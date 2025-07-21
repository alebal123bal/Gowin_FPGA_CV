module ov5640_top (
    input  wire        sys_clk,         // System clock
    input  wire        sys_rst_n,       // Reset signal
    input  wire        sys_init_done,   // System initialization complete (SDRAM + Camera)
    input  wire        ov5640_pclk,     // Camera pixel clock
    input  wire        ov5640_href,     // Camera horizontal sync signal
    input  wire        ov5640_vsync,    // Camera vertical sync signal
    input  wire [ 7:0] ov5640_data,     // Camera image data
    output wire        cfg_done,        // Register configuration complete
    output wire        sccb_scl,        // SCL signal
    output wire        sccb_sda,        // SDA signal
    output wire        ov5640_wr_en,    // Image data valid enable signal
    output wire [15:0] ov5640_data_out
);  // Image data output

  //// Parameters and Internal Signals ////

  // Parameter definitions
  parameter SLAVE_ADDR = 7'h3C;         // OV5640 device address (it's actually 0x78, but with this i2c controller it's shifted)
  parameter BIT_CTRL = 1'b1;  // Address bit control (16-bit for OV5640)
  parameter CLK_FREQ = 26'd24_000_000;  // i2c_dri module drive clock frequency
  parameter I2C_FREQ = 19'd250_000;  // I2C SCL clock frequency

  // Wire definitions
  wire cfg_end;
  wire cfg_start;
  wire [23:0] cfg_data;
  wire cfg_clk;

  //// Module Instantiations ////

  // I2C Controller Instance
  i2c_ctrl #(
      .DEVICE_ADDR (SLAVE_ADDR),  // I2C device address
      .SYS_CLK_FREQ(CLK_FREQ),    // i2c_ctrl module system clock frequency
      .SCL_FREQ    (I2C_FREQ)     // I2C SCL clock frequency
  ) i2c_ctrl_inst (
      .sys_clk  (sys_clk),         // Input system clock, 50MHz
      .sys_rst_n(sys_rst_n),       // Input reset signal, active low
      .wr_en    (1'b1),            // Input write enable signal
      .rd_en    (),                // Input read enable signal
      .i2c_start(cfg_start),       // Input i2c trigger signal
      .addr_num (BIT_CTRL),        // Input i2c byte address count
      .byte_addr(cfg_data[23:8]),  // Input i2c byte address
      .wr_data  (cfg_data[7:0]),   // Input i2c device data

      .rd_data(),          // Output i2c device read data
      .i2c_end(cfg_end),   // I2C read/write operation complete
      .i2c_clk(cfg_clk),   // I2C drive clock
      .i2c_scl(sccb_scl),  // Output serial clock signal to i2c device
      .i2c_sda(sccb_sda)   // Output serial data signal to i2c device
  );

  // OV5640 Configuration Instance
  ov5640_cfg_better_indexed ov5640_cfg_inst (
      .sys_clk  (cfg_clk),    // System clock from i2c module
      .sys_rst_n(sys_rst_n),  // System reset, active low
      .cfg_end  (cfg_end),    // Single register configuration complete

      .cfg_start(cfg_start),  // Single register configuration trigger
      .cfg_data (cfg_data),   // ID, REG_ADDR, REG_VAL
      .cfg_done (cfg_done)    // Register configuration complete
  );

  // OV5640 Data Instance
  ov5640_data ov5640_data_inst (
      .sys_rst_n   (sys_rst_n),     // Reset signal
      .ov5640_pclk (ov5640_pclk),   // Camera pixel clock
      .ov5640_href (ov5640_href),   // Camera line sync signal
      .ov5640_vsync(ov5640_vsync),  // Camera frame sync signal
      .ov5640_data (ov5640_data),   // Camera image data

      .ov5640_wr_en   (ov5640_wr_en),  // Image data valid enable signal
      .ov5640_data_out(ov5640_data_out)// Image data output
  );

endmodule
