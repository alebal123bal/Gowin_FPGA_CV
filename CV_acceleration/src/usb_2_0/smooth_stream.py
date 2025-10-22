import usb.core, usb.util, usb.backend.libusb1
import numpy as np, cv2, threading
import multiprocessing as mp
from multiprocessing import Process, Queue, Event

# --- Config ---
VID, PID, EP_IN = 0x33AA, 0x0000, 0x81
W, H = 640, 480
BULK_READ_SIZE = 32 * 1024 * 1024  # 32 MB per transfer
FRAME_SIZE = W * H * 2  # 2 bytes per pixel for RGB565
TIMEOUT_MS = 100
NUM_READERS = 8  # Multiple reader threads
MARKER_MIN_SIZE = 255  # Minimum consecutive 0xA0 bytes to detect frame marker


def decode_rgb565_fast(frame_bytes):
    """Optimized RGB565 decoder"""
    pix16 = np.frombuffer(frame_bytes, dtype=np.uint16).reshape(H, W)
    rgb = np.empty((H, W, 3), dtype=np.uint8)
    rgb[:, :, 0] = ((pix16 >> 11) & 0x1F) << 3  # R
    rgb[:, :, 1] = ((pix16 >> 5) & 0x3F) << 2  # G
    rgb[:, :, 2] = (pix16 & 0x1F) << 3  # B
    return rgb


def find_frame_marker_fast(buf_view, start, end, min_size=MARKER_MIN_SIZE):
    """Fast frame marker detection using NumPy"""
    if end - start < min_size:
        return -1

    data = np.frombuffer(buf_view[start:end], dtype=np.uint8)
    a0_mask = data == 0xA0
    a0_diff = np.diff(np.concatenate(([0], a0_mask.astype(np.int8), [0])))
    starts = np.where(a0_diff == 1)[0]
    ends = np.where(a0_diff == -1)[0]
    run_lengths = ends - starts
    valid_runs = np.where(run_lengths >= min_size)[0]

    if len(valid_runs) > 0:
        first_valid = valid_runs[0]
        return starts[first_valid] + run_lengths[first_valid]

    return -1


def usb_reader(raw_queue, stop, reader_id):
    """USB reader thread - reads raw data and puts into queue"""
    dev = usb.core.find(
        idVendor=VID, idProduct=PID, backend=usb.backend.libusb1.get_backend()
    )
    if not dev:
        return

    dev.set_configuration()

    try:
        dev.set_auto_detach_kernel_driver(True)
    except:
        pass

    ep = usb.util.find_descriptor(
        dev.get_active_configuration()[(0, 0)], bEndpointAddress=EP_IN
    )
    if not ep:
        return

    while not stop.is_set():
        try:
            data = dev.read(ep.bEndpointAddress, BULK_READ_SIZE, timeout=TIMEOUT_MS)
            if len(data) > 0 and not raw_queue.full():
                raw_queue.put(bytes(data))
        except usb.core.USBError as e:
            if e.errno != 110:  # Ignore timeout errors
                pass
        except:
            pass


def marker_detector_process(raw_queue, frame_queue, stop):
    """Marker detection and frame extraction with validation"""
    buf = bytearray(BULK_READ_SIZE * 8)
    buf_view = memoryview(buf)
    buf_len = 0

    frame_start = 0
    synced = False
    last_search_pos = 0

    # Frame validation thresholds
    MIN_VALID_FRAME = int(FRAME_SIZE * 0.98)
    MAX_VALID_FRAME = int(FRAME_SIZE * 1.02)

    # Auto re-sync parameters
    consecutive_bad_frames = 0
    MAX_BAD_FRAMES = 5

    while not stop.is_set():
        try:
            try:
                data = raw_queue.get(timeout=0.1)
            except:
                continue

            data_len = len(data)
            buf[buf_len : buf_len + data_len] = data
            buf_len += data_len

            search_start = max(last_search_pos - MARKER_MIN_SIZE, frame_start)

            while search_start < buf_len - MARKER_MIN_SIZE:
                marker_pos = find_frame_marker_fast(buf_view, search_start, buf_len)

                if marker_pos == -1:
                    last_search_pos = buf_len
                    break

                marker_abs_pos = search_start + marker_pos

                if not synced:
                    frame_start = marker_abs_pos
                    synced = True
                    last_search_pos = marker_abs_pos
                    consecutive_bad_frames = 0
                    search_start = marker_abs_pos
                else:
                    frame_len = marker_abs_pos - frame_start

                    # Frame validation
                    if MIN_VALID_FRAME <= frame_len <= MAX_VALID_FRAME:
                        consecutive_bad_frames = 0

                        if not frame_queue.full():
                            actual_frame_len = min(frame_len, FRAME_SIZE)
                            frame_data = bytes(
                                buf_view[frame_start : frame_start + actual_frame_len]
                            )

                            # Pad if short
                            if len(frame_data) < FRAME_SIZE:
                                frame_data += b"\x00" * (FRAME_SIZE - len(frame_data))
                            # Trim if long
                            elif len(frame_data) > FRAME_SIZE:
                                frame_data = frame_data[:FRAME_SIZE]

                            frame_queue.put(frame_data)
                    else:
                        # Invalid frame - discard
                        consecutive_bad_frames += 1

                        # Auto re-sync if too many bad frames
                        if consecutive_bad_frames >= MAX_BAD_FRAMES:
                            synced = False
                            consecutive_bad_frames = 0

                    frame_start = marker_abs_pos
                    last_search_pos = marker_abs_pos
                    search_start = marker_abs_pos

            # Cleanup buffer
            if frame_start > BULK_READ_SIZE * 2:
                remaining = buf_len - frame_start
                buf[:remaining] = buf[frame_start:buf_len]
                buf_len = remaining
                last_search_pos -= frame_start
                frame_start = 0

        except:
            pass


def display_process(frame_queue, stop):
    """RGB565 decoding and OpenCV display"""
    cv2.namedWindow("OV5640", cv2.WINDOW_NORMAL)

    try:
        while not stop.is_set():
            try:
                frame_data = frame_queue.get(timeout=0.5)
                frame_rgb = decode_rgb565_fast(frame_data)
                cv2.imshow("OV5640", frame_rgb[:, :, ::-1])

                if cv2.waitKey(1) & 0xFF == 27:
                    stop.set()
                    break
            except:
                if stop.is_set():
                    break
                continue
    finally:
        cv2.destroyAllWindows()


def main():
    raw_queue = Queue(maxsize=32)
    frame_queue = Queue(maxsize=16)
    stop = Event()

    # Start processes
    detector_proc = Process(
        target=marker_detector_process, args=(raw_queue, frame_queue, stop)
    )
    detector_proc.start()

    display_proc = Process(target=display_process, args=(frame_queue, stop))
    display_proc.start()

    # Start USB reader threads
    threads = []
    for i in range(NUM_READERS):
        t = threading.Thread(target=usb_reader, args=(raw_queue, stop, i), daemon=True)
        t.start()
        threads.append(t)

    try:
        display_proc.join()
    except KeyboardInterrupt:
        pass
    finally:
        stop.set()

        for t in threads:
            t.join(timeout=1)

        detector_proc.join(timeout=2)
        display_proc.join(timeout=2)

        if detector_proc.is_alive():
            detector_proc.terminate()
        if display_proc.is_alive():
            display_proc.terminate()


if __name__ == "__main__":
    mp.set_start_method("spawn", force=True)
    main()
