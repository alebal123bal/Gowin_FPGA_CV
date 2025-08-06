`timescale 1ns / 1ps

module power_on_delay_tb ();

  reg clk_27 = 0;
  reg rst_n = 0;

  wire camera_pwnd;  // 1 = camera power-down asserted (camera OFF)
  wire camera_rstn;  // 0 = camera held in reset

  power_on_delay dut (
      .clk_27(clk_27),
      .rst_n(rst_n),
      .camera_pwnd(camera_pwnd),
      .camera_rstn(camera_rstn)
  );

  always #18.5 clk_27 = ~clk_27;

  initial begin
    rst_n = 0;
    repeat (5) @(posedge clk_27);

    rst_n = 1;
    repeat (170002) @(posedge clk_27);  // run past final transition

    $display("time=%0t camera_pwnd=%b (expect 0; 0=ON)", $time, camera_pwnd);
    $display("time=%0t camera_rstn=%b (expect 1; 1=Run)", $time, camera_rstn);

    if (camera_pwnd === 1'b0 && camera_rstn === 1'b1) $display("PASS");
    else $display("FAIL");

    $finish;
  end
endmodule
