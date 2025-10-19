import usb.core, usb.util, usb.backend.libusb1
import time
import numpy as np

VID = 0x33AA
PID = 0x0000
EP_IN = 0x81
PKT_SIZE = 512
BULK_READ_SIZE = PKT_SIZE * 1024  # 512 KB per read
READ_COUNT = 2000
TIMEOUT_MS = 20
MAX_TIMEOUTS = 200  # Stop after these many consecutive timeouts


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
    print(f"Total bytes read: {total_bytes:,}")
    print(f"Elapsed time: {elapsed:.3f} s")
    print(f"Speed: {mb_per_s:.2f} MB/s ({mbits_per_s:.2f} Mb/s)")
    print("==============================\n")

    return np.concatenate([np.frombuffer(chunk, dtype=np.uint8) for chunk in all_data])


def post_process(data: np.ndarray):
    """Example post‑processing of collected USB data buffer."""
    print("Starting post‑processing ...")

    # Example: simple statistics
    print(f"Total samples: {len(data):,}")
    print(f"Mean value: {data.mean():.2f}")
    print(f"Std deviation: {data.std():.2f}")
    print(f"Min: {data.min()}   Max: {data.max()}")

    # Example: detect frame boundary based on value pattern
    ones = np.count_nonzero(data == 1)
    zeros = np.count_nonzero(data == 0)
    print(f"Zeros: {zeros:,}, Ones: {ones:,}")

    # Replace dump file
    out_file = "CV_acceleration/src/usb_2_0/usb_stream_dump/usb_stream_dump.bin"
    with open(out_file, "wb") as f:
        data.tofile(f)
    print(f"Saved raw stream to '{out_file}' ({len(data)/1024/1024:.1f} MB)")

    print("Post‑processing complete.")


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
