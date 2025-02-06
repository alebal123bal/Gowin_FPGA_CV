module ov5640_cfg_better_indexed
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
parameter REG_NUM = 10'd500;      // Total number of registers to configure
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

assign cfg_data_reg[0] = {24'h310311}; //Sys Clk From PLL
assign cfg_data_reg[1] = {24'h300882}; //Release Reset
assign cfg_data_reg[2] = {24'h300802}; //Release Reset
assign cfg_data_reg[3] = {24'h310303}; //Sys Clk From PLL
assign cfg_data_reg[4] = {24'h3017ff}; //Data bits as outputs
assign cfg_data_reg[5] = {24'h3018ff}; //Data bits as outputs
assign cfg_data_reg[6] = {24'h30341a}; //[7:4] Charge Pump (always 1), [3:0] BIT Div (0x8 = 2, 0xA = 2.5)
assign cfg_data_reg[7] = {24'h303511}; //System Clocking[7:4] Sys Div, [3:0] MIPI Div (always 0x1)
assign cfg_data_reg[8] = {24'h303650}; //PLL Multiplier x105
assign cfg_data_reg[9] = {24'h303702}; //[7:4] PLL Root Bypass or Div2, [3:0] PLL Pre Div
assign cfg_data_reg[10] = {24'h310801}; //[7:4] PCLK Div, [3:0] SCLK Div
assign cfg_data_reg[11] = {24'h363036}; //Not Documented
assign cfg_data_reg[12] = {24'h36310e}; //Not Documented
assign cfg_data_reg[13] = {24'h3632e2}; //Not Documented
assign cfg_data_reg[14] = {24'h363312}; //Not Documented
assign cfg_data_reg[15] = {24'h3621e0}; //Not Documented
assign cfg_data_reg[16] = {24'h3704a0}; //Not Documented
assign cfg_data_reg[17] = {24'h37035a}; //Not Documented
assign cfg_data_reg[18] = {24'h371578}; //Not Documented
assign cfg_data_reg[19] = {24'h371701}; //Not Documented
assign cfg_data_reg[20] = {24'h370b60}; //Not Documented
assign cfg_data_reg[21] = {24'h37051a}; //Not Documented
assign cfg_data_reg[22] = {24'h390502}; //Not Documented
assign cfg_data_reg[23] = {24'h390610}; //Not Documented
assign cfg_data_reg[24] = {24'h39010a}; //Not Documented
assign cfg_data_reg[25] = {24'h373112}; //Not Documented
assign cfg_data_reg[26] = {24'h360008}; //VCM Debug mode
assign cfg_data_reg[27] = {24'h360133}; //VCM Debug mode
assign cfg_data_reg[28] = {24'h302d60}; //Not documented
assign cfg_data_reg[29] = {24'h362052}; //Not documented
assign cfg_data_reg[30] = {24'h371b20}; //Not documented
assign cfg_data_reg[31] = {24'h471c50}; //Not documented
assign cfg_data_reg[32] = {24'h3a1360}; //AEC Bit[7]: Debug mode Bit[6]: Pre-gain enable Bit[5:0]: Pre-gain value 0x40 = 1x
assign cfg_data_reg[33] = {24'h3a1800}; //AEC Gain Output Top Limit Bit[7:2]: Debug mode Bit[1:0]: AEC gain ceiling[9:8] Real gain format
assign cfg_data_reg[34] = {24'h3a19ff}; //AEC Gain Output Top Limit Bit[7:0]: AEC gain ceiling[7:0] Real gain format
assign cfg_data_reg[35] = {24'h363513}; //Not documented
assign cfg_data_reg[36] = {24'h363603}; //Not documented
assign cfg_data_reg[37] = {24'h363440}; //Not documented
assign cfg_data_reg[38] = {24'h362201}; //Not documented
 
assign cfg_data_reg[39] = {24'h3c0134};
assign cfg_data_reg[40] = {24'h3c0428}; //50/60 Hz Light Fix Bit[7:0]: Threshold for low sum
assign cfg_data_reg[41] = {24'h3c0598}; //50/60 Hz Light Fix Bit[7:0]: Threshold for high sum
assign cfg_data_reg[42] = {24'h3c0600}; //50/60 Hz Light Fix Bit[7:0]: Lightmeter1 threshold[15:8]
assign cfg_data_reg[43] = {24'h3c0708}; //50/60 Hz Light Fix Bit[7:0]: Lightmeter1 threshold[7:0]
assign cfg_data_reg[44] = {24'h3c0800}; //50/60 Hz Light Fix Bit[7:0]: Lightmeter2 threshold[15:8]
assign cfg_data_reg[45] = {24'h3c091c}; //50/60 Hz Light Fix Bit[7:0]: Lightmeter2 threshold[7:0]
assign cfg_data_reg[46] = {24'h3c0a9c}; //50/60 Hz Light Fix Bit[7:0]: Sample number[15:8]
assign cfg_data_reg[47] = {24'h3c0b40}; //50/60 Hz Light Fix Bit[7:0]: Sample number[7:0]
assign cfg_data_reg[48] = {24'h382041}; //ISP Control, Flip
assign cfg_data_reg[49] = {24'h382107}; //ISP Control, Mirror, Binning
assign cfg_data_reg[50] = {24'h381431}; //Sample Increments
assign cfg_data_reg[51] = {24'h381531}; //Sample Increments
assign cfg_data_reg[52] = {24'h380000}; //X START
assign cfg_data_reg[53] = {24'h380100}; //X START
assign cfg_data_reg[54] = {24'h380200}; //Y START
assign cfg_data_reg[55] = {24'h3803FA}; //Y START
assign cfg_data_reg[56] = {24'h38040A}; // X END
assign cfg_data_reg[57] = {24'h380540}; // X END
assign cfg_data_reg[58] = {24'h380606}; // Y END
assign cfg_data_reg[59] = {24'h3807A9}; // Y END
assign cfg_data_reg[60] = {24'h380805}; // Output image width
assign cfg_data_reg[61] = {24'h380900}; // Output image width
assign cfg_data_reg[62] = {24'h380a02}; // Output image height
assign cfg_data_reg[63] = {24'h380bD0}; // Output image height
assign cfg_data_reg[64] = {24'h380c0a}; // HTS
assign cfg_data_reg[65] = {24'h380d60}; // HTS
assign cfg_data_reg[66] = {24'h380e02}; // VTS
assign cfg_data_reg[67] = {24'h380fE4}; // VTS
assign cfg_data_reg[68] = {24'h381000}; //ISP X OFFSET
assign cfg_data_reg[69] = {24'h381110}; //ISP X OFFSET
assign cfg_data_reg[70] = {24'h381200}; //ISP Y OFFSET
assign cfg_data_reg[71] = {24'h381304}; //ISP Y OFFSET
assign cfg_data_reg[72] = {24'h361800}; //Not documented
assign cfg_data_reg[73] = {24'h361229}; //Not documented
assign cfg_data_reg[74] = {24'h370864}; //Not documented
assign cfg_data_reg[75] = {24'h370952}; //Not documented
assign cfg_data_reg[76] = {24'h370c03}; //Not documented
assign cfg_data_reg[77] = {24'h3a0203}; //AEC 60Hz Maximum Exposure Output Limit Bit[7:0]: Maximum exposure[15:8]
assign cfg_data_reg[78] = {24'h3a03d8}; //AEC 60Hz Maximum Exposure Output Limit Bit[7:0]: Maximum exposure[7:0]
assign cfg_data_reg[79] = {24'h3a0802}; //AEC 50Hz Band Width Bit[7:2]: Debug mode Bit[1:0]: B50 step[9:8]
assign cfg_data_reg[80] = {24'h3a0940}; //AEC 50Hz Band Width Bit[7:0]: B50 step[7:0]
assign cfg_data_reg[81] = {24'h3a0a01}; //AEC 60Hz Band Width Bit[7:2]: Debug mode Bit[1:0]: B60 step[13:8]
assign cfg_data_reg[82] = {24'h3a0bf6}; //AEC 60Hz Band Width Bit[7:0]: B60 step[7:0]
assign cfg_data_reg[83] = {24'h3a0e03}; //AEC 50Hz Max Bands in One Frame Bit[7:6]: Debug mode Bit[5:0]: B50 max
assign cfg_data_reg[84] = {24'h3a0d04}; //AEC 60Hz Max Bands in One Frame Bit[7:6]: Debug mode Bit[5:0]: B60 max
assign cfg_data_reg[85] = {24'h3a1403}; //AEC 50Hz Maximum Exposure Output Limit Bit[7:4]: Debug mode Bit[3:0]: Max exposure[15:8]
assign cfg_data_reg[86] = {24'h3a15d8}; //AEC 50Hz Maximum Exposure Output Limit Bit[7:0]: Max exposure[7:0]
 
assign cfg_data_reg[87] = {24'h400102}; //BLC Bit[7:6]: Debug mode Bit[5:0]: BLC start line
assign cfg_data_reg[88] = {24'h400402}; //BLC Bit[7:0]: BLC line number Specify the line number BLC process
assign cfg_data_reg[89] = {24'h300000}; //Reset for Individual Block (0: enable block; 1: reset block) Bit[7]: Reset BIST Bit[6]: Reset MCU program memory Bit[5]: Reset MCU  Bit[4]: Reset OTP Bit[3]: Reset STB  Bit[2]: Reset d5060 Bit[1]: Reset timing control Bit[0]: Reset array control
assign cfg_data_reg[90] = {24'h30021c}; //Reset for Individual Block (0: enable block; 1: reset block) Bit[7]: Reset VFIFO Bit[5]: Reset format  Bit[4]: Reset JFIFO  Bit[3]: Reset SFIFO  Bit[2]: Reset JPG  Bit[1]: Reset format MUX Bit[0]: Reset average
assign cfg_data_reg[91] = {24'h3004ff}; //Clock Enable Control (0: disable clock; 1: enable clock) Bit[7]: Enable BIST clock Bit[6]: Enable MCU program memory  clock Bit[5]: Enable MCU clock Bit[4]: Enable OTP clock Bit[3]: Enable STROBE clock Bit[2]: Enable D5060 clock Bit[1]: Enable timing control clock Bit[0]: Enable array control clock
assign cfg_data_reg[92] = {24'h3006c3}; //Clock Enable Control (0: disable clock; 1: enable clock) Bit[7]: Enable PSRAM clock Bit[6]: Enable FMT clock Bit[5]: Enable JPEG 2x clock Bit[3]: Enable JPEG clock Bit[1]: Enable format MUX clock Bit[0]: Enable average clock
assign cfg_data_reg[93] = {24'h300e58}; //Enable DVP, power down MIPI
assign cfg_data_reg[94] = {24'h302e00}; //Not documented
assign cfg_data_reg[95] = {24'h430060}; //Format Control
assign cfg_data_reg[96] = {24'h501f01}; //Format MUX Control Bit[7:4]: Debug mode Bit[3]: Fmt vfirst Bit[2:0]: Format select 000: ISP YUV422 001: ISP RGB 010: ISP dither 011: ISP RAW (DPC) 100: SNR RAW 101: ISP RAW (CIP)
assign cfg_data_reg[97] = {24'h471303}; //Bit[7:3]: Debug mode Bit[2:0]: JPEG mode select 001: JPEG mode 1 010: JPEG mode 2 011: JPEG mode 3 100: JPEG mode 4 101: JPEG mode 5 110: JPEG mode 6
assign cfg_data_reg[98] = {24'h440704}; //Bit[7]: Enable read QTA auto increment Bit[5:0]: QS Quantization scale
assign cfg_data_reg[99] = {24'h440e00}; //Not documented
assign cfg_data_reg[100] = {24'h460b35}; //VFIFO
assign cfg_data_reg[101] = {24'h460c22}; //VIFO [2] Control PCLK with register 0x3824
assign cfg_data_reg[102] = {24'h382402}; //DVP PCLK Divider (weird register)
assign cfg_data_reg[103] = {24'h5000a7}; //ISP Control [7] LENC, [5] GMA, [2] BLC, [1] WPC, [0] CIE
assign cfg_data_reg[104] = {24'h5001a3}; //ISP Control [7] SDE, [5] Scale, [2] UV, [1] CME, [0] AWB
assign cfg_data_reg[105] = {24'h5180ff};
assign cfg_data_reg[106] = {24'h5181f2};
assign cfg_data_reg[107] = {24'h518200};
assign cfg_data_reg[108] = {24'h518314};
assign cfg_data_reg[109] = {24'h518425};
assign cfg_data_reg[110] = {24'h518524};
assign cfg_data_reg[111] = {24'h518609};
assign cfg_data_reg[112] = {24'h518709};
assign cfg_data_reg[113] = {24'h518809};
assign cfg_data_reg[114] = {24'h518975};
assign cfg_data_reg[115] = {24'h518a54};
assign cfg_data_reg[116] = {24'h518be0};
assign cfg_data_reg[117] = {24'h518cb2};
assign cfg_data_reg[118] = {24'h518d42};
assign cfg_data_reg[119] = {24'h518e3d};
assign cfg_data_reg[120] = {24'h518f56};
assign cfg_data_reg[121] = {24'h519046};
assign cfg_data_reg[122] = {24'h5191f8};
assign cfg_data_reg[123] = {24'h519204};
assign cfg_data_reg[124] = {24'h519370};
assign cfg_data_reg[125] = {24'h5194f0};
assign cfg_data_reg[126] = {24'h5195f0};
assign cfg_data_reg[127] = {24'h519603};
assign cfg_data_reg[128] = {24'h519701};
assign cfg_data_reg[129] = {24'h519804};
assign cfg_data_reg[130] = {24'h519912};
assign cfg_data_reg[131] = {24'h519a04};
assign cfg_data_reg[132] = {24'h519b00};
assign cfg_data_reg[133] = {24'h519c06};
assign cfg_data_reg[134] = {24'h519d82};
 
assign cfg_data_reg[135] = {24'h519e38};
assign cfg_data_reg[136] = {24'h53811e};
assign cfg_data_reg[137] = {24'h53825b};
assign cfg_data_reg[138] = {24'h538308};
assign cfg_data_reg[139] = {24'h53840a};
assign cfg_data_reg[140] = {24'h53857e};
assign cfg_data_reg[141] = {24'h538688};
assign cfg_data_reg[142] = {24'h53877c};
assign cfg_data_reg[143] = {24'h53886c};
assign cfg_data_reg[144] = {24'h538910};
assign cfg_data_reg[145] = {24'h538a01};
assign cfg_data_reg[146] = {24'h538b98};
assign cfg_data_reg[147] = {24'h530008}; //Color Interpolation Sharpen MT Threshold 1
assign cfg_data_reg[148] = {24'h530130}; //CIP Sharpen MT Thresh2
assign cfg_data_reg[149] = {24'h530210}; //CIP Sharpen MT Offset1 (Y edge mt manual setting when 0x5308[6]=1)
assign cfg_data_reg[150] = {24'h530300}; //CIP Sharpen MT Offset2
assign cfg_data_reg[151] = {24'h530408}; //CIP DNS Thresh1
assign cfg_data_reg[152] = {24'h530530}; //CIP DNS Thresh2
assign cfg_data_reg[153] = {24'h530608}; //CIP DNS Offset1 (DNS threshold manual setting when 0x5308[4]=1)
assign cfg_data_reg[154] = {24'h530716}; //CIP DNS Offset2
assign cfg_data_reg[155] = {24'h530908}; //CIP Sharpen TH Thresh 1
assign cfg_data_reg[156] = {24'h530a30}; //CIP Sharpen TH Thresh 2
assign cfg_data_reg[157] = {24'h530b04}; //CIP Sharpen TH Offset 1 (Sharpen threshold manual setting when 0x5308[6]=1)
assign cfg_data_reg[158] = {24'h530c06}; //CIP Sharpen TH Offset 2
assign cfg_data_reg[159] = {24'h548001}; //Gamma Bit[7:2]: Debug mode Bit[1]: YSLP15 manual enable Bit[0]: BIAS plus on
assign cfg_data_reg[160] = {24'h548108}; //Gamma Bit[7:0]: Y yst 00
assign cfg_data_reg[161] = {24'h548214}; //Gamma Bit[7:0]: Y yst 01
assign cfg_data_reg[162] = {24'h548328}; //Gamma Bit[7:0]: Y yst 02
assign cfg_data_reg[163] = {24'h548451}; //Gamma Bit[7:0]: Y yst 03
assign cfg_data_reg[164] = {24'h548565}; //Gamma Bit[7:0]: Y yst 04
assign cfg_data_reg[165] = {24'h548671}; //Gamma Bit[7:0]: Y yst 05
assign cfg_data_reg[166] = {24'h54877d}; //Gamma Bit[7:0]: Y yst 06
assign cfg_data_reg[167] = {24'h548887}; //Gamma Bit[7:0]: Y yst 07
assign cfg_data_reg[168] = {24'h548991}; //Gamma Bit[7:0]: Y yst 08
assign cfg_data_reg[169] = {24'h548a9a}; //Gamma Bit[7:0]: Y yst 09
assign cfg_data_reg[170] = {24'h548baa}; //Gamma Bit[7:0]: Y yst 0A
assign cfg_data_reg[171] = {24'h548cb8}; //Gamma Bit[7:0]: Y yst 0B
assign cfg_data_reg[172] = {24'h548dcd}; //Gamma Bit[7:0]: Y yst 0C
assign cfg_data_reg[173] = {24'h548edd}; //Gamma Bit[7:0]: Y yst 0D
assign cfg_data_reg[174] = {24'h548fea}; //Gamma Bit[7:0]: Y yst 0E
assign cfg_data_reg[175] = {24'h54901d}; //Gamma Bit[7:0]: Y yst 0F
assign cfg_data_reg[176] = {24'h558002};
assign cfg_data_reg[177] = {24'h558340};
assign cfg_data_reg[178] = {24'h558410};
assign cfg_data_reg[179] = {24'h558910};
assign cfg_data_reg[180] = {24'h558a00};
assign cfg_data_reg[181] = {24'h558bf8};
assign cfg_data_reg[182] = {24'h580023}; //LENC
 
assign cfg_data_reg[183] = {24'h580114};
assign cfg_data_reg[184] = {24'h58020f};
assign cfg_data_reg[185] = {24'h58030f};
assign cfg_data_reg[186] = {24'h580412};
assign cfg_data_reg[187] = {24'h580526};
assign cfg_data_reg[188] = {24'h58060c};
assign cfg_data_reg[189] = {24'h580708};
assign cfg_data_reg[190] = {24'h580805};
assign cfg_data_reg[191] = {24'h580905};
assign cfg_data_reg[192] = {24'h580a08};
assign cfg_data_reg[193] = {24'h580b0d};
assign cfg_data_reg[194] = {24'h580c08};
assign cfg_data_reg[195] = {24'h580d03};
assign cfg_data_reg[196] = {24'h580e00};
assign cfg_data_reg[197] = {24'h580f00};
assign cfg_data_reg[198] = {24'h581003};
assign cfg_data_reg[199] = {24'h581109};
assign cfg_data_reg[200] = {24'h581207};
assign cfg_data_reg[201] = {24'h581303};
assign cfg_data_reg[202] = {24'h581400};
assign cfg_data_reg[203] = {24'h581501};
assign cfg_data_reg[204] = {24'h581603};
assign cfg_data_reg[205] = {24'h581708};
assign cfg_data_reg[206] = {24'h58180d};
assign cfg_data_reg[207] = {24'h581908};
assign cfg_data_reg[208] = {24'h581a05};
assign cfg_data_reg[209] = {24'h581b06};
assign cfg_data_reg[210] = {24'h581c08};
assign cfg_data_reg[211] = {24'h581d0e};
assign cfg_data_reg[212] = {24'h581e29};
assign cfg_data_reg[213] = {24'h581f17};
assign cfg_data_reg[214] = {24'h582011};
assign cfg_data_reg[215] = {24'h582111};
assign cfg_data_reg[216] = {24'h582215};
assign cfg_data_reg[217] = {24'h582328};
assign cfg_data_reg[218] = {24'h582446};
assign cfg_data_reg[219] = {24'h582526};
assign cfg_data_reg[220] = {24'h582608};
assign cfg_data_reg[221] = {24'h582726};
assign cfg_data_reg[222] = {24'h582864};
assign cfg_data_reg[223] = {24'h582926};
assign cfg_data_reg[224] = {24'h582a24};
assign cfg_data_reg[225] = {24'h582b22};
assign cfg_data_reg[226] = {24'h582c24};
assign cfg_data_reg[227] = {24'h582d24};
assign cfg_data_reg[228] = {24'h582e06};
assign cfg_data_reg[229] = {24'h582f22};
assign cfg_data_reg[230] = {24'h583040};
 
assign cfg_data_reg[231] = {24'h583142};
assign cfg_data_reg[232] = {24'h583224};
assign cfg_data_reg[233] = {24'h583326};
assign cfg_data_reg[234] = {24'h583424};
assign cfg_data_reg[235] = {24'h583522};
assign cfg_data_reg[236] = {24'h583622};
assign cfg_data_reg[237] = {24'h583726};
assign cfg_data_reg[238] = {24'h583844};
assign cfg_data_reg[239] = {24'h583924};
assign cfg_data_reg[240] = {24'h583a26};
assign cfg_data_reg[241] = {24'h583b28};
assign cfg_data_reg[242] = {24'h583c42};
assign cfg_data_reg[243] = {24'h583dce};
assign cfg_data_reg[244] = {24'h502500}; //Not documented
assign cfg_data_reg[245] = {24'h3a0f30}; //AEC Stable Range High Limit (enter) Bit[7:0]: WPT
assign cfg_data_reg[246] = {24'h3a1028}; //AEC Stable Range Low Limit (enter) Bit[7:0]: BPT
assign cfg_data_reg[247] = {24'h3a1b30}; //AEC Stable Range High Limit (go out) Bit[7:0]: WPT2
assign cfg_data_reg[248] = {24'h3a1e26}; //AEC Stable Range Low Limit (go out) Bit[7:0]: BPT2
assign cfg_data_reg[249] = {24'h3a1160}; //AEC Step Manual Mode, Fast Zone High Limit Bit[7:0]: vpt_high
assign cfg_data_reg[250] = {24'h3a1f14}; //AEC Step Manual Mode, Fast Zone Low Limit Bit[7:0]: vpt_low
assign cfg_data_reg[251] = {24'h300802}; //Release Reset
assign cfg_data_reg[252] = {24'h303521}; //System Clocking[7:4] Sys Div, [3:0] MIPI Div (always 0x1)
 
assign cfg_data_reg[253] = {24'h3c01b4}; //Bit[7]: Band manual enable Bit[6]: Band begin reset enable Bit[5]: Sum auto mode enable Bit[4]: Band counter enable Bit[3:0]: Band counter Counter threshold for band change
assign cfg_data_reg[254] = {24'h3c0004}; //Bit[2]: Band value manual setting 0: 60 Hz light 1: 50 Hz light
 
assign cfg_data_reg[255] = {24'h3a197c};
 
assign cfg_data_reg[256] = {24'h58002c}; //LENC Bit[7:6]: Debug mode Bit[5:0]: Green matrix 00
assign cfg_data_reg[257] = {24'h580117}; //LENC Bit[7:6]: Debug mode Bit[5:0]: Green matrix 01
assign cfg_data_reg[258] = {24'h580211}; //LENC Bit[7:6]: Debug mode Bit[5:0]: Green matrix 02
assign cfg_data_reg[259] = {24'h580311}; //LENC Bit[7:6]: Debug mode Bit[5:0]: Green matrix 03
assign cfg_data_reg[260] = {24'h580415}; //LENC Bit[7:6]: Debug mode Bit[5:0]: Green matrix 04
assign cfg_data_reg[261] = {24'h580529}; //LENC Bit[7:6]: Debug mode Bit[5:0]: Green matrix 05
assign cfg_data_reg[262] = {24'h580608}; //LENC Bit[7:6]: Debug mode Bit[5:0]: Green matrix 06
assign cfg_data_reg[263] = {24'h580706}; //LENC Bit[7:6]: Debug mode Bit[5:0]: Green matrix 07
assign cfg_data_reg[264] = {24'h580804}; //LENC Bit[7:6]: Debug mode Bit[5:0]: Green matrix 08
assign cfg_data_reg[265] = {24'h580904}; //LENC Bit[7:6]: Debug mode Bit[5:0]: Green matrix 09
assign cfg_data_reg[266] = {24'h580a05}; //LENC Bit[7:6]: Debug mode Bit[5:0]: Green matrix 0A
assign cfg_data_reg[267] = {24'h580b07}; //LENC Bit[7:6]: Debug mode Bit[5:0]: Green matrix 0B
assign cfg_data_reg[268] = {24'h580c06}; //LENC Bit[7:6]: Debug mode Bit[5:0]: Green matrix 0C
assign cfg_data_reg[269] = {24'h580d03}; //LENC Bit[7:6]: Debug mode Bit[5:0]: Green matrix 0D
assign cfg_data_reg[270] = {24'h580e01}; //LENC Bit[7:6]: Debug mode Bit[5:0]: Green matrix 0E
assign cfg_data_reg[271] = {24'h580f01}; //LENC Bit[7:6]: Debug mode Bit[5:0]: Green matrix 0F
assign cfg_data_reg[272] = {24'h581003}; //LENC Bit[7:6]: Debug mode Bit[5:0]: Green matrix 10
assign cfg_data_reg[273] = {24'h581106}; //LENC Bit[7:6]: Debug mode Bit[5:0]: Green matrix 11
 
assign cfg_data_reg[274] = {24'h581206}; //LENC Bit[7:6]: Debug mode Bit[5:0]: Green matrix 12
assign cfg_data_reg[275] = {24'h581302}; //LENC Bit[7:6]: Debug mode Bit[5:0]: Green matrix 13
assign cfg_data_reg[276] = {24'h581401}; //LENC Bit[7:6]: Debug mode Bit[5:0]: Green matrix 14
assign cfg_data_reg[277] = {24'h581501}; //LENC Bit[7:6]: Debug mode Bit[5:0]: Green matrix 15
assign cfg_data_reg[278] = {24'h581604}; //LENC Bit[7:6]: Debug mode Bit[5:0]: Green matrix 16
assign cfg_data_reg[279] = {24'h581707}; //LENC Bit[7:6]: Debug mode Bit[5:0]: Green matrix 17
assign cfg_data_reg[280] = {24'h581806}; //LENC Bit[7:6]: Debug mode Bit[5:0]: Green matrix 18
assign cfg_data_reg[281] = {24'h581907}; //LENC Bit[7:6]: Debug mode Bit[5:0]: Green matrix 19
assign cfg_data_reg[282] = {24'h581a06}; //LENC Bit[7:6]: Debug mode Bit[5:0]: Green matrix 1A
assign cfg_data_reg[283] = {24'h581b06}; //LENC Bit[7:6]: Debug mode Bit[5:0]: Green matrix 1B
assign cfg_data_reg[284] = {24'h581c06}; //LENC Bit[7:6]: Debug mode Bit[5:0]: Green matrix 1C
assign cfg_data_reg[285] = {24'h581d0e}; //LENC Bit[7:6]: Debug mode Bit[5:0]: Green matrix 1D
assign cfg_data_reg[286] = {24'h581e31}; //LENC Bit[7:6]: Debug mode Bit[5:0]: Green matrix 1E
assign cfg_data_reg[287] = {24'h581f12}; //LENC Bit[7:6]: Debug mode Bit[5:0]: Green matrix 1F
assign cfg_data_reg[288] = {24'h582011}; //LENC Bit[7:6]: Debug mode Bit[5:0]: Green matrix 20
assign cfg_data_reg[289] = {24'h582111}; //LENC Bit[7:6]: Debug mode Bit[5:0]: Green matrix 21
assign cfg_data_reg[290] = {24'h582211}; //LENC Bit[7:6]: Debug mode Bit[5:0]: Green matrix 22
assign cfg_data_reg[291] = {24'h58232f}; //LENC Bit[7:6]: Debug mode Bit[5:0]: Green matrix 23
assign cfg_data_reg[292] = {24'h582412}; //LENC Bit[7:4]: Blue matrix 00 Bit[3:0]: Red matrix 00
assign cfg_data_reg[293] = {24'h582525}; //LENC Bit[7:4]: Blue matrix 01 Bit[3:0]: Red matrix 01
assign cfg_data_reg[294] = {24'h582639}; //LENC Bit[7:4]: Blue matrix 02 Bit[3:0]: Red matrix 02
assign cfg_data_reg[295] = {24'h582729}; //LENC Bit[7:4]: Blue matrix 03 Bit[3:0]: Red matrix 03
assign cfg_data_reg[296] = {24'h582827}; //LENC Bit[7:4]: Blue matrix 04 Bit[3:0]: Red matrix 04
assign cfg_data_reg[297] = {24'h582939}; //LENC Bit[7:4]: Blue matrix 05 Bit[3:0]: Red matrix 05
assign cfg_data_reg[298] = {24'h582a26}; //LENC Bit[7:4]: Blue matrix 06 Bit[3:0]: Red matrix 06
assign cfg_data_reg[299] = {24'h582b33}; //LENC Bit[7:4]: Blue matrix 07 Bit[3:0]: Red matrix 07
assign cfg_data_reg[300] = {24'h582c24}; //LENC Bit[7:4]: Blue matrix 08 Bit[3:0]: Red matrix 08
assign cfg_data_reg[301] = {24'h582d39}; //LENC Bit[7:4]: Blue matrix 09 Bit[3:0]: Red matrix 09
assign cfg_data_reg[302] = {24'h582e28}; //LENC Bit[7:4]: Blue matrix 20 Bit[3:0]: Red matrix 20
assign cfg_data_reg[303] = {24'h582f21}; //LENC Bit[7:4]: Blue matrix 21 Bit[3:0]: Red matrix 21
assign cfg_data_reg[304] = {24'h583040}; //LENC Bit[7:4]: Blue matrix 22 Bit[3:0]: Red matrix 22
assign cfg_data_reg[305] = {24'h583121}; //LENC Bit[7:4]: Blue matrix 23 Bit[3:0]: Red matrix 23
assign cfg_data_reg[306] = {24'h583217}; //LENC Bit[7:4]: Blue matrix 24 Bit[3:0]: Red matrix 24
assign cfg_data_reg[307] = {24'h583317}; //LENC Bit[7:4]: Blue matrix 30 Bit[3:0]: Red matrix 30
assign cfg_data_reg[308] = {24'h583415}; //LENC Bit[7:4]: Blue matrix 31 Bit[3:0]: Red matrix 31
assign cfg_data_reg[309] = {24'h583511}; //LENC Bit[7:4]: Blue matrix 32 Bit[3:0]: Red matrix 32
assign cfg_data_reg[310] = {24'h583624}; //LENC Bit[7:4]: Blue matrix 33 Bit[3:0]: Red matrix 33
assign cfg_data_reg[311] = {24'h583727}; //LENC Bit[7:4]: Blue matrix 34 Bit[3:0]: Red matrix 34
assign cfg_data_reg[312] = {24'h583826}; //LENC Bit[7:4]: Blue matrix 40 Bit[3:0]: Red matrix 40
assign cfg_data_reg[313] = {24'h583926}; //LENC Bit[7:4]: Blue matrix 41 Bit[3:0]: Red matrix 41
assign cfg_data_reg[314] = {24'h583a26}; //LENC Bit[7:4]: Blue matrix 42 Bit[3:0]: Red matrix 42
assign cfg_data_reg[315] = {24'h583b28}; //LENC Bit[7:4]: Blue matrix 43 Bit[3:0]: Red matrix 43
assign cfg_data_reg[316] = {24'h583c14}; //LENC Bit[7:4]: Blue matrix 44 Bit[3:0]: Red matrix 44
assign cfg_data_reg[317] = {24'h583dee}; //LENC Bit[7:4]: LENC b offset Bit[3:0]: LENC r offset
assign cfg_data_reg[318] = {24'h40051a}; //Bit[1]: BLC always update 0: Normal freeze 1: BLC always update; 
 
assign cfg_data_reg[319] = {24'h538126}; //Bit[7:2]: Debug mode Bit[1]: CMX1 for Y Bit[0]: Debug mode
assign cfg_data_reg[320] = {24'h538250}; //Bit[7:0]: CMX2 for Y
assign cfg_data_reg[321] = {24'h53830c}; //Bit[7:0]: CMX3 for Y
assign cfg_data_reg[322] = {24'h538409}; //Bit[7:0]: CMX4 for U
assign cfg_data_reg[323] = {24'h538574}; //Bit[7:0]: CMX5 for U
assign cfg_data_reg[324] = {24'h53867d}; //Bit[7:0]: CMX6 for U
assign cfg_data_reg[325] = {24'h53877e}; //Bit[7:0]: CMX7 for V
assign cfg_data_reg[326] = {24'h538875}; //Bit[7:0]: CMX8 for V
assign cfg_data_reg[327] = {24'h538909}; //Bit[7:0]: CMX9 for V
assign cfg_data_reg[328] = {24'h538b98}; //Cmxsign Bit[7]: CMX8 sign Bit[6]: CMX7 sign Bit[5]: CMX6 sign Bit[4]: CMX5 sign Bit[3]: CMX4 sign Bit[2]: CMX3 sign Bit[1]: CMX2 sign Bit[0]: CMX1 sign
assign cfg_data_reg[329] = {24'h538a01}; //Cmxsign Bit[7:1]: Debug mode Bit[0]: CMX9 sign
 
assign cfg_data_reg[330] = {24'h558002}; //Digital Effects Bit[7]: Fixed Y enable 0: Disable 1: Enable Bit[6]: Negative enable 0: Disable 1: Enable Bit[5]: Gray enable 0: Disable 1: Enable Bit[4]: Fixed V enable 0: Disable 1: Enable Bit[3]: Fixed U enable 0: Disable 1: Enable Bit[2]: Contrast enable 0: Disable 1: Enable Bit[1]: Saturation enable 0: Disable 1: Enable Bit[0]: Hue enable 0: Disable 1: Enable
assign cfg_data_reg[331] = {24'h558801}; //Digital Effects Bit[7]: Debug mode Bit[5]: Sign5 for hue V, cos Bit[4]: Sign4 for hue U, cos Bit[3]: Sign3 Y bright sign for contrast 0: Keep Y bright sign 1: Negative Y bright sign Bit[2]: Sign2 Y offset sign for contrast when  0x5044[3]=1 0: Keep Y offset sign 1: Negative Y offset sign Bit[1]: Sign1 for hue V, sin Bit[0]: Sign0 for hue U, sin
assign cfg_data_reg[332] = {24'h558340}; //Digital Effects Saturation U when 0x5580[1]=1 and 0x5588[6]=1, max value for UV adjust when 0x5580[1]=1 and 0x5588[6]=0 or fixed U when 0x5580[3]=1
assign cfg_data_reg[333] = {24'h558410}; //Digital Effects Saturation V when 0x5580[1]=1 and 0x5588[6]=1, min value for UV adjust when 0x5580[1]=1 and 0x5588[6]=0 or Vreg when 0x5580[4]=1
assign cfg_data_reg[334] = {24'h55890f}; //Digital Effects Bit[7:0]: UV adjust threshold 1 Valid when 0x5580[1]=1
assign cfg_data_reg[335] = {24'h558a00}; //Digital Effects Bit[7:1]: Debug mode Bit[0]: UV adjust threshold 2[8] Valid when 0x5580[1]=1
assign cfg_data_reg[336] = {24'h558b3f}; //Digital Effects Bit[7:0]: UV adjust threshold 2[7:0] Valid when 0x5580[1]=1
 
assign cfg_data_reg[337] = {24'h530825}; //CIP CTRL Bit[7]: Debug mode Bit[6]: CIP edge MT manual enable Bit[4]: CIP DNS manual enable Bit[2:0]: CIP threshold for BR sharpen
assign cfg_data_reg[338] = {24'h530408}; //CIP DNS Thresh1
assign cfg_data_reg[339] = {24'h530530}; //CIP DNS Thresh2
assign cfg_data_reg[340] = {24'h530610}; //CIP DNS Offset1
assign cfg_data_reg[341] = {24'h530720}; //CIP DNS Offset2
 
assign cfg_data_reg[342] = {24'h5180ff}; //AWB B Block
assign cfg_data_reg[343] = {24'h5181f2}; //Bit[7:6]: Step local Bit[5:4]: Step fast Bit[3]: Slop 8x Bit[2]: Slop 4x Bit[1]: One zone Bit[0]: AVG all
assign cfg_data_reg[344] = {24'h518211}; //Bit[7:4]: Max local counter Bit[3:0]: Max fast counter
assign cfg_data_reg[345] = {24'h518314}; //Bit[7]: AWB simple enable 0: AWB advance 1: AWB simple Bit[6]: AWB advance 0: YUV enable 1: Simple YUV enable Bit[5]: AWB preset Bit[4]: AWB SIMF Bit[3:2]: AWB win Bit[0]: Debug mode
assign cfg_data_reg[346] = {24'h518425}; //Bit[7:6]: Count area selection Bit[5]: G enable Bit[4:2]: Count limit control Bit[1:0]: Counter threshold
assign cfg_data_reg[347] = {24'h518524}; //Bit[7:4]: Stable range unstable Threshold for unstable to stable change Bit[3:0]: Stable range stable Threshold for stable to unstable change
assign cfg_data_reg[348] = {24'h518610}; //Advanced AWB Control Registers
assign cfg_data_reg[349] = {24'h518712}; //Advanced AWB Control Registers
assign cfg_data_reg[350] = {24'h518810}; //Advanced AWB Control Registers
assign cfg_data_reg[351] = {24'h518980}; //Advanced AWB Control Registers
assign cfg_data_reg[352] = {24'h518a54}; //Advanced AWB Control Registers
assign cfg_data_reg[353] = {24'h518bb8}; //Advanced AWB Control Registers
assign cfg_data_reg[354] = {24'h518cb2}; //Advanced AWB Control Registers
assign cfg_data_reg[355] = {24'h518d42}; //Advanced AWB Control Registers
assign cfg_data_reg[356] = {24'h518e3a}; //Advanced AWB Control Registers
assign cfg_data_reg[357] = {24'h518f56}; //Advanced AWB Control Registers
assign cfg_data_reg[358] = {24'h519046}; //Advanced AWB Control Registers
assign cfg_data_reg[359] = {24'h5191f0}; //AWB top limit
assign cfg_data_reg[360] = {24'h51920f}; //AWB bottomm limit
assign cfg_data_reg[361] = {24'h519370}; //Bit[7:0]: Red limit
assign cfg_data_reg[362] = {24'h5194f0}; //Bit[7:0]: Green limit
assign cfg_data_reg[363] = {24'h5195f0}; //Bit[7:0]: Blue limit
assign cfg_data_reg[364] = {24'h519603}; //Bit[7:6]: Debug mode Bit[5]: AWB freeze Bit[4]: Debug mode Bit[3:2]: AWB simple selection 00: AWB simple from after AWB gain 01: AWB simple from after RAW GMA 10: AWB simple from after RAW GMA 11: AWB simple from after AWB gain Bit[1]: Fast enable Bit[0]: AWB bias stat
assign cfg_data_reg[365] = {24'h519701}; //Bit[7:0]: Local limit
assign cfg_data_reg[366] = {24'h519806}; //Debug Mode
assign cfg_data_reg[367] = {24'h519962}; //Debug Mode
assign cfg_data_reg[368] = {24'h519a04}; //Debug Mode
assign cfg_data_reg[369] = {24'h519b00}; //Debug Mode
assign cfg_data_reg[370] = {24'h519c04}; //Debug Mode
assign cfg_data_reg[371] = {24'h519de7}; //Debug Mode
assign cfg_data_reg[372] = {24'h519e38}; //Bit[7:4]: Debug mode Bit[3]: Local limit select Bit[2]: Simple stable select Bit[1:0]: Debug mode

endmodule