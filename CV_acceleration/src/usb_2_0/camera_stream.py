# pylint: disable=all

import usb.core, usb.util
import usb.backend.libusb1
import numpy as np
import threading
import queue
import time

# Configuration
VID = 0x33AA
PID = 0x0000
EP_IN = 0x81  # endpoint address
PKT_SIZE = 512  # wMaxPacketSize
TIMEOUT = 10  # Reduced timeout for high-speed operation
TOTAL_PACKETS = 5000  # Total packets to read in this demo
FRAME_BOUNDARY_ONES = 500  # Consecutive ones to detect frame boundary


class HighSpeedUSBReader:
    def __init__(self):
        self.running = False
        self.packet_queue = queue.Queue(
            maxsize=TOTAL_PACKETS * 2
        )  # Buffer for high-speed operation
        self.stats_lock = threading.Lock()
        self.total_packets_read = 0
        self.total_bytes_read = 0
        self.read_speed_mbps = 0.0

        # USB setup
        self.setup_usb()

    def setup_usb(self):
        """Initialize USB device with optimized settings"""
        backend = usb.backend.libusb1.get_backend()
        print("Backend:", backend)

        print(f"Searching for USB device (VID: 0x{VID:04X}, PID: 0x{PID:04X})...")
        self.dev = usb.core.find(idVendor=VID, idProduct=PID)

        if self.dev is None:
            print("Device not found! Listing all USB devices:")
            devices = usb.core.find(find_all=True)
            for device in devices:
                try:
                    print(
                        f"  Found device: VID=0x{device.idVendor:04X}, PID=0x{device.idProduct:04X}"
                    )
                except:
                    print("  Found device: (unable to read VID/PID)")
            raise ValueError("Target device not found")

        print(
            f"Found target device: VID=0x{self.dev.idVendor:04X}, PID=0x{self.dev.idProduct:04X}"
        )

        try:
            # Set configuration for high-speed operation
            print("Setting USB configuration...")
            self.dev.set_configuration()

            print("Getting active configuration...")
            cfg = self.dev.get_active_configuration()
            intf = cfg[(0, 0)]

            print(f"Finding endpoint {EP_IN:02X}...")
            self.ep = usb.util.find_descriptor(intf, bEndpointAddress=EP_IN)

            if self.ep is None:
                print("Available endpoints:")
                for ep in intf:
                    print(f"  Endpoint: 0x{ep.bEndpointAddress:02X}")
                raise ValueError(f"Endpoint {EP_IN:02X} not found")

            print(f"Found endpoint: 0x{self.ep.bEndpointAddress:02X}")

            # Reset any stale data
            print("Clearing USB buffer...")
            cleared_packets = 0
            try:
                while True:
                    self.dev.read(self.ep.bEndpointAddress, PKT_SIZE, timeout=10)
                    cleared_packets += 1
                    if cleared_packets > 100:  # Prevent infinite loop
                        break
            except usb.core.USBTimeoutError:
                pass  # Expected when buffer is empty

            if cleared_packets > 0:
                print(f"Cleared {cleared_packets} stale packets from buffer")

            print("USB device initialized for high-speed operation")

        except usb.core.USBError as e:
            print(f"USB setup error: {e}")
            raise
        except Exception as e:
            print(f"Unexpected error during USB setup: {e}")
            raise

    def has_consecutive_ones(self, data_array, min_count=FRAME_BOUNDARY_ONES):
        """Fast consecutive one detection"""
        consecutive = 0
        for byte_val in data_array:
            if byte_val == 1:
                consecutive += 1
                if consecutive >= min_count:
                    return True
            else:
                consecutive = 0
        return False

    def usb_reader_thread(self):
        """Dedicated high-speed USB reading thread - stops after TOTAL_PACKETS packets"""
        packet_count = 0
        start_time = time.time()

        print(
            f"High-speed USB reader thread started - will stop after {TOTAL_PACKETS} packets"
        )

        while self.running and packet_count < TOTAL_PACKETS:
            try:
                # Read packet at maximum speed
                data = self.dev.read(
                    self.ep.bEndpointAddress, PKT_SIZE, timeout=TIMEOUT
                )

                # Queue packet for processing (non-blocking)
                if not self.packet_queue.full():
                    self.packet_queue.put((packet_count, data), block=False)

                packet_count += 1

                # Update statistics every 500 packets
                if packet_count % 500 == 0:
                    print(
                        f"Reading progress: {packet_count}/{TOTAL_PACKETS} packets..."
                    )

            except usb.core.USBTimeoutError:
                # Normal timeout, continue reading
                continue
            except usb.core.USBError as e:
                print(f"USB Error: {e}")
                break
            except Exception as e:
                print(f"Reader thread error: {e}")
                break

        # Store final stats
        with self.stats_lock:
            elapsed = time.time() - start_time
            self.total_packets_read = packet_count
            self.total_bytes_read = packet_count * PKT_SIZE
            self.read_speed_mbps = (self.total_bytes_read * 8) / (elapsed * 1_000_000)

        print(
            f"USB reader thread stopped after {packet_count} packets in {elapsed:.2f}s"
        )
        self.running = False

    def start(self):
        """Start the high-speed USB reader"""
        self.running = True
        self.reader_thread = threading.Thread(
            target=self.usb_reader_thread, daemon=True
        )
        self.reader_thread.start()
        time.sleep(0.5)  # Let reader start

    def stop(self):
        """Stop the USB reader"""
        self.running = False
        if hasattr(self, "reader_thread"):
            self.reader_thread.join(timeout=2.0)

    def get_stats(self):
        """Get current reading statistics"""
        with self.stats_lock:
            return {
                "packets": self.total_packets_read,
                "bytes": self.total_bytes_read,
                "speed_mbps": self.read_speed_mbps,
                "queue_size": self.packet_queue.qsize(),
            }


def analyze_queue(reader):
    """Analyze the packet queue contents"""
    print("\n" + "=" * 50)
    print("ANALYZING PACKET QUEUE")
    print("=" * 50)

    queue_size = reader.packet_queue.qsize()
    print(f"Packets in queue: {queue_size}")

    if queue_size == 0:
        print("No packets to analyze!")
        return

    # Extract all packets from queue
    packets = []
    while not reader.packet_queue.empty():
        try:
            packet = reader.packet_queue.get_nowait()
            packets.append(packet)
        except queue.Empty:
            break

    print(f"Extracted {len(packets)} packets for analysis")

    # Show first 3 packets
    print(f"\nFirst 3 packets:")
    for i, (pkt_num, data) in enumerate(packets[:3]):
        preview = list(data[:10])  # First 10 bytes
        print(f"  Packet {pkt_num}: {preview}...")

    # Look for frame boundaries
    boundaries = 0
    for pkt_num, data in packets:
        if reader.has_consecutive_ones(data):
            boundaries += 1
            print(f"  Frame boundary found in packet {pkt_num}")

    print(f"\nFrame boundaries found: {boundaries}")

    # Basic stats
    total_bytes = len(packets) * PKT_SIZE
    print(f"Total bytes: {total_bytes:,}")
    print(f"Total packets analyzed: {len(packets)}")

    stats = reader.get_stats()
    print(f"Reading speed: {stats['speed_mbps']:.1f} Mbps")
    print("=" * 50)


def main():
    """Stream TOTAL_PACKETS packets then analyze"""
    reader = HighSpeedUSBReader()

    try:
        # Start streaming
        reader.start()
        print(f"Streaming {TOTAL_PACKETS} packets...")

        # Wait for reader to finish
        while reader.running:
            time.sleep(0.1)

        # Analyze the queue
        analyze_queue(reader)

        print("\nAnalysis complete!")

    except KeyboardInterrupt:
        print("\nStopping...")
        reader.stop()

    print("Done!")


if __name__ == "__main__":
    main()
