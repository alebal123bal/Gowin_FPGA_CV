import usb.core, usb.util, usb.backend.libusb1
import numpy as np, cv2, threading, queue, time
import multiprocessing as mp
from multiprocessing import Process, Queue, Event, Value
import ctypes

# --- Config ---
VID, PID, EP_IN = 0x33AA, 0x0000, 0x81
W, H = 640, 480
BULK_READ_SIZE = 32 * 1024 * 1024  # 32 MB per transfer (larger chunks)
FRAME_SIZE = W * H * 2  # 2 bytes per pixel for RGB565
TIMEOUT_MS = 100
NUM_READERS = 8  # Multiple reader threads
MARKER_MIN_SIZE = 255  # Minimum consecutive 0xA0 bytes to detect frame marker


def decode_rgb565_fast(frame_bytes):
    """Optimized RGB565 decoder (standard format - NO channel swap needed)"""
    pix16 = np.frombuffer(frame_bytes, dtype=np.uint16).reshape(H, W)

    # Pre-allocate output array
    rgb = np.empty((H, W, 3), dtype=np.uint8)

    # Extract channels - standard RGB565 layout
    rgb[:, :, 0] = ((pix16 >> 11) & 0x1F) << 3  # R (bits 15-11)
    rgb[:, :, 1] = ((pix16 >> 5) & 0x3F) << 2  # G (bits 10-5)
    rgb[:, :, 2] = (pix16 & 0x1F) << 3  # B (bits 4-0)

    return rgb


def find_frame_marker_fast(buf_view, start, end, min_size=MARKER_MIN_SIZE):
    """Fast frame marker detection using NumPy"""
    if end - start < min_size:
        return -1

    # Convert memoryview to numpy array (zero-copy)
    data = np.frombuffer(buf_view[start:end], dtype=np.uint8)

    # Find all 0xA0 positions
    a0_mask = data == 0xA0

    # Find transitions (where 0xA0 sequences start/end)
    a0_diff = np.diff(np.concatenate(([0], a0_mask.astype(np.int8), [0])))
    starts = np.where(a0_diff == 1)[0]
    ends = np.where(a0_diff == -1)[0]

    # Find runs of 0xA0 >= min_size
    run_lengths = ends - starts
    valid_runs = np.where(run_lengths >= min_size)[0]

    if len(valid_runs) > 0:
        # Return position after the FIRST valid marker
        first_valid = valid_runs[0]
        return starts[first_valid] + run_lengths[first_valid]  # End of marker

    return -1


def usb_reader(raw_queue, stop, reader_id):
    """USB reader thread - reads raw data and puts into queue"""
    dev = usb.core.find(
        idVendor=VID, idProduct=PID, backend=usb.backend.libusb1.get_backend()
    )
    if not dev:
        return print(f"Reader {reader_id}: No device")

    dev.set_configuration()

    try:
        dev.set_auto_detach_kernel_driver(True)
    except:
        pass

    ep = usb.util.find_descriptor(
        dev.get_active_configuration()[(0, 0)], bEndpointAddress=EP_IN
    )
    if not ep:
        return print(f"Reader {reader_id}: No EP")

    start = time.time()
    bytes_rx = 0

    while not stop.is_set():
        try:
            data = dev.read(ep.bEndpointAddress, BULK_READ_SIZE, timeout=TIMEOUT_MS)
            data_len = len(data)

            if data_len == 0:
                continue

            bytes_rx += data_len

            # Put raw data into queue for marker detection process
            if not raw_queue.full():
                raw_queue.put(bytes(data))

        except usb.core.USBError as e:
            if e.errno != 110:  # Ignore timeout errors
                pass
        except Exception:
            pass

        # Stats reporting
        elapsed = time.time() - start
        if elapsed > 1.0:
            print(f"Reader {reader_id}: {bytes_rx/1e6:.1f} MB/s")
            bytes_rx = 0
            start = time.time()

    print(f"Reader {reader_id} stopped")


def marker_detector_process(raw_queue, frame_queue, stop):
    """Separate process for marker detection and frame extraction"""
    print("Marker detector process started")

    buf = bytearray(BULK_READ_SIZE * 8)  # Large buffer
    buf_view = memoryview(buf)
    buf_len = 0

    # Frame sync state
    frame_start = 0
    synced = False
    last_search_pos = 0

    start = time.time()
    frame_count = 0
    dropped_frames = 0
    bytes_processed = 0

    while not stop.is_set():
        try:
            # Get raw data from USB readers
            try:
                data = raw_queue.get(timeout=0.1)
            except:
                continue

            data_len = len(data)
            bytes_processed += data_len

            # Fast buffer append
            buf[buf_len : buf_len + data_len] = data
            buf_len += data_len

            # Look for frame markers and extract frames
            search_start = max(last_search_pos - MARKER_MIN_SIZE, frame_start)

            while search_start < buf_len - MARKER_MIN_SIZE:
                # Fast marker search
                marker_pos = find_frame_marker_fast(buf_view, search_start, buf_len)

                if marker_pos == -1:
                    # No marker found, remember where we searched
                    last_search_pos = buf_len
                    break

                # Absolute position of marker end
                marker_abs_pos = search_start + marker_pos

                if not synced:
                    # First sync - start from after this marker
                    frame_start = marker_abs_pos
                    synced = True
                    last_search_pos = marker_abs_pos
                    print(f"Marker detector: Synced at byte {marker_abs_pos}")
                    search_start = marker_abs_pos
                else:
                    # We have a complete frame
                    frame_len = marker_abs_pos - frame_start

                    # Extract frame (before the marker)
                    if FRAME_SIZE // 2 <= frame_len <= FRAME_SIZE * 2:  # Sanity check
                        if not frame_queue.full():
                            # Trim to exact frame size
                            actual_frame_len = min(frame_len, FRAME_SIZE)
                            frame_data = bytes(
                                buf_view[frame_start : frame_start + actual_frame_len]
                            )

                            # Pad if needed
                            if len(frame_data) < FRAME_SIZE:
                                frame_data += b"\x00" * (FRAME_SIZE - len(frame_data))

                            # Send frame bytes to display process
                            frame_queue.put(frame_data)
                            frame_count += 1
                        else:
                            dropped_frames += 1

                    # Move to next frame
                    frame_start = marker_abs_pos
                    last_search_pos = marker_abs_pos
                    search_start = marker_abs_pos

            # Cleanup buffer periodically
            if frame_start > BULK_READ_SIZE * 2:
                remaining = buf_len - frame_start
                buf[:remaining] = buf[frame_start:buf_len]
                buf_len = remaining
                last_search_pos -= frame_start
                frame_start = 0

        except Exception as e:
            print(f"Marker detector error: {e}")

        # Stats reporting
        elapsed = time.time() - start
        if elapsed > 1.0:
            print(
                f"Marker detector: {bytes_processed/1e6:.1f} MB/s, {frame_count} fps, dropped={dropped_frames}, buf={buf_len}"
            )
            bytes_processed = 0
            frame_count = 0
            dropped_frames = 0
            start = time.time()

    print("Marker detector process stopped")


def display_process(frame_queue, stop):
    """Separate process for RGB565 decoding and OpenCV display"""
    print("Display process started")

    cv2.namedWindow("OV5640", cv2.WINDOW_NORMAL)

    start = time.time()
    display_count = 0

    try:
        while not stop.is_set():
            try:
                # Get frame data from marker detector
                frame_data = frame_queue.get(timeout=0.5)

                # Option 1: Standard RGB565
                frame_rgb = decode_rgb565_fast(frame_data)

                # Convert RGB to BGR for OpenCV display
                cv2.imshow("OV5640", frame_rgb[:, :, ::-1])
                display_count += 1

                if cv2.waitKey(1) & 0xFF == 27:
                    stop.set()
                    break

            except:
                # Timeout - check if we should exit
                if stop.is_set():
                    break
                continue

            # Stats reporting
            elapsed = time.time() - start
            if elapsed > 1.0:
                print(f"Display: {display_count} fps")
                display_count = 0
                start = time.time()

    finally:
        cv2.destroyAllWindows()
        print("Display process stopped")


def main():
    # Use multiprocessing queues
    raw_queue = Queue(maxsize=32)  # Raw USB data
    frame_queue = Queue(maxsize=16)  # Extracted frames
    stop = Event()

    # Start marker detector process
    detector_proc = Process(
        target=marker_detector_process, args=(raw_queue, frame_queue, stop)
    )
    detector_proc.start()

    # Start display process
    display_proc = Process(target=display_process, args=(frame_queue, stop))
    display_proc.start()

    # Start USB reader threads
    threads = []
    for i in range(NUM_READERS):
        t = threading.Thread(target=usb_reader, args=(raw_queue, stop, i), daemon=True)
        t.start()
        threads.append(t)

    try:
        # Wait for display process (which handles ESC key)
        display_proc.join()
    except KeyboardInterrupt:
        print("Interrupted by user")
    finally:
        stop.set()

        # Clean up
        for t in threads:
            t.join(timeout=1)

        detector_proc.join(timeout=2)
        display_proc.join(timeout=2)

        # Force terminate if needed
        if detector_proc.is_alive():
            detector_proc.terminate()
        if display_proc.is_alive():
            display_proc.terminate()

        print("All processes stopped")


if __name__ == "__main__":
    # Required for multiprocessing on Windows/macOS
    mp.set_start_method("spawn", force=True)
    main()
