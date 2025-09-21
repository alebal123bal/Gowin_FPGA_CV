// USB2.0 device descriptor module
// Configures the FPGA to stream data from OV5640 camera over USB using a specific bulk endpoint.
// 3 Endpoints are still needed: EP0 for control and EP1 IN for data streaming, EP1 OUT for ack.
// USB bulk must alternate DATA0/DATA1 toggles; 
// without an OUT endpoint the host has no way to send the ACK handshake that contains the toggle bit, 
// so every IN transaction is retried forever and no data reaches the PC.

module usb_descriptor #(
    // Vendor ID to report in device descriptor.
    parameter VENDORID = 16'h33AA,
    // Product ID to report in device descriptor.
    parameter PRODUCTID = 16'h0000,
    // Product version to report in device descriptor.
    parameter VERSIONBCD = 16'h0100,
    // Optional description of manufacturer (max 126 characters).
    parameter VENDORSTR = "OV5640 Camera",
    parameter VENDORSTR_LEN = 13,
    // Optional description of product (max 126 characters).
    parameter PRODUCTSTR = "Video Streamer",
    parameter PRODUCTSTR_LEN = 14,
    // Optional product serial number (max 126 characters).
    parameter SERIALSTR = "12345678",
    parameter SERIALSTR_LEN = 8,
    // Support high speed mode.
    parameter HSSUPPORT = 1,
    // Set to true if the device never draws power from the USB bus.
    parameter SELFPOWERED = 1,
    // BOS support
    parameter BOSUPPORT = 1,
    parameter BOS_LEN = 15
) (
    input CLK,
    input RESET,
    input [15:0] i_pid,
    input [15:0] i_vid,
    input [15:0] i_descrom_raddr,
    output [7:0] o_descrom_rdat,
    output [15:0] o_desc_dev_addr,
    output [15:0] o_desc_dev_len,
    output [15:0] o_desc_qual_addr,
    output [15:0] o_desc_qual_len,
    output [15:0] o_desc_fscfg_addr,
    output [15:0] o_desc_fscfg_len,
    output [15:0] o_desc_hscfg_addr,
    output [15:0] o_desc_hscfg_len,
    output [15:0] o_desc_oscfg_addr,
    output [15:0] o_desc_strlang_addr,
    output [15:0] o_desc_strvendor_addr,
    output [15:0] o_desc_strvendor_len,
    output [15:0] o_desc_strproduct_addr,
    output [15:0] o_desc_strproduct_len,
    output [15:0] o_desc_strserial_addr,
    output [15:0] o_desc_strserial_len,
    output o_descrom_have_strings,
    output [15:0] o_desc_bos_addr,
    output [15:0] o_desc_bos_len
);

  // Descriptor ROM
  localparam DESC_DEV_ADDR = 0;
  localparam DESC_DEV_LEN = 18;
  localparam DESC_QUAL_ADDR = 20;
  localparam DESC_QUAL_LEN = 10;
  localparam DESC_FSCFG_ADDR = 32;
  localparam DESC_FSCFG_LEN = 32;  // 9+9+7+7 = 32 bytes for single bulk endpoint
  localparam DESC_HSCFG_ADDR = DESC_FSCFG_ADDR + DESC_FSCFG_LEN;
  localparam DESC_HSCFG_LEN = 32;  // 9+9+7+7 = 32 bytes for single bulk endpoint
  localparam DESC_OSCFG_ADDR = DESC_HSCFG_ADDR + DESC_HSCFG_LEN;
  localparam DESC_OSCFG_LEN = 32;  // 9+9+7+7 = 32 bytes for single bulk endpoint
  localparam DESC_BOS_ADDR = DESC_OSCFG_ADDR + DESC_OSCFG_LEN;
  localparam DESC_BOS_LEN = BOS_LEN;
  localparam DESC_STRLANG_ADDR = DESC_BOS_ADDR + DESC_BOS_LEN;
  localparam DESC_STRVENDOR_ADDR = DESC_STRLANG_ADDR + 4;
  localparam DESC_STRVENDOR_LEN = 2 + 2 * VENDORSTR_LEN;
  localparam DESC_STRPRODUCT_ADDR = DESC_STRVENDOR_ADDR + DESC_STRVENDOR_LEN;
  localparam DESC_STRPRODUCT_LEN = 2 + 2 * PRODUCTSTR_LEN;
  localparam DESC_STRSERIAL_ADDR = DESC_STRPRODUCT_ADDR + DESC_STRPRODUCT_LEN;
  localparam DESC_STRSERIAL_LEN = 2 + 2 * SERIALSTR_LEN;
  localparam DESC_END_ADDR = DESC_STRSERIAL_ADDR + DESC_STRSERIAL_LEN;

  assign o_desc_dev_addr = DESC_DEV_ADDR;
  assign o_desc_dev_len = DESC_DEV_LEN;
  assign o_desc_qual_addr = DESC_QUAL_ADDR;
  assign o_desc_qual_len = DESC_QUAL_LEN;
  assign o_desc_fscfg_addr = DESC_FSCFG_ADDR;
  assign o_desc_fscfg_len = DESC_FSCFG_LEN;
  assign o_desc_hscfg_addr = DESC_HSCFG_ADDR;
  assign o_desc_hscfg_len = DESC_HSCFG_LEN;
  assign o_desc_oscfg_addr = DESC_OSCFG_ADDR;
  assign o_desc_strlang_addr = DESC_STRLANG_ADDR;
  assign o_desc_strvendor_addr = DESC_STRVENDOR_ADDR;
  assign o_desc_strvendor_len = DESC_STRVENDOR_LEN;
  assign o_desc_strproduct_addr = DESC_STRPRODUCT_ADDR;
  assign o_desc_strproduct_len = DESC_STRPRODUCT_LEN;
  assign o_desc_strserial_addr = DESC_STRSERIAL_ADDR;
  assign o_desc_strserial_len = DESC_STRSERIAL_LEN;
  assign o_desc_bos_addr = DESC_BOS_ADDR;
  assign o_desc_bos_len = DESC_BOS_LEN;

  // Truncate descriptor data to keep only the necessary pieces
  localparam descrom_have_strings = (VENDORSTR_LEN > 0 || PRODUCTSTR_LEN > 0 || SERIALSTR_LEN > 0);
  localparam descrom_len = (HSSUPPORT || descrom_have_strings || BOSUPPORT) ? ((descrom_have_strings) ? DESC_END_ADDR : (BOSUPPORT) ? DESC_BOS_ADDR + DESC_BOS_LEN : DESC_OSCFG_ADDR + DESC_OSCFG_LEN) : DESC_FSCFG_ADDR + DESC_FSCFG_LEN;
  assign o_descrom_have_strings = descrom_have_strings;

  reg [7:0] descrom[0 : descrom_len-1];
  integer i;
  integer z;

  always @(posedge CLK or posedge RESET)
    if (RESET) begin
      // 18 bytes device descriptor
      descrom[0] <= 8'h12;  // bLength = 18 bytes
      descrom[1] <= 8'h01;  // bDescriptorType = device descriptor
      descrom[2] <= 8'h00;  // bcdUSB LSB
      descrom[3] <= 8'h02;  // bcdUSB MSB → 0200 = USB 2.0
      descrom[4] <= 8'hFF;  // bDeviceClass = Vendor Specific
      descrom[5] <= 8'h00;  // bDeviceSubClass = none
      descrom[6] <= 8'h00;  // bDeviceProtocol = none
      descrom[7] <= 8'h40;  // bMaxPacketSize0 = 64 bytes
      descrom[8] <= VENDORID[7 : 0];  // idVendor
      descrom[9] <= VENDORID[15 : 8];
      descrom[10] <= PRODUCTID[7 : 0];  // idProduct
      descrom[11] <= PRODUCTID[15 : 8];
      descrom[12] <= VERSIONBCD[7 : 0];  // bcdDevice
      descrom[13] <= VERSIONBCD[15 : 8];
      descrom[14] <= (VENDORSTR_LEN > 0) ? 8'h01 : 8'h00;  // iManufacturer
      descrom[15] <= (PRODUCTSTR_LEN > 0) ? 8'h02 : 8'h00;  // iProduct
      descrom[16] <= (SERIALSTR_LEN > 0) ? 8'h03 : 8'h00;  // iSerialNumber
      descrom[17] <= 8'h01;  // bNumConfigurations = 1

      // 2 bytes padding
      descrom[18] <= 8'h00;
      descrom[19] <= 8'h00;

      // 10 bytes device qualifier
      descrom[20+0] <= 8'h0a;  // bLength = 10 bytes
      descrom[20+1] <= 8'h06;  // bDescriptorType = device qualifier
      descrom[20+2] <= 8'h00;  // bcdUSB LSB
      descrom[20+3] <= 8'h02;  // bcdUSB MSB = 2.0
      descrom[20+4] <= 8'hFF;  // bDeviceClass = Vendor Specific
      descrom[20+5] <= 8'h00;  // bDeviceSubClass = none
      descrom[20+6] <= 8'h00;  // bDeviceProtocol = none
      descrom[20+7] <= 8'h40;  // bMaxPacketSize0 = 64 bytes
      descrom[20+8] <= 8'h01;  // bNumConfigurations = 1
      descrom[20+9] <= 8'h00;  // bReserved

      // 2 bytes padding
      descrom[20+10] <= 8'h00;
      descrom[20+11] <= 8'h00;

      //======Full Speed Configuration (32 bytes)
      // 9 bytes configuration header
      descrom[DESC_FSCFG_ADDR+0] <= 8'h09;  // bLength = 9 bytes
      descrom[DESC_FSCFG_ADDR+1] <= 8'h02;  // bDescriptorType = configuration descriptor
      descrom[DESC_FSCFG_ADDR+2] <= DESC_FSCFG_LEN[7:0];  // wTotalLength LSB
      descrom[DESC_FSCFG_ADDR+3] <= DESC_FSCFG_LEN[15:8];  // wTotalLength MSB
      descrom[DESC_FSCFG_ADDR+4] <= 8'h01;  // bNumInterfaces = 1
      descrom[DESC_FSCFG_ADDR+5] <= 8'h01;  // bConfigurationValue = 1
      descrom[DESC_FSCFG_ADDR+6] <= 8'h00;  // iConfiguration = none
      descrom[DESC_FSCFG_ADDR+7] <= (SELFPOWERED) ? 8'hc0 : 8'h80;  // bmAttributes
      descrom[DESC_FSCFG_ADDR+8] <= 8'h32;  // bMaxPower = 100 mA

      //---------------- Interface Descriptor -----------------
      descrom[DESC_FSCFG_ADDR+9] <= 8'h09;  // bLength = 9 bytes
      descrom[DESC_FSCFG_ADDR+10] <= 8'h04;  // bDescriptorType = interface descriptor
      descrom[DESC_FSCFG_ADDR+11] <= 8'h00;  // bInterfaceNumber = 0
      descrom[DESC_FSCFG_ADDR+12] <= 8'h00;  // bAlternateSetting = 0
      descrom[DESC_FSCFG_ADDR+13] <= 8'h02;  // bNumEndpoints = 2 (single bulk endpoint)
      descrom[DESC_FSCFG_ADDR+14] <= 8'hFF;  // bInterfaceClass = Vendor Specific
      descrom[DESC_FSCFG_ADDR+15] <= 8'h00;  // bInterfaceSubClass = none
      descrom[DESC_FSCFG_ADDR+16] <= 8'h00;  // bInterfaceProtocol = none
      descrom[DESC_FSCFG_ADDR+17] <= 8'h00;  // iInterface = none

      //----------------- Endpoint Descriptor EP1 IN (camera → PC) -----------------
      descrom[DESC_FSCFG_ADDR+18] <= 8'h07;  // bLength = 7 bytes
      descrom[DESC_FSCFG_ADDR+19] <= 8'h05;  // bDescriptorType = endpoint descriptor
      descrom[DESC_FSCFG_ADDR+20] <= 8'h81;  // bEndpointAddress = INPUT 1 (EP1 IN)
      descrom[DESC_FSCFG_ADDR+21] <= 8'h02;  // bmAttributes = Bulk Transfer
      descrom[DESC_FSCFG_ADDR+22] <= 8'h40;  // wMaxPacketSize LSB = 64 bytes (FS)
      descrom[DESC_FSCFG_ADDR+23] <= 8'h00;  // wMaxPacketSize MSB
      descrom[DESC_FSCFG_ADDR+24] <= 8'h00;  // bInterval = 0 (ignored for bulk)

      //----------------- Endpoint Descriptor EP1 OUT (PC → camera) -----------------
      descrom[DESC_FSCFG_ADDR+25] <= 8'h07;  // bLength = 7 bytes
      descrom[DESC_FSCFG_ADDR+26] <= 8'h05;  // bDescriptorType = endpoint descriptor
      descrom[DESC_FSCFG_ADDR+27] <= 8'h01;  // bEndpointAddress = OUTPUT 1 (EP1 OUT)
      descrom[DESC_FSCFG_ADDR+28] <= 8'h02;  // bmAttributes = Bulk Transfer
      descrom[DESC_FSCFG_ADDR+29] <= 8'h40;  // wMaxPacketSize LSB = 64 bytes (FS)
      descrom[DESC_FSCFG_ADDR+30] <= 8'h00;  // wMaxPacketSize MSB
      descrom[DESC_FSCFG_ADDR+31] <= 8'h00;  // bInterval = 0 (ignored for bulk)

      //======High Speed Configuration (32 bytes)
      // 9 bytes configuration header
      descrom[DESC_HSCFG_ADDR+0] <= 8'h09;  // bLength = 9 bytes
      descrom[DESC_HSCFG_ADDR+1] <= 8'h02;  // bDescriptorType = configuration descriptor
      descrom[DESC_HSCFG_ADDR+2] <= DESC_HSCFG_LEN[7:0];  // wTotalLength LSB
      descrom[DESC_HSCFG_ADDR+3] <= DESC_HSCFG_LEN[15:8];  // wTotalLength MSB
      descrom[DESC_HSCFG_ADDR+4] <= 8'h01;  // bNumInterfaces = 1
      descrom[DESC_HSCFG_ADDR+5] <= 8'h01;  // bConfigurationValue = 1
      descrom[DESC_HSCFG_ADDR+6] <= 8'h00;  // iConfiguration = none
      descrom[DESC_HSCFG_ADDR+7] <= (SELFPOWERED) ? 8'hc0 : 8'h80;  // bmAttributes
      descrom[DESC_HSCFG_ADDR+8] <= 8'h32;  // bMaxPower = 100 mA

      //---------------- Interface Descriptor -----------------
      descrom[DESC_HSCFG_ADDR+9] <= 8'h09;  // bLength = 9 bytes
      descrom[DESC_HSCFG_ADDR+10] <= 8'h04;  // bDescriptorType = interface descriptor
      descrom[DESC_HSCFG_ADDR+11] <= 8'h00;  // bInterfaceNumber = 0
      descrom[DESC_HSCFG_ADDR+12] <= 8'h00;  // bAlternateSetting = 0
      descrom[DESC_HSCFG_ADDR+13] <= 8'h02;  // bNumEndpoints = 2 (single bulk endpoint)
      descrom[DESC_HSCFG_ADDR+14] <= 8'hFF;  // bInterfaceClass = Vendor Specific
      descrom[DESC_HSCFG_ADDR+15] <= 8'h00;  // bInterfaceSubClass = none
      descrom[DESC_HSCFG_ADDR+16] <= 8'h00;  // bInterfaceProtocol = none
      descrom[DESC_HSCFG_ADDR+17] <= 8'h00;  // iInterface = none

      //----------------- Endpoint Descriptor EP1 IN (camera → PC) -----------------
      descrom[DESC_HSCFG_ADDR+18] <= 8'h07;  // bLength = 7 bytes
      descrom[DESC_HSCFG_ADDR+19] <= 8'h05;  // bDescriptorType = endpoint descriptor
      descrom[DESC_HSCFG_ADDR+20] <= 8'h81;  // bEndpointAddress = INPUT 1 (EP1 IN)
      descrom[DESC_HSCFG_ADDR+21] <= 8'h02;  // bmAttributes = Bulk Transfer
      descrom[DESC_HSCFG_ADDR+22] <= 8'h00;  // wMaxPacketSize LSB = 512 bytes (HS)
      descrom[DESC_HSCFG_ADDR+23] <= 8'h02;  // wMaxPacketSize MSB
      descrom[DESC_HSCFG_ADDR+24] <= 8'h00;  // bInterval = 0 (ignored for bulk)

      //----------------- Endpoint Descriptor EP1 OUT (PC → camera) -----------------
      descrom[DESC_HSCFG_ADDR+25] <= 8'h07;  // bLength = 7 bytes
      descrom[DESC_HSCFG_ADDR+26] <= 8'h05;  // bDescriptorType = endpoint descriptor
      descrom[DESC_HSCFG_ADDR+27] <= 8'h01;  // bEndpointAddress = OUTPUT 1 (EP1 OUT)
      descrom[DESC_HSCFG_ADDR+28] <= 8'h02;  // bmAttributes = Bulk Transfer
      descrom[DESC_HSCFG_ADDR+29] <= 8'h00;  // wMaxPacketSize LSB = 512 bytes (HS)
      descrom[DESC_HSCFG_ADDR+30] <= 8'h02;  // wMaxPacketSize MSB
      descrom[DESC_HSCFG_ADDR+31] <= 8'h00;  // bInterval = 0 (ignored for bulk)

      //======OTHER-SPEED CONFIGURATION (32 bytes)
      descrom[DESC_OSCFG_ADDR+0] <= 8'h09;  // bLength
      descrom[DESC_OSCFG_ADDR+1] <= 8'h07;  // bDescriptorType (OTHER_SPEED_CONFIGURATION)
      descrom[DESC_OSCFG_ADDR+2] <= DESC_OSCFG_LEN[7:0];  // wTotalLength LSB
      descrom[DESC_OSCFG_ADDR+3] <= DESC_OSCFG_LEN[15:8];  // wTotalLength MSB
      descrom[DESC_OSCFG_ADDR+4] <= 8'h01;  // bNumInterfaces
      descrom[DESC_OSCFG_ADDR+5] <= 8'h01;  // bConfigurationValue
      descrom[DESC_OSCFG_ADDR+6] <= 8'h00;  // iConfiguration
      descrom[DESC_OSCFG_ADDR+7] <= SELFPOWERED ? 8'hC0 : 8'h80;  // bmAttributes
      descrom[DESC_OSCFG_ADDR+8] <= 8'h32;  // bMaxPower = 100 mA

      // --- Interface Descriptor (9 bytes) ---
      descrom[DESC_OSCFG_ADDR+9] <= 8'h09;  // bLength
      descrom[DESC_OSCFG_ADDR+10] <= 8'h04;  // bDescriptorType (INTERFACE)
      descrom[DESC_OSCFG_ADDR+11] <= 8'h00;  // bInterfaceNumber
      descrom[DESC_OSCFG_ADDR+12] <= 8'h00;  // bAlternateSetting
      descrom[DESC_OSCFG_ADDR+13] <= 8'h02;  // bNumEndpoints = 2 (single bulk endpoint)
      descrom[DESC_OSCFG_ADDR+14] <= 8'hFF;  // bInterfaceClass (Vendor-defined)
      descrom[DESC_OSCFG_ADDR+15] <= 8'h00;  // bInterfaceSubClass = none
      descrom[DESC_OSCFG_ADDR+16] <= 8'h00;  // bInterfaceProtocol = none
      descrom[DESC_OSCFG_ADDR+17] <= 8'h00;  // iInterface

      //----------------- Endpoint Descriptor EP1 IN (camera → PC) -----------------
      descrom[DESC_OSCFG_ADDR+18] <= 8'h07;  // bLength
      descrom[DESC_OSCFG_ADDR+19] <= 8'h05;  // bDescriptorType (ENDPOINT)
      descrom[DESC_OSCFG_ADDR+20] <= 8'h81;  // bEndpointAddress (EP1 IN)
      descrom[DESC_OSCFG_ADDR+21] <= 8'h02;  // bmAttributes (Bulk)
      descrom[DESC_OSCFG_ADDR+22] <= 8'h40;  // wMaxPacketSize LSB = 64 bytes (other speed)
      descrom[DESC_OSCFG_ADDR+23] <= 8'h00;  // wMaxPacketSize MSB
      descrom[DESC_OSCFG_ADDR+24] <= 8'h00;  // bInterval (ignored for Bulk)

      //----------------- Endpoint Descriptor EP1 OUT (PC → camera) -----------------
      descrom[DESC_OSCFG_ADDR+25] <= 8'h07;  // bLength
      descrom[DESC_OSCFG_ADDR+26] <= 8'h05;  // bDescriptorType (ENDPOINT)
      descrom[DESC_OSCFG_ADDR+27] <= 8'h01;  // bEndpointAddress (EP1 OUT)
      descrom[DESC_OSCFG_ADDR+28] <= 8'h02;  // bmAttributes (Bulk)
      descrom[DESC_OSCFG_ADDR+29] <= 8'h40;  // wMaxPacketSize LSB = 64 bytes (HS)
      descrom[DESC_OSCFG_ADDR+30] <= 8'h00;  // wMaxPacketSize MSB
      descrom[DESC_OSCFG_ADDR+31] <= 8'h00;  // bInterval (ignored for Bulk)

      if (BOSUPPORT && (descrom_len > DESC_BOS_ADDR)) begin
        // BOS Descriptor (15 bytes)
        descrom[DESC_BOS_ADDR+0] <= 8'h05;  // bLength = 5 bytes
        descrom[DESC_BOS_ADDR+1] <= 8'h0F;  // bDescriptorType = BOS
        descrom[DESC_BOS_ADDR+2] <= BOS_LEN[7:0];  // wTotalLength LSB
        descrom[DESC_BOS_ADDR+3] <= BOS_LEN[15:8];  // wTotalLength MSB
        descrom[DESC_BOS_ADDR+4] <= 8'h01;  // bNumDeviceCaps = 1

        // USB 2.0 Extension Capability (10 bytes)
        descrom[DESC_BOS_ADDR+5] <= 8'h0A;  // bLength = 10 bytes
        descrom[DESC_BOS_ADDR+6] <= 8'h10;  // bDescriptorType = Device Capability
        descrom[DESC_BOS_ADDR+7] <= 8'h02;  // bDevCapabilityType = USB 2.0 Extension
        descrom[DESC_BOS_ADDR+8] <= 8'h02;  // bmAttributes = LPM support
        descrom[DESC_BOS_ADDR+9] <= 8'h00;  // bmAttributes[15:8]
        descrom[DESC_BOS_ADDR+10] <= 8'h00;  // bmAttributes[23:16]
        descrom[DESC_BOS_ADDR+11] <= 8'h00;  // bmAttributes[31:24]
        descrom[DESC_BOS_ADDR+12] <= 8'h00;  // Reserved
        descrom[DESC_BOS_ADDR+13] <= 8'h00;  // Reserved
        descrom[DESC_BOS_ADDR+14] <= 8'h00;  // Reserved
      end

      if (descrom_len > DESC_STRLANG_ADDR) begin
        // string descriptor 0 (supported languages)
        descrom[DESC_STRLANG_ADDR+0] <= 8'h04;  // bLength = 4
        descrom[DESC_STRLANG_ADDR+1] <= 8'h03;  // bDescriptorType = string descriptor
        descrom[DESC_STRLANG_ADDR+2] <= 8'h09;
        descrom[DESC_STRLANG_ADDR+3] <= 8'h04;  // wLangId[0] = 0x0409 = English U.S.

        descrom[DESC_STRVENDOR_ADDR+0] <= 2 + 2 * VENDORSTR_LEN;
        descrom[DESC_STRVENDOR_ADDR+1] <= 8'h03;
        for (i = 0; i < VENDORSTR_LEN; i = i + 1) begin
          for (z = 0; z < 8; z = z + 1) begin
            descrom[DESC_STRVENDOR_ADDR+2*i+2][z] <= VENDORSTR[(VENDORSTR_LEN-1-i)*8+z];
          end
          descrom[DESC_STRVENDOR_ADDR+2*i+3] <= 8'h00;
        end

        descrom[DESC_STRPRODUCT_ADDR+0] <= 2 + 2 * PRODUCTSTR_LEN;
        descrom[DESC_STRPRODUCT_ADDR+1] <= 8'h03;
        for (i = 0; i < PRODUCTSTR_LEN; i = i + 1) begin
          for (z = 0; z < 8; z = z + 1) begin
            descrom[DESC_STRPRODUCT_ADDR+2*i+2][z] <= PRODUCTSTR[(PRODUCTSTR_LEN-1-i)*8+z];
          end
          descrom[DESC_STRPRODUCT_ADDR+2*i+3] <= 8'h00;
        end

        descrom[DESC_STRSERIAL_ADDR+0] <= 2 + 2 * SERIALSTR_LEN;
        descrom[DESC_STRSERIAL_ADDR+1] <= 8'h03;
        for (i = 0; i < SERIALSTR_LEN; i = i + 1) begin
          for (z = 0; z < 8; z = z + 1) begin
            descrom[DESC_STRSERIAL_ADDR+2*i+2][z] <= SERIALSTR[(SERIALSTR_LEN-1-i)*8+z];
          end
          descrom[DESC_STRSERIAL_ADDR+2*i+3] <= 8'h00;
        end
      end
    end else begin
      descrom[8] <= ((i_pid != 16'h0000) && (i_pid != 16'hFFFF)) ? i_pid[7:0] : VENDORID[7 : 0];  // idVendor
      descrom[9] <= ((i_pid != 16'h0000) && (i_pid != 16'hFFFF)) ? i_pid[15:8] : VENDORID[15 : 8];
      descrom[10] <= ((i_vid != 16'h0000) && (i_vid != 16'hFFFF)) ? i_vid[7:0] : PRODUCTID[7 : 0];  // idProduct
      descrom[11] <= ((i_vid != 16'h0000) && (i_vid != 16'hFFFF)) ? i_vid[15:8] : PRODUCTID[15 : 8];
    end

  assign o_descrom_rdat = descrom[i_descrom_raddr];
endmodule
