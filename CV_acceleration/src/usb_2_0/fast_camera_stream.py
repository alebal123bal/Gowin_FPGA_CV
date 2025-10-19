import usb.core, usb.util, usb.backend.libusb1
import time

VID = 0x33AA
PID = 0x0000
EP_IN = 0x81
PKT_SIZE = 512
BULK_READ_SIZE = PKT_SIZE * 1024  # 512 KB per read
READ_COUNT = 200
TIMEOUT_MS = 20
MAX_TIMEOUTS = 200  # Stop after these many consecutive timeouts


def main():
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

    total_bytes = 0
    timeout_streak = 0
    start = time.time()

    for i in range(READ_COUNT):
        try:
            data = dev.read(ep.bEndpointAddress, BULK_READ_SIZE, timeout=TIMEOUT_MS)
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

    print("\n===== READ COMPLETE =====")
    print(f"Total bytes read: {total_bytes:,}")
    print(f"Elapsed time: {elapsed:.3f} s")
    print(f"Speed: {mb_per_s:.2f} MB/s ({mbits_per_s:.2f} Mb/s)")
    print("===========================")


if __name__ == "__main__":
    main()
