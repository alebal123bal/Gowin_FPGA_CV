//Copyright (C)2014-2024 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: IP file
//Tool Version: V1.9.9.03 Education (64-bit)
//Part Number: GW2A-LV18PG256C8/I7
//Device: GW2A-18
//Device Version: C
//Created Time: Thu Oct 31 12:43:44 2024

module Gowin_pROM (dout, clk, oce, ce, reset, ad);

output [7:0] dout;
input clk;
input oce;
input ce;
input reset;
input [3:0] ad;

wire [23:0] prom_inst_0_dout_w;
wire gw_gnd;

assign gw_gnd = 1'b0;

pROM prom_inst_0 (
    .DO({prom_inst_0_dout_w[23:0],dout[7:0]}),
    .CLK(clk),
    .OCE(oce),
    .CE(ce),
    .RESET(reset),
    .AD({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,ad[3:0],gw_gnd,gw_gnd,gw_gnd})
);

defparam prom_inst_0.READ_MODE = 1'b0;
defparam prom_inst_0.BIT_WIDTH = 8;
defparam prom_inst_0.RESET_MODE = "SYNC";
defparam prom_inst_0.INIT_RAM_00 = 256'h0000000000000000000000000000000000000A0D216E75662073692041475046;

endmodule //Gowin_pROM
