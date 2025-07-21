// Camera power-on timing requirement
module power_on_delay (
    input  clk_27,       // 27 MHz clock
    input  rst_n,        // Active-low reset
    output camera_pwnd,  // Camera power-down (active-low)
    output camera_rstn   // Camera reset (active-low)
);

  // Internal registers
  reg [31:0] counter;
  reg camera_rstn_reg;
  reg camera_pwnd_reg;

  // Output assignments
  assign camera_rstn = camera_rstn_reg;
  assign camera_pwnd = camera_pwnd_reg;

  // Timing logic
  always @(posedge clk_27 or negedge rst_n) begin
    if (!rst_n) begin
      // Reset state
      counter <= 32'd0;
      camera_pwnd_reg <= 1'b1;  // Assert power-down
      camera_rstn_reg <= 1'b0;  // Assert reset
    end else begin
      // Increment counter
      counter <= counter + 1;

      // Timing sequence
      if (counter > 32'd1 && counter < 32'd135000) begin
        camera_pwnd_reg <= 1'b1;  // Keep power-down asserted
        camera_rstn_reg <= 1'b0;  // Keep reset asserted
      end else if (counter >= 32'd135000 && counter < 32'd170000) begin
        camera_pwnd_reg <= 1'b0;  // Release power-down
        camera_rstn_reg <= 1'b0;  // Keep reset
      end else if (counter >= 32'd170000) begin
        camera_pwnd_reg <= 1'b0;  // Release power-down
        camera_rstn_reg <= 1'b1;  // Release reset
      end
    end
  end

endmodule
