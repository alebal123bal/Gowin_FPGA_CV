//Copyright (C)2014-2024 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//Tool Version: V1.9.9.03 Education (64-bit)
//Part Number: GW2A-LV18PG256C8/I7
//Device: GW2A-18
//Device Version: C
//Created Time: Wed Jan  1 19:06:32 2025

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

	I2C_MASTER_Top your_instance_name(
		.I_CLK(I_CLK), //input I_CLK
		.I_RESETN(I_RESETN), //input I_RESETN
		.I_TX_EN(I_TX_EN), //input I_TX_EN
		.I_WADDR(I_WADDR), //input [2:0] I_WADDR
		.I_WDATA(I_WDATA), //input [7:0] I_WDATA
		.I_RX_EN(I_RX_EN), //input I_RX_EN
		.I_RADDR(I_RADDR), //input [2:0] I_RADDR
		.O_RDATA(O_RDATA), //output [7:0] O_RDATA
		.O_IIC_INT(O_IIC_INT), //output O_IIC_INT
		.SCL(SCL), //inout SCL
		.SDA(SDA) //inout SDA
	);

//--------Copy end-------------------
