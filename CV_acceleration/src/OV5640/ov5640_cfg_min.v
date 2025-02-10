module ov5640_cfg_min
(
    input wire sys_clk,        // System clock from IIC module
    input wire sys_rst_n,      // System reset, active low
    input wire cfg_end,        // Single register configuration complete

    output reg cfg_start,      // Single register configuration trigger signal
    output wire [23:0] cfg_data, // ID, REG_ADDR, REG_VAL
    output reg cfg_done        // Register configuration complete
);

//// Parameters and Internal Signals ////

// Parameter definitions
parameter REG_NUM = 10'd100;      // Total number of registers to configure
parameter CNT_WAIT_MAX = 20'd30000; // Wait count before register configuration

// Wire definitions
wire [23:0] cfg_data_reg[REG_NUM-1:0]; // Register configuration data buffer

// Register definitions
reg [14:0] cnt_wait;              // Register configuration wait counter
reg [9:0] reg_num;               // Number of configured registers

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

// System init
assign cfg_data_reg[0] = {24'h310311}; //Sys Clk From Pad
assign cfg_data_reg[1] = {24'h300842}; //Software Power down
assign cfg_data_reg[2] = {24'h300802}; //Software Power up
assign cfg_data_reg[3] = {24'h300882}; //Software Reset
assign cfg_data_reg[4] = {24'h300802}; //Release Reset
assign cfg_data_reg[5] = {24'h310303}; //Sys Clk From PLL

// PLL setup
assign cfg_data_reg[6] = {24'h30341A}; //[7:4] Charge Pump (always 0x1), [3:0] BIT Div (0x8 = 2, 0xA = 2.5)
assign cfg_data_reg[7] = {24'h303511}; //System Clocking[7:4] Sys Div, [3:0] MIPI Div (always 0x1)
assign cfg_data_reg[8] = {24'h30365E}; //PLL Multiplier
assign cfg_data_reg[9] = {24'h303712}; //[7:4] PLL Root Bypass or Div2, [3:0] PLL Pre Div
assign cfg_data_reg[10] = {24'h310800}; //[7:4] PCLK Div, [3:0] SCLK Div

// Clock control
assign cfg_data_reg[11] = {24'h300000}; //Reset for Individual Block (0: enable block; 1: reset block) Bit[7]: Reset BIST Bit[6]: Reset MCU program memory Bit[5]: Reset MCU  Bit[4]: Reset OTP Bit[3]: Reset STB  Bit[2]: Reset d5060 Bit[1]: Reset timing control Bit[0]: Reset array control
assign cfg_data_reg[12] = {24'h300100}; //Reset for Individual Block (0: enable block; 1: reset block) Bit[7]: Reset AWB registers Bit[6]: Reset AFC Bit[5]: Reset ISP Bit[4]: Reset FC Bit[3]: Reset S2P Bit[2]: Reset BLC Bit[1]: Reset AEC registers Bit[0]: Reset AEC
assign cfg_data_reg[13] = {24'h300200}; //Reset for Individual Block (0: enable block; 1: reset block) Bit[7]: Reset VFIFO Bit[5]: Reset format  Bit[4]: Reset JFIFO  Bit[3]: Reset SFIFO  Bit[2]: Reset JPG  Bit[1]: Reset format MUX Bit[0]: Reset average
assign cfg_data_reg[14] = {24'h300300}; //Reset for Individual Block (0: enable block; 1: reset block) Bit[7:6]: Debug mode Bit[5]: Reset digital gain compensation Bit[4]: Reset SYNC FIFO Bit[3]: Reset PSRAM Bit[2]: Reset ISP FC Bit[1]: Reset MIPI  Bit[0]: Reset DVP
assign cfg_data_reg[15] = {24'h3004ff}; //Clock Enable Control (0: disable clock; 1: enable clock) Bit[7]: Enable BIST clock Bit[6]: Enable MCU program memory  clock Bit[5]: Enable MCU clock Bit[4]: Enable OTP clock Bit[3]: Enable STROBE clock Bit[2]: Enable D5060 clock Bit[1]: Enable timing control clock Bit[0]: Enable array control clock
assign cfg_data_reg[16] = {24'h3005ff}; //Clock Enable Control (0: disable clock; 1: enable clock) Bit[7]: Enable AWB register clock Bit[6]: Enable AFC clock Bit[5]: Enable ISP clock Bit[4]: Enable FC clock Bit[3]: Enable S2P clock Bit[2]: Enable BLC clock Bit[1]: Enable AEC register clock Bit[0]: Enable AEC clock
assign cfg_data_reg[17] = {24'h3006ff}; //Clock Enable Control (0: disable clock; 1: enable clock) Bit[7]: Enable PSRAM clock Bit[6]: Enable FMT clock Bit[5]: Enable JPEG 2x clock Bit[3]: Enable JPEG clock Bit[1]: Enable format MUX clock Bit[0]: Enable average clock
assign cfg_data_reg[18] = {24'h3007ff}; //Clock Enable Control (0: disable clock; 1: enable clock) Bit[7]: Enable digital gain  compensation clock it[6]: Enable SYNC FIFO clock  Bit[5]: Enable ISPFC SCLK clock Bit[4]: Enable MIPI PCLK clock Bit[3]: Enable MIPI clock Bit[2]: Enable DVP PCLK clock Bit[1]: Enable VFIFO PCLK clock Bit[0]: Enable VFIFO SCLK clock

// I/O control
assign cfg_data_reg[19] = {24'h300e58}; //Enable DVP, power down MIPI
assign cfg_data_reg[20] = {24'h301600}; //Data bits as outputs
assign cfg_data_reg[21] = {24'h3017ff}; //Data bits as outputs
assign cfg_data_reg[22] = {24'h3018ff}; //Data bits as outputs

// Image and sensor dimensioning
assign cfg_data_reg[23] = {24'h380000}; //X START
assign cfg_data_reg[24] = {24'h380100}; //X START
assign cfg_data_reg[25] = {24'h380200}; //Y START
assign cfg_data_reg[26] = {24'h380300}; //Y START
assign cfg_data_reg[27] = {24'h38040A}; // X END
assign cfg_data_reg[28] = {24'h38053F}; // X END
assign cfg_data_reg[29] = {24'h380607}; // Y END
assign cfg_data_reg[30] = {24'h38079B}; // Y END
assign cfg_data_reg[31] = {24'h380802}; // Output image width
assign cfg_data_reg[32] = {24'h380980}; // Output image width
assign cfg_data_reg[33] = {24'h380a01}; // Output image height
assign cfg_data_reg[34] = {24'h380bE0}; // Output image height
assign cfg_data_reg[35] = {24'h380c07}; // HTS
assign cfg_data_reg[36] = {24'h380d68}; // HTS
assign cfg_data_reg[37] = {24'h380e03}; // VTS
assign cfg_data_reg[38] = {24'h380fD8}; // VTS
assign cfg_data_reg[39] = {24'h381000}; //ISP X OFFSET
assign cfg_data_reg[40] = {24'h381110}; //ISP X OFFSET
assign cfg_data_reg[41] = {24'h381200}; //ISP Y OFFSET
assign cfg_data_reg[42] = {24'h381306}; //ISP Y OFFSET
assign cfg_data_reg[43] = {24'h381431}; //Sample Increments
assign cfg_data_reg[44] = {24'h381531}; //Sample Increments
assign cfg_data_reg[45] = {24'h382041}; //ISP Control, Flip
assign cfg_data_reg[46] = {24'h382107}; //ISP Control, Mirror, Binning

// ISP control
assign cfg_data_reg[47] = {24'h500006}; //ISP Control [7] LENC, [5] GMA, [2] BPC, [1] WPC, [0] CIE
assign cfg_data_reg[48] = {24'h500120}; //ISP Control [7] SDE, [5] Scale, [2] UV, [1] CME, [0] AWB
assign cfg_data_reg[49] = {24'h50030C}; //Bit[7:3]: Debug mode Bit[2]: Bin enable 0: Disable 1: Enable Bit[1]: Draw window for AFC enable 0: Disable 1: Enable Bit[0]: Solarize enable 0: Disable 1: Enable
assign cfg_data_reg[50] = {24'h500500}; //Bit[7]: Debug mode Bit[6]: AWB bias manual enable 0: Disable 1: Enable Bit[5]: AWB bias ON enable 0: Disable 1: Enable Bit[4]: AWB bias plus enable 0: Disable 1: Enable Bit[3]: Debug mode Bit[2]: LENC bias ON enable 0: Disable 1: Enable Bit[1]: GMA bias ON enable 0: Disable 1: Enable Bit[0]: LENC bias manual enable 0: Disable 1: Enable
assign cfg_data_reg[51] = {24'h501D00}; //Bit[7]: Debug mode Bit[6]: SDE AVG manual enable Bit[5]: AWB YUV2CBCR enable Bit[4]: Average size manual enable Bit[3:0]: Debug mode 
assign cfg_data_reg[52] = {24'h501E40}; //Bit[7]: Debug mode Bit[6]: Scale ratio manual enable Bit[5:0]: Debug mode 

// Format control
assign cfg_data_reg[53] = {24'h430060}; //Format Control (blue 5, green 6, red 5)
assign cfg_data_reg[54] = {24'h501F01}; //Format MUX Control Bit[7:4]: Debug mode Bit[3]: Fmt vfirst Bit[2:0]: Format select 000: ISP YUV422 001: ISP RGB 010: ISP dither 011: ISP RAW (DPC) 100: SNR RAW 101: ISP RAW (CIP)

// Not documented necessary
assign cfg_data_reg[55] = {24'h363036}; //Not Documented
assign cfg_data_reg[56] = {24'h36310e}; //Not Documented
assign cfg_data_reg[57] = {24'h3632e2}; //Not Documented
assign cfg_data_reg[58] = {24'h363312}; //Not Documented
assign cfg_data_reg[59] = {24'h3621e0}; //Not Documented
assign cfg_data_reg[60] = {24'h3704a0}; //Not Documented
assign cfg_data_reg[61] = {24'h37035a}; //Not Documented
assign cfg_data_reg[62] = {24'h371578}; //Not Documented
assign cfg_data_reg[63] = {24'h371701}; //Not Documented
assign cfg_data_reg[64] = {24'h370b60}; //Not Documented
assign cfg_data_reg[65] = {24'h37051a}; //Not Documented
assign cfg_data_reg[66] = {24'h390502}; //Not Documented
assign cfg_data_reg[67] = {24'h390610}; //Not Documented
assign cfg_data_reg[68] = {24'h39010a}; //Not Documented
assign cfg_data_reg[69] = {24'h373112}; //Not Documented
assign cfg_data_reg[70] = {24'h302d60}; //Not documented
assign cfg_data_reg[71] = {24'h362052}; //Not documented
assign cfg_data_reg[72] = {24'h371b20}; //Not documented
assign cfg_data_reg[73] = {24'h471c50}; //Not documented
assign cfg_data_reg[74] = {24'h363513}; //Not documented
assign cfg_data_reg[75] = {24'h363603}; //Not documented
assign cfg_data_reg[76] = {24'h363440}; //Not documented
assign cfg_data_reg[77] = {24'h362201}; //Not documented
assign cfg_data_reg[78] = {24'h361800}; //Not documented
assign cfg_data_reg[79] = {24'h361229}; //Not documented
assign cfg_data_reg[80] = {24'h370864}; //Not documented
assign cfg_data_reg[81] = {24'h370952}; //Not documented
assign cfg_data_reg[82] = {24'h370c03}; //Not documented
assign cfg_data_reg[83] = {24'h302e00}; //Not documented
assign cfg_data_reg[84] = {24'h440e00}; //Not documented
assign cfg_data_reg[85] = {24'h502500}; //Not documented

// Motor VCM control
assign cfg_data_reg[86] = {24'h360008}; //VCM Debug mode
assign cfg_data_reg[87] = {24'h360133}; //VCM Debug mode

endmodule