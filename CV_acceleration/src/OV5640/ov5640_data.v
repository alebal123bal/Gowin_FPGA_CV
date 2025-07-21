module ov5640_data (
    input  wire        sys_rst_n,       // Reset signal
    // OV5640
    input  wire        ov5640_pclk,     // Camera pixel clock
    input  wire        ov5640_href,     // Camera line sync signal
    input  wire        ov5640_vsync,    // Camera frame sync signal
    input  wire [ 7:0] ov5640_data,     // Camera image data
    // Write FIFO
    output wire        ov5640_wr_en,    // Image data valid enable signal
    output wire [15:0] ov5640_data_out  // Image data output
);

  //// Parameters and Internal Signals ////

  // Parameter definitions
  parameter PIC_WAIT = 4'd10;  // Number of frames to wait for image stabilization

  // Wire definitions
  wire        pic_flag;  // Frame image flag signal, indicates one complete frame when high

  // Register definitions
  reg         ov5640_vsync_dly;  // Camera vsync signal delayed
  reg  [ 3:0] cnt_pic;  // Image frame counter
  reg         pic_valid;  // Frame valid flag
  reg  [ 7:0] pic_data_reg;  // Input 8-bit image data buffer
  reg  [15:0] data_out_reg;  // Output 16-bit image data buffer
  reg         data_flag;  // Input 8-bit image data buffer flag
  reg         data_flag_dly1;  // Delayed image data concatenation flag

  //// Main Code ////

  // Delay camera vsync signal by one clock
  always @(posedge ov5640_pclk or negedge sys_rst_n)
    if (sys_rst_n == 1'b0) ov5640_vsync_dly <= 1'b0;
    else ov5640_vsync_dly <= ov5640_vsync;

  // Generate frame flag signal (indicates start of new frame)
  assign pic_flag = ((ov5640_vsync_dly == 1'b0) && (ov5640_vsync == 1'b1)) ? 1'b1 : 1'b0;

  // Frame counter
  always @(posedge ov5640_pclk or negedge sys_rst_n)
    if (sys_rst_n == 1'b0) cnt_pic <= 4'd0;
    else if (cnt_pic < PIC_WAIT) cnt_pic <= cnt_pic + 1'b1;
    else cnt_pic <= cnt_pic;

  // Valid frame flag
  always @(posedge ov5640_pclk or negedge sys_rst_n)
    if (sys_rst_n == 1'b0) pic_valid <= 1'b0;
    else if ((cnt_pic == PIC_WAIT) && (pic_flag == 1'b1)) pic_valid <= 1'b1;
    else pic_valid <= pic_valid;

  // Handle 16-bit image data buffering and 8-to-16 bit conversion
  always @(posedge ov5640_pclk or negedge sys_rst_n)
    if (sys_rst_n == 1'b0) begin
      data_out_reg <= 16'd0;
      pic_data_reg <= 8'd0;
      data_flag <= 1'b0;
    end else if (ov5640_href == 1'b1) begin
      data_flag <= ~data_flag;
      pic_data_reg <= ov5640_data;
      data_out_reg <= data_out_reg;
      if (data_flag == 1'b1) data_out_reg <= {pic_data_reg, ov5640_data};
      else data_out_reg <= data_out_reg;
    end else begin
      data_flag <= 1'b0;
      pic_data_reg <= 8'd0;
      data_out_reg <= data_out_reg;
    end

  // Delay data flag
  always @(posedge ov5640_pclk or negedge sys_rst_n)
    if (sys_rst_n == 1'b0) data_flag_dly1 <= 1'b0;
    else data_flag_dly1 <= data_flag;

  // Output 16-bit image data
  assign ov5640_data_out = (pic_valid == 1'b1) ? data_out_reg : 16'b0;

  // Output write enable signal
  assign ov5640_wr_en = (pic_valid == 1'b1) ? data_flag_dly1 : 1'b0;

endmodule
