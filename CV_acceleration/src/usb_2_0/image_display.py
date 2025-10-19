import time
import usb.core, usb.util, usb.backend.libusb1
import numpy as np
import cv2


# --- USB CONFIG ---

VID = 0x33AA
PID = 0x0000
EP_IN = 0x81
PKT_SIZE = 512
BULK_READ_SIZE = PKT_SIZE * 1024  # 512 KB per read
READ_COUNT = 5
TIMEOUT_MS = 20
MAX_TIMEOUTS = 200  # Stop after these many consecutive timeouts

# Frame‑related detection
FRAME_ONES_THRESHOLD = 511
CONSECUTIVE_TARGET_VALUE = 255  # 0xFF
MARKER_PACKETS = 13  # you confirmed this experimentally

# Image parameters
FRAME_W, FRAME_H = 640, 480
BYTES_PER_PIXEL = 2
FRAME_SIZE = FRAME_W * FRAME_H * BYTES_PER_PIXEL


def read_usb_data():
    """Continuously read from the USB device, return all data collected."""
    backend = usb.backend.libusb1.get_backend()
    dev = usb.core.find(idVendor=VID, idProduct=PID, backend=backend)
    if dev is None:
        raise ValueError("USB device not found")

    dev.set_configuration()
    cfg = dev.get_active_configuration()
    intf = cfg[(0, 0)]
    ep = usb.util.find_descriptor(intf, bEndpointAddress=EP_IN)
    if ep is None:
        raise ValueError(f"Endpoint 0x{EP_IN:02X} not found")

    print(f"Found device VID=0x{VID:04X}, PID=0x{PID:04X}, EP=0x{EP_IN:02X}")
    print(f"Bulk size: {BULK_READ_SIZE // 1024} KB | reads: {READ_COUNT}")

    all_data = []
    total_bytes = 0
    timeout_streak = 0
    start = time.time()

    for i in range(READ_COUNT):
        try:
            data = dev.read(ep.bEndpointAddress, BULK_READ_SIZE, timeout=TIMEOUT_MS)
            if len(data) > 0:
                all_data.append(data)
                total_bytes += len(data)
            timeout_streak = 0
        except usb.core.USBTimeoutError:
            timeout_streak += 1
            if timeout_streak >= MAX_TIMEOUTS:
                print(f"\nStopped: {timeout_streak} consecutive timeouts.")
                break
            continue
        except KeyboardInterrupt:
            print("\nInterrupted by user.")
            break

    elapsed = time.time() - start
    mb_per_s = total_bytes / (elapsed * 1024 * 1024) if elapsed > 0 else 0
    mbits_per_s = mb_per_s * 8

    print("\n===== USB READ COMPLETE =====")
    print(f"Total bytes read : {total_bytes:,}")
    print(f"Elapsed time     : {elapsed:.3f} s")
    print(f"Speed            : {mb_per_s:.2f} MB/s ({mbits_per_s:.2f} Mb/s)")
    print("=================================\n")

    if not all_data:
        return np.array([], dtype=np.uint8)

    # Convert each chunk (bytes) → uint8 array
    flat_data = np.concatenate(
        [np.frombuffer(chunk, dtype=np.uint8) for chunk in all_data if len(chunk) > 0]
    )

    if flat_data.size % PKT_SIZE != 0:
        print(f"⚠️ Warning: total bytes {flat_data.size} not multiple of 512")

    print(f"Total samples in array: {flat_data.size:,}")
    return flat_data


def find_consecutive_value(packet: np.ndarray, threshold: int) -> bool:
    """Return True if the packet has >= threshold consecutive occurrences of CONSECUTIVE_TARGET_VALUE."""
    if packet.size == 0:
        return False
    ones = (packet == CONSECUTIVE_TARGET_VALUE).astype(np.int8)
    diffs = np.diff(np.concatenate(([0], ones, [0])))
    run_starts = np.where(diffs == 1)[0]
    run_ends = np.where(diffs == -1)[0]
    if run_starts.size == 0:
        return False
    run_lengths = run_ends - run_starts
    return np.any(run_lengths >= threshold)


def detect_frame_boundaries(data: np.ndarray):
    """Find packet indices that contain 512 consecutive 0xFF (marker packets)."""
    packet_count = len(data) // PKT_SIZE
    matches = []
    for pkt_idx in range(packet_count):
        start = pkt_idx * PKT_SIZE
        end = start + PKT_SIZE
        pkt = data[start:end]
        if find_consecutive_value(pkt, FRAME_ONES_THRESHOLD):
            matches.append(pkt_idx)

    if not matches:
        print("No frame markers found.")
        return []

    print(f"Found {len(matches)} marker packets.")
    # Collapse consecutive marker indices into single frame boundaries
    matches = np.array(matches)
    # start new group whenever gap > 1
    groups = matches[np.hstack(([True], np.diff(matches) > 1))]
    print(f"Detected {len(groups)} unique frame boundaries")
    return groups


def split_frames(data: np.ndarray, frame_boundary_packets):
    """Split byte stream into frames using found boundaries."""
    if not len(frame_boundary_packets):
        return []

    boundaries_bytes = frame_boundary_packets * PKT_SIZE
    frames = []
    start = 0
    for end in boundaries_bytes:
        frame = data[start:end]
        if len(frame) >= FRAME_SIZE:  # only full frames
            frames.append(frame[:FRAME_SIZE].copy())
        start = end + MARKER_PACKETS * PKT_SIZE  # skip markers
        if start >= len(data):
            break

    print(f"Extracted {len(frames)} frame(s)")
    return frames


def decode_bgr565_from_fpga(frame_bytes, width=640, height=480):
    """Decode FPGA's BGR565-like stream (B‑G‑R order) into RGB888 image."""
    pix16 = np.frombuffer(frame_bytes, dtype="<u2")  # little-endian 16-bit
    if pix16.size != width * height:
        raise ValueError(f"Unexpected pixel count: {pix16.size}")

    # FPGA mapping: bits [15:11]=R5, [10:5]=G6, [4:0]=B5 --> outputs [15:11]=B5, [10:5]=G6, [4:0]=R5
    # so to get correct RGB, swap red and blue positions when extracting
    b = ((pix16 >> 11) & 0x1F) << 3  # upper 5 bits are actually blue
    g = ((pix16 >> 5) & 0x3F) << 2
    r = (pix16 & 0x1F) << 3

    rgb = np.stack((r, g, b), axis=-1).astype(np.uint8)
    return rgb.reshape((height, width, 3))


def display_frames(frames):
    """Display frames one by one using OpenCV."""
    for i, frame_bytes in enumerate(frames):
        print(f"Displaying frame {i}, {len(frame_bytes)} bytes")
        try:
            bgr = decode_bgr565_from_fpga(frame_bytes)
        except ValueError as e:
            print(f"Skipping frame {i}: {e}")
            continue

        cv2.imshow("OV5640 Frame", cv2.cvtColor(bgr, cv2.COLOR_RGB2BGR))
        key = cv2.waitKey(0)  # 200 ms per frame
        if key == 27:  # ESC to exit early
            break
    cv2.destroyAllWindows()


def main():
    try:
        data = read_usb_data()
        if data.size == 0:
            print("No data collected, aborting.")
            return

        # Find frame markers
        boundaries = detect_frame_boundaries(data)
        # Split frames
        frames = split_frames(data, boundaries)
        # Visualize
        if frames:
            display_frames(frames)
        else:
            print("No complete frames found for display.")

    except Exception as e:
        print(f"Error: {e}")


if __name__ == "__main__":
    main()
