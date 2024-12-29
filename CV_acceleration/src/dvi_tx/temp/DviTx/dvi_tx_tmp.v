//Copyright (C)2014-2024 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//Tool Version: V1.9.9.03 Education (64-bit)
//Part Number: GW2A-LV18PG256C8/I7
//Device: GW2A-18
//Device Version: C
//Created Time: Sun Dec 29 14:35:57 2024

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

	DVI_TX_Top your_instance_name(
		.I_rst_n(I_rst_n), //input I_rst_n
		.I_rgb_clk(I_rgb_clk), //input I_rgb_clk
		.I_rgb_vs(I_rgb_vs), //input I_rgb_vs
		.I_rgb_hs(I_rgb_hs), //input I_rgb_hs
		.I_rgb_de(I_rgb_de), //input I_rgb_de
		.I_rgb_r(I_rgb_r), //input [7:0] I_rgb_r
		.I_rgb_g(I_rgb_g), //input [7:0] I_rgb_g
		.I_rgb_b(I_rgb_b), //input [7:0] I_rgb_b
		.O_tmds_clk_p(O_tmds_clk_p), //output O_tmds_clk_p
		.O_tmds_clk_n(O_tmds_clk_n), //output O_tmds_clk_n
		.O_tmds_data_p(O_tmds_data_p), //output [2:0] O_tmds_data_p
		.O_tmds_data_n(O_tmds_data_n) //output [2:0] O_tmds_data_n
	);

//--------Copy end-------------------
