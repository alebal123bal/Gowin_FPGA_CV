module ov5640_cfg_better
(
    input wire sys_clk,          // System clock from IIC module
    input wire sys_rst_n,        // System reset, active low
    input wire cfg_end,          // Single register configuration complete

    output reg cfg_start,        // Single register configuration trigger signal
    output wire [23:0] cfg_data, // ID, REG_ADDR, REG_VAL
    output reg cfg_done          // Register configuration complete
);

//// Parameters and Internal Signals ////

// Parameter definitions
parameter REG_NUM = 10'd5;        // Total number of registers to configure
parameter CNT_WAIT_MAX = 20'd30000; // Wait count before register configuration

// Wire definitions
wire [23:0] cfg_data_reg[REG_NUM-1:0]; // Register configuration data buffer

// Register definitions
reg [14:0] cnt_wait;                // Register configuration wait counter
reg [9:0] reg_num;                 // Number of configured registers

//// Main Code ////

// cnt_wait: Register configuration wait counter
always @(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        cnt_wait <= 15'd0;
    else if(cnt_wait < CNT_WAIT_MAX)
        cnt_wait <= cnt_wait + 1'b1;

// reg_num: Number of configured registers
always @(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        reg_num <= 10'd0;
    else if(cfg_end == 1'b1)
        reg_num <= reg_num + 1'b1;

// cfg_start: Single register configuration trigger signal
always @(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        cfg_start <= 1'b0;
    else if(reg_num == 0 && cnt_wait == (CNT_WAIT_MAX - 1'b1))
        cfg_start <= 1'b1;
    else if((cfg_end == 1'b1) && (reg_num < REG_NUM))
        cfg_start <= 1'b1;
    else
        cfg_start <= 1'b0;

// cfg_done: Register configuration complete
always @(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        cfg_done <= 1'b0;
    else if((reg_num == REG_NUM) && (cfg_end == 1'b1))
        cfg_done <= 1'b1;

// cfg_data: ID, REG_ADDR, REG_VAL
assign cfg_data = (cfg_done == 1'b1) ? 24'b0 : cfg_data_reg[reg_num];

// Register configuration data buffer
// Format: {16-bit register address, 8-bit register value}
assign cfg_data_reg[001] = {24'h300882};// software reset, bit[7]// delay 5ms
assign cfg_data_reg[002] = {24'h300842};// software power down, bit[6]
assign cfg_data_reg[003] = {24'h310303};// system clock from PLL, bit[1]
assign cfg_data_reg[004] = {24'h300802};// Chip Power Up

endmodule