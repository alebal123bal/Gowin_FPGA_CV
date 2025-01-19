module ov5640_cfg_worse
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
parameter REG_NUM = 10'd218;      // Total number of registers to configure
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
assign cfg_data_reg[000] = {24'h300882}; //Software Reset
assign cfg_data_reg[001] = {24'h300842}; //Chip Power Down
assign cfg_data_reg[002] = {24'h310303}; //Sys Clk From PLL
assign cfg_data_reg[003] = {24'h3017ff}; //Data bits as outputs
assign cfg_data_reg[004] = {24'h3018ff}; //Data bits as outputs
assign cfg_data_reg[005] = {24'h350300}; //AEC/AGC on
assign cfg_data_reg[006] = {24'h000000};
assign cfg_data_reg[007] = {24'h000000};
// assign cfg_data_reg[006] = {24'h350bc4}; //Gain Lower
// assign cfg_data_reg[007] = {24'h350a03}; //Gain Upper
assign cfg_data_reg[008] = {24'h30341A}; //[7:4] Charge Pump (always 1), [3:0] BIT Div (0x8 = 2, 0xA = 2.5)
assign cfg_data_reg[009] = {24'h303521}; //System Clocking[7:4] Sys Div, [3:0] MIPI Div (always 0x1)
assign cfg_data_reg[010] = {24'h303669}; //PLL Multiplier
assign cfg_data_reg[011] = {24'h303703}; //[7:4] PLL Root Bypass or Div2, [3:0] PLL Pre Div
assign cfg_data_reg[012] = {24'h310801}; //[7:4] PCLK Div, [3:0] SCLK Div
assign cfg_data_reg[013] = {24'h363036}; //Not Documented
assign cfg_data_reg[014] = {24'h36310e}; //Not Documented
assign cfg_data_reg[015] = {24'h3632e2}; //Not Documented
assign cfg_data_reg[016] = {24'h363312}; //Not Documented
assign cfg_data_reg[017] = {24'h3621e0}; //Not Documented
assign cfg_data_reg[018] = {24'h3704a0}; //Not Documented
assign cfg_data_reg[019] = {24'h37035a}; //Not Documented
assign cfg_data_reg[020] = {24'h371578}; //Not Documented
assign cfg_data_reg[021] = {24'h371701}; //Not Documented
assign cfg_data_reg[022] = {24'h370b60}; //Not Documented
assign cfg_data_reg[023] = {24'h37051a}; //Not Documented
assign cfg_data_reg[024] = {24'h390502}; //Not Documented
assign cfg_data_reg[025] = {24'h390610}; //Not Documented
assign cfg_data_reg[026] = {24'h39010a}; //Not Documented
assign cfg_data_reg[027] = {24'h373112}; //Not Documented
assign cfg_data_reg[028] = {24'h360008}; //VCM
assign cfg_data_reg[029] = {24'h360133}; //VCM
assign cfg_data_reg[030] = {24'h302d60}; //Not documented
assign cfg_data_reg[031] = {24'h362052}; //Not documented
assign cfg_data_reg[032] = {24'h371b20}; //Not documented
assign cfg_data_reg[033] = {24'h471c50}; //Not documented
assign cfg_data_reg[034] = {24'h3a1343}; //AEC These sure make the screen dark!
assign cfg_data_reg[035] = {24'h3a1800}; //AEC These sure make the screen dark!
assign cfg_data_reg[036] = {24'h3a19f8}; //AEC These sure make the screen dark!
assign cfg_data_reg[037] = {24'h363513}; //Not documented
assign cfg_data_reg[038] = {24'h363603}; //Not documented
assign cfg_data_reg[039] = {24'h363440}; //Not documented
assign cfg_data_reg[040] = {24'h362201}; //Not documented
assign cfg_data_reg[041] = {24'h3c0134}; //50/60 Hz Light Fix
assign cfg_data_reg[042] = {24'h3c0428}; //50/60 Hz Light Fix
assign cfg_data_reg[043] = {24'h3c0598}; //50/60 Hz Light Fix
assign cfg_data_reg[044] = {24'h3c0600}; //50/60 Hz Light Fix
assign cfg_data_reg[045] = {24'h3c0707}; //50/60 Hz Light Fix
assign cfg_data_reg[046] = {24'h3c0800}; //50/60 Hz Light Fix
assign cfg_data_reg[047] = {24'h3c091c}; //50/60 Hz Light Fix
assign cfg_data_reg[048] = {24'h3c0a9c}; //50/60 Hz Light Fix
assign cfg_data_reg[049] = {24'h3c0b40}; //50/60 Hz Light Fix
assign cfg_data_reg[050] = {24'h382047}; //ISP Control, Flip
assign cfg_data_reg[051] = {24'h382101}; //ISP Control, Mirror, No binning
assign cfg_data_reg[052] = {24'h381431}; //Sample Increments
assign cfg_data_reg[053] = {24'h381531}; //Sample Increments
assign cfg_data_reg[054] = {24'h380000}; //X START
assign cfg_data_reg[055] = {24'h380100}; //X START
assign cfg_data_reg[056] = {24'h380200}; //Y START
assign cfg_data_reg[057] = {24'h380300}; //Y START
assign cfg_data_reg[058] = {24'h38040a}; //X END
assign cfg_data_reg[059] = {24'h38053f}; //X END
assign cfg_data_reg[060] = {24'h380607}; //Y END
assign cfg_data_reg[061] = {24'h38079f}; //Y END
assign cfg_data_reg[062] = {24'h380805}; //DVPHO = 1280
assign cfg_data_reg[063] = {24'h380900}; //DVPHO = 1280
assign cfg_data_reg[064] = {24'h380a02}; //DVPVO = 720
assign cfg_data_reg[065] = {24'h380bD0}; //DVPVO = 720
assign cfg_data_reg[066] = {24'h380c07}; //HTS
assign cfg_data_reg[067] = {24'h380d68}; //HTS
assign cfg_data_reg[068] = {24'h380e03}; //VTS
assign cfg_data_reg[069] = {24'h380fd8}; //VTS
assign cfg_data_reg[070] = {24'h381000}; //ISP X OFFSET
assign cfg_data_reg[071] = {24'h381110}; //ISP X OFFSET
assign cfg_data_reg[072] = {24'h381200}; //ISP Y OFFSET
assign cfg_data_reg[073] = {24'h381304}; //ISP Y OFFSET
assign cfg_data_reg[074] = {24'h361800}; //Not documented
assign cfg_data_reg[075] = {24'h361229}; //Not documented
assign cfg_data_reg[076] = {24'h370864}; //Not documented
assign cfg_data_reg[077] = {24'h370952}; //Not documented
assign cfg_data_reg[078] = {24'h370c03}; //Not documented
assign cfg_data_reg[079] = {24'h3a0202}; //AEC
assign cfg_data_reg[080] = {24'h3a03e0}; //AEC
assign cfg_data_reg[081] = {24'h3a0800}; //AEC
assign cfg_data_reg[082] = {24'h3a096f}; //AEC
assign cfg_data_reg[083] = {24'h3a0a00}; //AEC
assign cfg_data_reg[084] = {24'h3a0b5c}; //AEC
assign cfg_data_reg[085] = {24'h3a0e06}; //AEC
assign cfg_data_reg[086] = {24'h3a0d08}; //AEC
assign cfg_data_reg[087] = {24'h3a1402}; //AEC
assign cfg_data_reg[088] = {24'h3a15e0}; //AEC
assign cfg_data_reg[089] = {24'h400102}; //BLC
assign cfg_data_reg[090] = {24'h400402}; //BLC
assign cfg_data_reg[091] = {24'h300000}; //Functional Enables
assign cfg_data_reg[092] = {24'h300100}; //Functional Enables
assign cfg_data_reg[093] = {24'h30021c}; //Functional Enables
assign cfg_data_reg[094] = {24'h3004ff}; //Clock Enables
assign cfg_data_reg[095] = {24'h3005ff}; //Clock Enables
assign cfg_data_reg[096] = {24'h3006c3}; //Clock Enables
assign cfg_data_reg[097] = {24'h3007ff}; //Clock Enables
assign cfg_data_reg[098] = {24'h300e58}; //Enable DVP, power down MIPI
assign cfg_data_reg[099] = {24'h302e00}; //Not documented
// assign cfg_data_reg[100] = {24'h474021}; //Active High PCLK and active high HREF
assign cfg_data_reg[100] = {24'h000000}; //Active High PCLK and active high HREF
assign cfg_data_reg[101] = {24'h460b37}; //VFIFO
assign cfg_data_reg[102] = {24'h460c20}; //VIFO [2] Control PCLK with register 0x3824
assign cfg_data_reg[103] = {24'h382401}; //DVP PCLK Divider (weird register)
assign cfg_data_reg[104] = {24'h430060}; //Format Control (select RAW RG GB = 0x03)
assign cfg_data_reg[105] = {24'h5001a3}; //ISP Control [7] SDE, [5] Scale, [2] UV, [1] CME, [0] AWB
assign cfg_data_reg[106] = {24'h501f01}; //Format Mux Control (0x05 = ISP RAW CIP)
assign cfg_data_reg[107] = {24'h5000a7}; //ISP Control [7] LENC, [5] GMA, [2] BLC, [1] WPC, [0] CIE
assign cfg_data_reg[108] = {24'h340600}; //Simple AWB
assign cfg_data_reg[109] = {24'h518314}; //Simple AWB
assign cfg_data_reg[110] = {24'h5191f8}; //Simple AWB
assign cfg_data_reg[111] = {24'h519204}; //Simple AWB
assign cfg_data_reg[112] = {24'h530130}; //CIP Sharpen MT Thresh2
assign cfg_data_reg[113] = {24'h530210}; //CIP Sharpen MT Offset1
assign cfg_data_reg[114] = {24'h530300}; //CIP Sharpen MT Offset2
assign cfg_data_reg[115] = {24'h530408}; //CIP DNS Thresh1
assign cfg_data_reg[116] = {24'h530530}; //CIP DNS Thresh2
assign cfg_data_reg[117] = {24'h530608}; //CIP DNS Offset1
assign cfg_data_reg[118] = {24'h530716}; //CIP DNS Offset2
assign cfg_data_reg[119] = {24'h530825}; //CIP CTRL
assign cfg_data_reg[120] = {24'h530908}; //CIP Sharpen TH Thresh 1
assign cfg_data_reg[121] = {24'h530a30}; //CIP Sharpen TH Thresh 2
assign cfg_data_reg[122] = {24'h530b04}; //CIP Sharpen TH Offset 1
assign cfg_data_reg[123] = {24'h530c06}; //CIP Sharpen TH Offset 2
assign cfg_data_reg[124] = {24'h548001}; //Gamma
assign cfg_data_reg[125] = {24'h548108}; //Gamma
assign cfg_data_reg[126] = {24'h548214}; //Gamma
assign cfg_data_reg[127] = {24'h548328}; //Gamma
assign cfg_data_reg[128] = {24'h548451}; //Gamma
assign cfg_data_reg[129] = {24'h548565}; //Gamma
assign cfg_data_reg[130] = {24'h548671}; //Gamma
assign cfg_data_reg[131] = {24'h54877d}; //Gamma
assign cfg_data_reg[132] = {24'h548887}; //Gamma
assign cfg_data_reg[133] = {24'h548991}; //Gamma
assign cfg_data_reg[134] = {24'h548a9a}; //Gamma
assign cfg_data_reg[135] = {24'h548baa}; //Gamma
assign cfg_data_reg[136] = {24'h548cb8}; //Gamma
assign cfg_data_reg[137] = {24'h548dcd}; //Gamma
assign cfg_data_reg[138] = {24'h548edd}; //Gamma
assign cfg_data_reg[139] = {24'h548fea}; //Gamma
assign cfg_data_reg[140] = {24'h54901d}; //Gamma
assign cfg_data_reg[141] = {24'h558006}; //Digital Effects
assign cfg_data_reg[142] = {24'h558340}; //Digital Effects
assign cfg_data_reg[143] = {24'h558410}; //Digital Effects
assign cfg_data_reg[144] = {24'h558910}; //Digital Effects
assign cfg_data_reg[145] = {24'h558a00}; //Digital Effects
assign cfg_data_reg[146] = {24'h558bf8}; //Digital Effects
assign cfg_data_reg[147] = {24'h580023}; //LENC
assign cfg_data_reg[148] = {24'h580114}; //LENC
assign cfg_data_reg[149] = {24'h58020f}; //LENC
assign cfg_data_reg[150] = {24'h58030f}; //LENC
assign cfg_data_reg[151] = {24'h580412}; //LENC
assign cfg_data_reg[152] = {24'h580526}; //LENC
assign cfg_data_reg[153] = {24'h58060c}; //LENC
assign cfg_data_reg[154] = {24'h580708}; //LENC
assign cfg_data_reg[155] = {24'h580805}; //LENC
assign cfg_data_reg[156] = {24'h580905}; //LENC
assign cfg_data_reg[157] = {24'h580a08}; //LENC
assign cfg_data_reg[158] = {24'h580b0d}; //LENC
assign cfg_data_reg[159] = {24'h580c08}; //LENC
assign cfg_data_reg[160] = {24'h580d03}; //LENC
assign cfg_data_reg[161] = {24'h580e00}; //LENC
assign cfg_data_reg[162] = {24'h580f00}; //LENC
assign cfg_data_reg[163] = {24'h581003}; //LENC
assign cfg_data_reg[164] = {24'h581109}; //LENC
assign cfg_data_reg[165] = {24'h581207}; //LENC
assign cfg_data_reg[166] = {24'h581303}; //LENC
assign cfg_data_reg[167] = {24'h581400}; //LENC
assign cfg_data_reg[168] = {24'h581501}; //LENC
assign cfg_data_reg[169] = {24'h581603}; //LENC
assign cfg_data_reg[170] = {24'h581708}; //LENC
assign cfg_data_reg[171] = {24'h58180d}; //LENC
assign cfg_data_reg[172] = {24'h581908}; //LENC
assign cfg_data_reg[173] = {24'h581a05}; //LENC
assign cfg_data_reg[174] = {24'h581b06}; //LENC
assign cfg_data_reg[175] = {24'h581c08}; //LENC
assign cfg_data_reg[176] = {24'h581d0e}; //LENC
assign cfg_data_reg[177] = {24'h581e29}; //LENC
assign cfg_data_reg[178] = {24'h581f17}; //LENC
assign cfg_data_reg[179] = {24'h582011}; //LENC
assign cfg_data_reg[180] = {24'h582111}; //LENC
assign cfg_data_reg[181] = {24'h582215}; //LENC
assign cfg_data_reg[182] = {24'h582328}; //LENC
assign cfg_data_reg[183] = {24'h582446}; //LENC
assign cfg_data_reg[184] = {24'h582526}; //LENC
assign cfg_data_reg[185] = {24'h582608}; //LENC
assign cfg_data_reg[186] = {24'h582726}; //LENC
assign cfg_data_reg[187] = {24'h582864}; //LENC
assign cfg_data_reg[188] = {24'h582926}; //LENC
assign cfg_data_reg[189] = {24'h582a24}; //LENC
assign cfg_data_reg[190] = {24'h582b22}; //LENC
assign cfg_data_reg[191] = {24'h582c24}; //LENC
assign cfg_data_reg[192] = {24'h582d24}; //LENC
assign cfg_data_reg[193] = {24'h582e06}; //LENC
assign cfg_data_reg[194] = {24'h582f22}; //LENC
assign cfg_data_reg[195] = {24'h583040}; //LENC
assign cfg_data_reg[196] = {24'h583142}; //LENC
assign cfg_data_reg[197] = {24'h583224}; //LENC
assign cfg_data_reg[198] = {24'h583326}; //LENC
assign cfg_data_reg[199] = {24'h583424}; //LENC
assign cfg_data_reg[200] = {24'h583522}; //LENC
assign cfg_data_reg[201] = {24'h583622}; //LENC
assign cfg_data_reg[202] = {24'h583726}; //LENC
assign cfg_data_reg[203] = {24'h583844}; //LENC
assign cfg_data_reg[204] = {24'h583924}; //LENC
assign cfg_data_reg[205] = {24'h583a26}; //LENC
assign cfg_data_reg[206] = {24'h583b28}; //LENC
assign cfg_data_reg[207] = {24'h583c42}; //LENC
assign cfg_data_reg[208] = {24'h583dce}; //LENC
assign cfg_data_reg[209] = {24'h502500}; //Not documented
assign cfg_data_reg[210] = {24'h3a0f30}; //AEC
assign cfg_data_reg[211] = {24'h3a1028}; //AEC
assign cfg_data_reg[212] = {24'h3a1b30}; //AEC
assign cfg_data_reg[213] = {24'h3a1e26}; //AEC
assign cfg_data_reg[214] = {24'h3a1160}; //AEC
assign cfg_data_reg[215] = {24'h3a1f14}; //AEC
assign cfg_data_reg[216] = {24'h474104}; //DVP Test Pattern Enable, 8 bit
assign cfg_data_reg[217] = {24'h300802}; //Chip Power Up

endmodule