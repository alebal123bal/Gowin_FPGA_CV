import usb.core, usb.util, usb.backend.libusb1
import numpy as np, cv2, threading, queue, time

# --- Config ---
VID, PID, EP_IN = 0x33AA, 0x0000, 0x81
W, H = 640, 480
BULK_READ_SIZE = 8 * 1024 * 1024  # 8 MB per transfer
FRAME_SIZE = W * H * 2
TIMEOUT_MS = 50


def decode_bgr565(frame_bytes):
    pix16 = np.frombuffer(frame_bytes, dtype="<u2")
    b = ((pix16 >> 11) & 0x1F) << 3
    g = ((pix16 >> 5) & 0x3F) << 2
    r = (pix16 & 0x1F) << 3
    return np.stack((r, g, b), -1).astype(np.uint8).reshape(H, W, 3)


def usb_reader(q, stop):
    dev = usb.core.find(
        idVendor=VID, idProduct=PID, backend=usb.backend.libusb1.get_backend()
    )
    if not dev:
        return print("No device")
    dev.set_configuration()
    ep = usb.util.find_descriptor(
        dev.get_active_configuration()[(0, 0)], bEndpointAddress=EP_IN
    )
    if not ep:
        return print("No EP")
    buf = bytearray()
    start = time.time()
    bytes_rx = 0
    while not stop.is_set():
        try:
            data = dev.read(ep.bEndpointAddress, BULK_READ_SIZE, timeout=TIMEOUT_MS)
            if len(data) == 0:
                continue
            buf += data
            bytes_rx += len(data)
            while len(buf) >= FRAME_SIZE:
                f = bytes(buf[:FRAME_SIZE])
                del buf[:FRAME_SIZE]
                q.put(decode_bgr565(f))
        except Exception:
            pass
        if time.time() - start > 1:
            print(f"{bytes_rx/1e6:.1f} MB/s")
            bytes_rx = 0
            start = time.time()
    print("USB stopped")


def main():
    q, stop = queue.Queue(4), threading.Event()
    t = threading.Thread(target=usb_reader, args=(q, stop), daemon=True)
    t.start()
    try:
        while True:
            try:
                f = q.get(timeout=2)
            except queue.Empty:
                if not t.is_alive():
                    break
                continue
            cv2.imshow("OV5640", cv2.cvtColor(f, cv2.COLOR_RGB2BGR))
            if cv2.waitKey(1) & 0xFF == 27:
                break
    finally:
        stop.set()
        t.join()
        cv2.destroyAllWindows()


if __name__ == "__main__":
    main()
