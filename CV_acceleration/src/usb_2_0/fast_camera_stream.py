import time
import usb.core, usb.util, usb.backend.libusb1
import numpy as np

VID = 0x33AA
PID = 0x0000
EP_IN = 0x81
PKT_SIZE = 512
BULK_READ_SIZE = PKT_SIZE * 1024  # 512 KB per read
READ_COUNT = 5
TIMEOUT_MS = 20
MAX_TIMEOUTS = 200  # Stop after these many consecutive timeouts
FRAME_ONES_THRESHOLD = 511  # configurable threshold (consecutive occurrences)
CONSECUTIVE_TARGET_VALUE = 255  # int8 arbitrary number to search for (0-255)


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

    all_data = []  # List to accumulate chunks
    total_bytes = 0
    timeout_streak = 0
    start = time.time()

    for i in range(READ_COUNT):
        try:
            data = dev.read(ep.bEndpointAddress, BULK_READ_SIZE, timeout=TIMEOUT_MS)
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
    mb_per_s = total_bytes / (elapsed * 1024 * 1024)
    mbits_per_s = mb_per_s * 8

    print("\n===== USB READ COMPLETE =====")
    print(f"Total bytes read : {total_bytes:,}")
    print(f"Elapsed time     : {elapsed:.3f} s")
    print(f"Speed            : {mb_per_s:.2f} MB/s ({mbits_per_s:.2f} Mb/s)")
    print("=================================\n")

    if not all_data:
        return np.array([], dtype=np.uint8)

    return np.concatenate([np.frombuffer(chunk, dtype=np.uint8) for chunk in all_data])


def find_consecutive_value(packet: np.ndarray, threshold: int) -> bool:
    """Return True if the packet has >= threshold consecutive occurrences of CONSECUTIVE_TARGET_VALUE."""
    if packet.size == 0:
        return False
    # Efficient vectorized search for consecutive target values
    # Convert to boolean mask
    ones = (packet == CONSECUTIVE_TARGET_VALUE).astype(np.int8)
    # Find run lengths of consecutive target values
    diffs = np.diff(np.concatenate(([0], ones, [0])))
    run_starts = np.where(diffs == 1)[0]
    run_ends = np.where(diffs == -1)[0]
    if run_starts.size == 0:
        return False
    run_lengths = run_ends - run_starts
    return np.any(run_lengths >= threshold)


def post_process(data: np.ndarray):
    """Do post‑processing and find packets with long consecutive 1s."""
    print("Starting post‑processing ...")

    # ---- Basic statistics ----
    print(f"Total samples: {len(data):,}")
    print(f"Mean: {data.mean():.2f}, Std: {data.std():.2f}")
    print(f"Min: {data.min()}   Max: {data.max()}")

    # ---- Count zeros/ones just for global info ----
    ones = np.count_nonzero(data == 1)
    zeros = np.count_nonzero(data == 0)
    print(f"Zeros: {zeros:,}, Ones: {ones:,}")

    # ---- Frame boundary search ----
    print(
        f"\nSearching packets with >= {FRAME_ONES_THRESHOLD} consecutive '{CONSECUTIVE_TARGET_VALUE}'s ..."
    )

    # Split the entire stream into 512‑byte logical packets
    packet_count = len(data) // PKT_SIZE
    matches = []

    for pkt_idx in range(packet_count):
        start = pkt_idx * PKT_SIZE
        end = start + PKT_SIZE
        pkt = data[start:end]
        if find_consecutive_value(pkt, FRAME_ONES_THRESHOLD):
            matches.append(pkt_idx)

    if matches:
        print(f"\nFound {len(matches)} packets matching threshold:")
        print(matches[:150])  # Show first 150 packet indices only
        if len(matches) > 150:
            print(f"... and {len(matches) - 150} more not shown")
    else:
        print("No packets found with that pattern.")

    # ---- Save binary dump for offline analysis ----
    out_file = "CV_acceleration/src/usb_2_0/usb_stream_dump/usb_stream_dump.bin"
    with open(out_file, "wb") as f:
        data.tofile(f)
    print(f"\nSaved raw stream to '{out_file}' ({len(data)/1024/1024:.1f} MB)")

    print("\nPost-processing complete.")


def main():
    try:
        data_array = read_usb_data()
        if data_array.size > 0:
            post_process(data_array)
        else:
            print("No data collected, skipping post‑processing.")
    except Exception as e:
        print(f"Error: {e}")


if __name__ == "__main__":
    main()
