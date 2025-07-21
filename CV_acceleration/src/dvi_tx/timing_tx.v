// Working at 74.25MHz	--> 1280x720 @ 60FPS

module timing_tx (
    input             I_pxl_clk,
    input             I_rst_n,
    input      [11:0] I_h_total,
    input      [11:0] I_h_sync,
    input      [11:0] I_h_bporch,
    input      [11:0] I_h_res,
    input      [11:0] I_v_total,
    input      [11:0] I_v_sync,
    input      [11:0] I_v_bporch,
    input      [11:0] I_v_res,
    input             I_hs_pol,
    input             I_vs_pol,
    output            O_de,
    output reg        O_hs,
    output reg        O_vs
);

  reg  [11:0] V_cnt;
  reg  [11:0] H_cnt;
  wire        Pout_de_w;
  wire        Pout_hs_w;
  wire        Pout_vs_w;

  // Horizontal counter
  always @(posedge I_pxl_clk or negedge I_rst_n) begin
    if (!I_rst_n) H_cnt <= 12'd0;
    else if (H_cnt >= (I_h_total - 1'b1)) H_cnt <= 12'd0;
    else H_cnt <= H_cnt + 1'b1;
  end

  // Vertical counter
  always @(posedge I_pxl_clk or negedge I_rst_n) begin
    if (!I_rst_n) V_cnt <= 12'd0;
    else if ((V_cnt >= (I_v_total - 1'b1)) && (H_cnt >= (I_h_total - 1'b1))) V_cnt <= 12'd0;
    else if (H_cnt >= (I_h_total - 1'b1)) V_cnt <= V_cnt + 1'b1;
  end

  // Generate sync signals
  assign Pout_de_w = ((H_cnt >= (I_h_sync + I_h_bporch)) && 
                    (H_cnt <= (I_h_sync + I_h_bporch + I_h_res - 1'b1))) &&
                   ((V_cnt >= (I_v_sync + I_v_bporch)) &&
                    (V_cnt <= (I_v_sync + I_v_bporch + I_v_res - 1'b1)));
  assign Pout_hs_w = ~((H_cnt >= 12'd0) && (H_cnt <= (I_h_sync - 1'b1)));
  assign Pout_vs_w = ~((V_cnt >= 12'd0) && (V_cnt <= (I_v_sync - 1'b1)));

  always @(posedge I_pxl_clk or negedge I_rst_n) begin
    if (!I_rst_n) begin
      O_hs <= 1'b1;
      O_vs <= 1'b1;
    end else begin
      O_hs <= I_hs_pol ? ~Pout_hs_w : Pout_hs_w;
      O_vs <= I_vs_pol ? ~Pout_vs_w : Pout_vs_w;
    end
  end

  assign O_de = Pout_de_w;

endmodule
