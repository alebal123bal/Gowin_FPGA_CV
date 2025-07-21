`timescale 1ns / 1ns
module tb_ov5640_data ();

  //// Parameters and Internal Signals ////

  // Parameter definitions
  parameter H_VALID = 10'd640,  // Valid pixels per line
  H_TOTAL = 10'd784;  // Total pixels per line (including blanking)
  parameter V_SYNC = 10'd4,  // Vertical sync period
  V_BACK = 10'd18,  // Vertical back porch
  V_VALID = 10'd480,  // Valid lines per frame
  V_FRONT = 10'd8,  // Vertical front porch
  V_TOTAL = 10'd510;  // Total lines per frame

  // Wire definitions
  wire        ov5640_wr_en;  // Valid image enable signal
  wire [15:0] ov5640_data_out;  // Valid image data
  wire        ov5640_href;  // Horizontal sync signal
  wire        ov5640_vsync;  // Vertical sync signal

  // Register definitions
  reg         sys_clk;  // Simulated clock signal
  reg         sys_rst_n;  // Simulated reset signal
  reg  [ 7:0] ov5640_data;  // Simulated camera image data
  reg  [11:0] cnt_h;  // Horizontal sync counter
  reg  [ 9:0] cnt_v;  // Vertical sync counter

  //// Main Code ////

  // Clock and reset initialization
  initial begin
    sys_clk = 1'b1;
    sys_rst_n <= 1'b0;
    #200 sys_rst_n <= 1'b1;
  end

  // Clock generation (25MHz)
  always #20 sys_clk = ~sys_clk;

  // Horizontal counter
  always @(posedge sys_clk or negedge sys_rst_n)
    if (sys_rst_n == 1'b0) cnt_h <= 12'd0;
    else if (cnt_h == ((H_TOTAL * 2) - 1'b1)) cnt_h <= 12'd0;
    else cnt_h <= cnt_h + 1'd1;

  // Generate href signal
  assign ov5640_href = (((cnt_h >= 0) 
                    && (cnt_h <= ((H_VALID * 2) - 1'b1)))
                    && ((cnt_v >= (V_SYNC + V_BACK))
                    && (cnt_v <= (V_SYNC + V_BACK + V_VALID - 1'b1))))
                    ? 1'b1 : 1'b0;

  // Vertical counter
  always @(posedge sys_clk or negedge sys_rst_n)
    if (sys_rst_n == 1'b0) cnt_v <= 10'd0;
    else if ((cnt_v == (V_TOTAL - 1'b1)) && (cnt_h == ((H_TOTAL * 2) - 1'b1))) cnt_v <= 10'd0;
    else if (cnt_h == ((H_TOTAL * 2) - 1'b1)) cnt_v <= cnt_v + 1'd1;
    else cnt_v <= cnt_v;

  // Generate vsync signal
  assign ov5640_vsync = (cnt_v <= (V_SYNC - 1'b1)) ? 1'b1 : 1'b0;

  // Generate simulated camera data
  always @(posedge sys_clk or negedge sys_rst_n)
    if (sys_rst_n == 1'b0) ov5640_data <= 8'd0;
    else if (ov5640_href == 1'b1) ov5640_data <= ov5640_data + 1'b1;
    else ov5640_data <= 8'd0;

  //// Module Instantiation ////

  // Instantiate ov5640_data module
  ov5640_data ov5640_data_inst (
      .sys_rst_n   (sys_rst_n),     // Reset signal
      .ov5640_pclk (sys_clk),       // Camera pixel clock
      .ov5640_href (ov5640_href),   // Camera line sync signal
      .ov5640_vsync(ov5640_vsync),  // Camera frame sync signal
      .ov5640_data (ov5640_data),   // Camera image data

      .ov5640_wr_en   (ov5640_wr_en),    // Image data valid enable signal
      .ov5640_data_out(ov5640_data_out)  // Image data output
  );

  // Simulation stop time
  initial begin
    #40000000  // Run for 40ms (at least one picture @30FPS)
    $stop;  // Or $finish;
  end

endmodule
