import usb.core, usb.util
import usb.backend.libusb1

VID = 0x33AA
PID = 0x0000
EP_IN = 0x81  # endpoint address
PKT = 512  # wMaxPacketSize


backend = usb.backend.libusb1.get_backend()
print("Backend:", backend)

dev = usb.core.find(idVendor=VID, idProduct=PID)
if dev is None:
    raise ValueError("Device not found")

dev.set_configuration()
cfg = dev.get_active_configuration()
intf = cfg[(0, 0)]
ep = usb.util.find_descriptor(intf, bEndpointAddress=EP_IN)

i = 0
while True:
    data = dev.read(ep.bEndpointAddress, PKT, timeout=2000)
    print(data)
    print()
    i += 1
    # if i >= 10:
    #     print("Read 10 packets, exiting.")
    #     break
