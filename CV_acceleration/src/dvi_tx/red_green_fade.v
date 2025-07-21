// Working at 74.25MHz	--> 1280x720 @ 60FPS
// Red to green fade pattern generator

module red_green_fade (
    input            I_pxl_clk,
    input            I_rst_n,
    input            I_vs,       // Basically, "end of frame"
    output reg [7:0] O_data_r,
    output reg [7:0] O_data_g,
    output reg [7:0] O_data_b
);

  // Frame and color control
  reg [4:0] frame_count;
  reg       vs_prev;
  reg [7:0] color_value;
  reg       direction;

  // Frame detection and color fade control
  always @(posedge I_pxl_clk or negedge I_rst_n) begin
    if (!I_rst_n) begin
      vs_prev <= 1'b0;
      frame_count <= 5'd0;
      color_value <= 8'd0;
      direction <= 1'b0;
    end else begin
      vs_prev <= I_vs;

      // Detect frame transition on VS falling edge
      if (vs_prev && !I_vs) begin
        // New frame starts here
        if (frame_count == 5'd29) begin
          frame_count <= 5'd0;
          direction   <= ~direction;
        end else begin
          frame_count <= frame_count + 1'b1;
        end

        // Update color value
        if (!direction) color_value <= frame_count * (8'd255 / 5'd29);
        else color_value <= 8'd255 - (frame_count * (8'd255 / 5'd29));
      end
    end
  end

  // Output color assignment
  always @(posedge I_pxl_clk or negedge I_rst_n) begin
    if (!I_rst_n) begin
      O_data_r <= 8'd0;
      O_data_g <= 8'd255;
      O_data_b <= 8'd0;
    end else begin
      O_data_r <= color_value;
      O_data_g <= 8'd255 - color_value;
      O_data_b <= 8'd0;
    end
  end

endmodule
