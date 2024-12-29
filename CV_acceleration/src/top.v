`timescale 1ns / 1ps

module top (
    input clk,                  // 27 MHz clock
    input rst_n,                // Active low reset
    output uart_tx,             // UART TX pin
    output Voltage,             // LED
    output [2:0] O_tmds_data_p,       // HDMI positive RGB data
    output [2:0] O_tmds_data_n,       // HDMI negative RGB data
    output O_tmds_clk_p,  // HDMI positive CLK
    output O_tmds_clk_n   // HDMI negative CLK
);

// Parameters
parameter CLK_FREQ = 27;        // 27 MHz
parameter BAUD_RATE = 115200;   // 115200 bps

// Signals
// wire clk_135_MHz;

// Registers
// reg[31:0] counter_135_MHz;
reg Voltage_reg;

// HDMI
wire [7:0] I_rgb_r, I_rgb_g, I_rgb_b;
wire I_rgb_hs, I_rgb_vs, de;

// Instantiate rPLL at 135MHz
// Gowin_rPLL PLL_135_MHz(
//     .clkout(clk_135_MHz), //output clkout
//     .clkin(clk) //input clkin
// );

// Green screen generator instance
green_screen_gen green_gen (
    .clk_27(clk),          // 27MHz clock
    .rst_n(rst_n),        // Active low reset
    .rgb_red(I_rgb_r),
    .rgb_green(I_rgb_g),
    .rgb_blue(I_rgb_b),
    .hsync(I_rgb_hs),
    .vsync(I_rgb_vs),
    .de(de)
);

// Your HDMI controller instance
// hdmi_ctrl hdmi_inst (
//     .clk_1x(clk),          // 27MHz clock
//     .clk_5x(clk_135_MHz),         // 135MHz clock (5x)
//     .sys_rst_n(rst_n),
//     .rgb_red(rgb_red),
//     .rgb_green(rgb_green),
//     .rgb_blue(rgb_blue),
//     .hsync(I_rgb_hs),
//     .vsync(I_rgb_vs),
//     .de(de),
//     .hdmi_clk_p(hdmi_clk_p),
//     .hdmi_clk_n(hdmi_clk_n),
//     .hdmi_r_p(hdmi_r_p),
//     .hdmi_r_n(hdmi_r_n),
//     .hdmi_g_p(hdmi_g_p),
//     .hdmi_g_n(hdmi_g_n),
//     .hdmi_b_p(hdmi_b_p),
//     .hdmi_b_n(hdmi_b_n)
// );


// Use this IP
DVI_TX_Top my_HDMI_TX(
    .I_rst_n(rst_n), //input I_rst_n
    .I_rgb_clk(clk), //input I_rgb_clk
    .I_rgb_vs(I_rgb_vs), //input I_rgb_vs
    .I_rgb_hs(I_rgb_hs), //input I_rgb_hs
    .I_rgb_de(de), //input I_rgb_de
    .I_rgb_r(I_rgb_r), //input [7:0] I_rgb_r
    .I_rgb_g(I_rgb_g), //input [7:0] I_rgb_g
    .I_rgb_b(I_rgb_b), //input [7:0] I_rgb_b
    .O_tmds_clk_p(O_tmds_clk_p), //output O_tmds_clk_p
    .O_tmds_clk_n(O_tmds_clk_n), //output O_tmds_clk_n
    .O_tmds_data_p(O_tmds_data_p), //output [2:0] O_tmds_data_p
    .O_tmds_data_n(O_tmds_data_n) //output [2:0] O_tmds_data_n
);

// Quickly check if LED blinks every 1 second at 135MHz 
// always @(posedge clk_135_MHz or negedge rst_n) begin
//     if (!rst_n) begin
//         counter_135_MHz <= 0;
//         Voltage_reg <= 1'b0;
//     end else begin
//         if (counter_135_MHz == 135_000_000 - 1) begin
//             counter_135_MHz <= 0;
//             Voltage_reg <= ~Voltage_reg;
//         end else begin
//             counter_135_MHz <= counter_135_MHz + 1;
//             Voltage_reg <= Voltage_reg;
//         end
//     end
// end

// Combinatorial logic
assign Voltage = 1'b0;

endmodule