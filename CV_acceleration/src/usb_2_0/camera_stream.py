import usb.core, usb.util
import usb.backend.libusb1
import numpy as np

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
frame_boundary_detected = False
packets_to_collect = 0
collected_packets = []  # Pre-allocate list to store packets


def has_consecutive_zeros(data_array, min_count=30):
    """Check if data_array has min_count consecutive zeros using numpy"""
    # Convert array to numpy array if it isn't already
    arr = np.array(data_array)

    # Simple approach: count consecutive zeros
    consecutive_count = 0
    max_consecutive = 0

    for value in arr:
        if value == 0:
            consecutive_count += 1
            max_consecutive = max(max_consecutive, consecutive_count)
            if max_consecutive >= min_count:
                return True
        else:
            consecutive_count = 0

    return max_consecutive >= min_count


print("Searching for frame boundary (30+ consecutive zeros)...")

while True:
    data = dev.read(ep.bEndpointAddress, PKT, timeout=2000)

    # Show progress every 100 packets (only while searching)
    if not frame_boundary_detected and i % 100 == 0:
        print(f"Processed {i} packets, still searching for frame boundary...")

    # Check for frame boundary (30+ consecutive zeros)
    if has_consecutive_zeros(data, 30):
        print(f"Frame boundary detected at packet {i}! Collecting next 100 packets...")
        frame_boundary_detected = True
        packets_to_collect = 10
        collected_packets = []  # Reset the collection

    # Collect packets if we're in collection mode
    if packets_to_collect > 0:
        collected_packets.append((i, data))
        packets_to_collect -= 1

        # Show collection progress every 20 packets
        if packets_to_collect % 20 == 0:
            print(f"Collected {100 - packets_to_collect}/100 packets...")

        if packets_to_collect == 0:
            print("Finished collecting 100 packets. Printing all at once:")
            print("=" * 60)
            for packet_num, packet_data in collected_packets:
                print(f"Packet {packet_num}: {packet_data}")
                print()
            print("=" * 60)
            print("All packets printed. Exiting.")
            break

    i += 1

    # Safety exit after reading many packets without finding boundary
    if i >= 1000 and not frame_boundary_detected:
        print("Read 1000 packets without finding frame boundary, exiting.")
        break
