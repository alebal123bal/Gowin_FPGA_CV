// Camera power-on timing requirement
module power_on_delay (
    input clk_27,  // 27 MHz clock
    input rst_n,  // Active-low reset
    output camera_pwnd,  // Camera power-down (active-low: 1 = OFF, 0 = ON)
    output camera_rstn  // Camera reset  (active-low: 0 = Reset, 1 = Run)
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
      camera_pwnd_reg <= 1'b1;  // keep camera OFF (power-down asserted)
      camera_rstn_reg <= 1'b0;  // keep camera in reset
    end else begin
      // Increment counter
      counter <= counter + 1;

      // Timing sequence
      if (counter > 32'd1 && counter < 32'd135000) begin
        camera_pwnd_reg <= 1'b1;  // OFF
        camera_rstn_reg <= 1'b0;  // reset held
      end else if (counter >= 32'd135000 && counter < 32'd170000) begin
        camera_pwnd_reg <= 1'b0;  // ON
        camera_rstn_reg <= 1'b0;  // reset still held
      end else if (counter >= 32'd170000) begin
        camera_pwnd_reg <= 1'b0;  // ON
        camera_rstn_reg <= 1'b1;  // reset released
      end
    end
  end

endmodule
