module ov5640_cfg_better_indexed
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
parameter REG_NUM = 10'd500;        // Total number of registers to configure
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

assign cfg_data_reg[0] = {24'h310311  }; 
assign cfg_data_reg[1] = {24'h300882  };
assign cfg_data_reg[2] = {24'h300802  };
assign cfg_data_reg[3] = {24'h310303  };
assign cfg_data_reg[4] = {24'h3017ff  };
assign cfg_data_reg[5] = {24'h3018ff  };
assign cfg_data_reg[6] = {24'h30341a  };    // DIV2_5
assign cfg_data_reg[7] = {24'h303511  };    // DIV2
assign cfg_data_reg[8] = {24'h30368c  };    // MULT140
assign cfg_data_reg[9] = {24'h303713  };    // DIV2, DIV3
assign cfg_data_reg[10] = {24'h310801  };
assign cfg_data_reg[11] = {24'h363036  };
assign cfg_data_reg[12] = {24'h36310e  };
assign cfg_data_reg[13] = {24'h3632e2  };
assign cfg_data_reg[14] = {24'h363312  };
assign cfg_data_reg[15] = {24'h3621e0  };
assign cfg_data_reg[16] = {24'h3704a0  };
assign cfg_data_reg[17] = {24'h37035a  };
assign cfg_data_reg[18] = {24'h371578  };
assign cfg_data_reg[19] = {24'h371701  };
assign cfg_data_reg[20] = {24'h370b60  };
assign cfg_data_reg[21] = {24'h37051a  };
assign cfg_data_reg[22] = {24'h390502  };
assign cfg_data_reg[23] = {24'h390610  };
assign cfg_data_reg[24] = {24'h39010a  };
assign cfg_data_reg[25] = {24'h373112  };
assign cfg_data_reg[26] = {24'h360008  };
assign cfg_data_reg[27] = {24'h360133  };
assign cfg_data_reg[28] = {24'h302d60  };
assign cfg_data_reg[29] = {24'h362052  };
assign cfg_data_reg[30] = {24'h371b20  };
assign cfg_data_reg[31] = {24'h471c50  };
assign cfg_data_reg[32] = {24'h3a1343  };
assign cfg_data_reg[33] = {24'h3a1800  };
assign cfg_data_reg[34] = {24'h3a19f8  };
assign cfg_data_reg[35] = {24'h363513  };
assign cfg_data_reg[36] = {24'h363603  };
assign cfg_data_reg[37] = {24'h363440  };
assign cfg_data_reg[38] = {24'h362201  };
 
assign cfg_data_reg[39] = {24'h3c0134  };
assign cfg_data_reg[40] = {24'h3c0428  };
assign cfg_data_reg[41] = {24'h3c0598  };
assign cfg_data_reg[42] = {24'h3c0600  };
assign cfg_data_reg[43] = {24'h3c0708  };
assign cfg_data_reg[44] = {24'h3c0800  };
assign cfg_data_reg[45] = {24'h3c091c  };
assign cfg_data_reg[46] = {24'h3c0a9c  };
assign cfg_data_reg[47] = {24'h3c0b40  };
assign cfg_data_reg[48] = {24'h382041  };
assign cfg_data_reg[49] = {24'h382107  };   // Binning
assign cfg_data_reg[50] = {24'h381431  };   // Pixel skip
assign cfg_data_reg[51] = {24'h381531  };   // Pixel skip
assign cfg_data_reg[52] = {24'h380000  };
assign cfg_data_reg[53] = {24'h380100  };
assign cfg_data_reg[54] = {24'h380200  };
assign cfg_data_reg[55] = {24'h380304  };
assign cfg_data_reg[56] = {24'h38040a  };
assign cfg_data_reg[57] = {24'h38053f  };
assign cfg_data_reg[58] = {24'h380607  };
assign cfg_data_reg[59] = {24'h38079b  };
assign cfg_data_reg[60] = {24'h380802  };
assign cfg_data_reg[61] = {24'h380980  };
assign cfg_data_reg[62] = {24'h380a01  };
assign cfg_data_reg[63] = {24'h380be0  };
assign cfg_data_reg[64] = {24'h380c07  };
assign cfg_data_reg[65] = {24'h380d68  };
assign cfg_data_reg[66] = {24'h380e03  };
assign cfg_data_reg[67] = {24'h380fd8  };
assign cfg_data_reg[68] = {24'h381000  };
assign cfg_data_reg[69] = {24'h381110  };
assign cfg_data_reg[70] = {24'h381200  };
assign cfg_data_reg[71] = {24'h381306  };
assign cfg_data_reg[72] = {24'h361800  };
assign cfg_data_reg[73] = {24'h361229  };
assign cfg_data_reg[74] = {24'h370864  };
assign cfg_data_reg[75] = {24'h370952  };
assign cfg_data_reg[76] = {24'h370c03  };
assign cfg_data_reg[77] = {24'h3a0203  };
assign cfg_data_reg[78] = {24'h3a03d8  };
assign cfg_data_reg[79] = {24'h3a0801  };
assign cfg_data_reg[80] = {24'h3a0927  };
assign cfg_data_reg[81] = {24'h3a0a00  };
assign cfg_data_reg[82] = {24'h3a0bf6  };
assign cfg_data_reg[83] = {24'h3a0e03  };
assign cfg_data_reg[84] = {24'h3a0d04  };
assign cfg_data_reg[85] = {24'h3a1403  };
assign cfg_data_reg[86] = {24'h3a15d8  };
 
assign cfg_data_reg[87] = {24'h400102  };
assign cfg_data_reg[88] = {24'h400402  };
assign cfg_data_reg[89] = {24'h300000  };
assign cfg_data_reg[90] = {24'h30021c  };
assign cfg_data_reg[91] = {24'h3004ff  };
assign cfg_data_reg[92] = {24'h3006c3  };
assign cfg_data_reg[93] = {24'h300e58  };
assign cfg_data_reg[94] = {24'h302e00  };
assign cfg_data_reg[95] = {24'h430060  };   // TODO: change to 60
assign cfg_data_reg[96] = {24'h501f01  };   // TODO: change to 01
assign cfg_data_reg[97] = {24'h471303  };
assign cfg_data_reg[98] = {24'h440704  };
assign cfg_data_reg[99] = {24'h440e00  };
assign cfg_data_reg[100] = {24'h460b35  };
assign cfg_data_reg[101] = {24'h460c22  };
assign cfg_data_reg[102] = {24'h382402  };
assign cfg_data_reg[103] = {24'h5000a7  };
assign cfg_data_reg[104] = {24'h5001a3  };
assign cfg_data_reg[105] = {24'h5180ff  };
assign cfg_data_reg[106] = {24'h5181f2  };
assign cfg_data_reg[107] = {24'h518200  };
assign cfg_data_reg[108] = {24'h518314  };
assign cfg_data_reg[109] = {24'h518425  };
assign cfg_data_reg[110] = {24'h518524  };
assign cfg_data_reg[111] = {24'h518609  };
assign cfg_data_reg[112] = {24'h518709  };
assign cfg_data_reg[113] = {24'h518809  };
assign cfg_data_reg[114] = {24'h518975  };
assign cfg_data_reg[115] = {24'h518a54  };
assign cfg_data_reg[116] = {24'h518be0  };
assign cfg_data_reg[117] = {24'h518cb2  };
assign cfg_data_reg[118] = {24'h518d42  };
assign cfg_data_reg[119] = {24'h518e3d  };
assign cfg_data_reg[120] = {24'h518f56  };
assign cfg_data_reg[121] = {24'h519046  };
assign cfg_data_reg[122] = {24'h5191f8  };
assign cfg_data_reg[123] = {24'h519204  };
assign cfg_data_reg[124] = {24'h519370  };
assign cfg_data_reg[125] = {24'h5194f0  };
assign cfg_data_reg[126] = {24'h5195f0  };
assign cfg_data_reg[127] = {24'h519603  };
assign cfg_data_reg[128] = {24'h519701  };
assign cfg_data_reg[129] = {24'h519804  };
assign cfg_data_reg[130] = {24'h519912  };
assign cfg_data_reg[131] = {24'h519a04  };
assign cfg_data_reg[132] = {24'h519b00  };
assign cfg_data_reg[133] = {24'h519c06  };
assign cfg_data_reg[134] = {24'h519d82  };
 
assign cfg_data_reg[135] = {24'h519e38  };
assign cfg_data_reg[136] = {24'h53811e  };
assign cfg_data_reg[137] = {24'h53825b  };
assign cfg_data_reg[138] = {24'h538308  };
assign cfg_data_reg[139] = {24'h53840a  };
assign cfg_data_reg[140] = {24'h53857e  };
assign cfg_data_reg[141] = {24'h538688  };
assign cfg_data_reg[142] = {24'h53877c  };
assign cfg_data_reg[143] = {24'h53886c  };
assign cfg_data_reg[144] = {24'h538910  };
assign cfg_data_reg[145] = {24'h538a01  };
assign cfg_data_reg[146] = {24'h538b98  };
assign cfg_data_reg[147] = {24'h530008  };
assign cfg_data_reg[148] = {24'h530130  };
assign cfg_data_reg[149] = {24'h530210  };
assign cfg_data_reg[150] = {24'h530300  };
assign cfg_data_reg[151] = {24'h530408  };
assign cfg_data_reg[152] = {24'h530530  };
assign cfg_data_reg[153] = {24'h530608  };
assign cfg_data_reg[154] = {24'h530716  };
assign cfg_data_reg[155] = {24'h530908  };
assign cfg_data_reg[156] = {24'h530a30  };
assign cfg_data_reg[157] = {24'h530b04  };
assign cfg_data_reg[158] = {24'h530c06  };
assign cfg_data_reg[159] = {24'h548001  };
assign cfg_data_reg[160] = {24'h548108  };
assign cfg_data_reg[161] = {24'h548214  };
assign cfg_data_reg[162] = {24'h548328  };
assign cfg_data_reg[163] = {24'h548451  };
assign cfg_data_reg[164] = {24'h548565  };
assign cfg_data_reg[165] = {24'h548671  };
assign cfg_data_reg[166] = {24'h54877d  };
assign cfg_data_reg[167] = {24'h548887  };
assign cfg_data_reg[168] = {24'h548991  };
assign cfg_data_reg[169] = {24'h548a9a  };
assign cfg_data_reg[170] = {24'h548baa  };
assign cfg_data_reg[171] = {24'h548cb8  };
assign cfg_data_reg[172] = {24'h548dcd  };
assign cfg_data_reg[173] = {24'h548edd  };
assign cfg_data_reg[174] = {24'h548fea  };
assign cfg_data_reg[175] = {24'h54901d  };
assign cfg_data_reg[176] = {24'h558002  };
assign cfg_data_reg[177] = {24'h558340  };
assign cfg_data_reg[178] = {24'h558410  };
assign cfg_data_reg[179] = {24'h558910  };
assign cfg_data_reg[180] = {24'h558a00  };
assign cfg_data_reg[181] = {24'h558bf8  };
assign cfg_data_reg[182] = {24'h580023  };
 
assign cfg_data_reg[183] = {24'h580114  };
assign cfg_data_reg[184] = {24'h58020f  };
assign cfg_data_reg[185] = {24'h58030f  };
assign cfg_data_reg[186] = {24'h580412  };
assign cfg_data_reg[187] = {24'h580526  };
assign cfg_data_reg[188] = {24'h58060c  };
assign cfg_data_reg[189] = {24'h580708  };
assign cfg_data_reg[190] = {24'h580805  };
assign cfg_data_reg[191] = {24'h580905  };
assign cfg_data_reg[192] = {24'h580a08  };
assign cfg_data_reg[193] = {24'h580b0d  };
assign cfg_data_reg[194] = {24'h580c08  };
assign cfg_data_reg[195] = {24'h580d03  };
assign cfg_data_reg[196] = {24'h580e00  };
assign cfg_data_reg[197] = {24'h580f00  };
assign cfg_data_reg[198] = {24'h581003  };
assign cfg_data_reg[199] = {24'h581109  };
assign cfg_data_reg[200] = {24'h581207  };
assign cfg_data_reg[201] = {24'h581303  };
assign cfg_data_reg[202] = {24'h581400  };
assign cfg_data_reg[203] = {24'h581501  };
assign cfg_data_reg[204] = {24'h581603  };
assign cfg_data_reg[205] = {24'h581708  };
assign cfg_data_reg[206] = {24'h58180d  };
assign cfg_data_reg[207] = {24'h581908  };
assign cfg_data_reg[208] = {24'h581a05  };
assign cfg_data_reg[209] = {24'h581b06  };
assign cfg_data_reg[210] = {24'h581c08  };
assign cfg_data_reg[211] = {24'h581d0e  };
assign cfg_data_reg[212] = {24'h581e29  };
assign cfg_data_reg[213] = {24'h581f17  };
assign cfg_data_reg[214] = {24'h582011  };
assign cfg_data_reg[215] = {24'h582111  };
assign cfg_data_reg[216] = {24'h582215  };
assign cfg_data_reg[217] = {24'h582328  };
assign cfg_data_reg[218] = {24'h582446  };
assign cfg_data_reg[219] = {24'h582526  };
assign cfg_data_reg[220] = {24'h582608  };
assign cfg_data_reg[221] = {24'h582726  };
assign cfg_data_reg[222] = {24'h582864  };
assign cfg_data_reg[223] = {24'h582926  };
assign cfg_data_reg[224] = {24'h582a24  };
assign cfg_data_reg[225] = {24'h582b22  };
assign cfg_data_reg[226] = {24'h582c24  };
assign cfg_data_reg[227] = {24'h582d24  };
assign cfg_data_reg[228] = {24'h582e06  };
assign cfg_data_reg[229] = {24'h582f22  };
assign cfg_data_reg[230] = {24'h583040  };
 
assign cfg_data_reg[231] = {24'h583142  };
assign cfg_data_reg[232] = {24'h583224  };
assign cfg_data_reg[233] = {24'h583326  };
assign cfg_data_reg[234] = {24'h583424  };
assign cfg_data_reg[235] = {24'h583522  };
assign cfg_data_reg[236] = {24'h583622  };
assign cfg_data_reg[237] = {24'h583726  };
assign cfg_data_reg[238] = {24'h583844  };
assign cfg_data_reg[239] = {24'h583924  };
assign cfg_data_reg[240] = {24'h583a26  };
assign cfg_data_reg[241] = {24'h583b28  };
assign cfg_data_reg[242] = {24'h583c42  };
assign cfg_data_reg[243] = {24'h583dce  };
assign cfg_data_reg[244] = {24'h502500  };
assign cfg_data_reg[245] = {24'h3a0f30  };
assign cfg_data_reg[246] = {24'h3a1028  };
assign cfg_data_reg[247] = {24'h3a1b30  };
assign cfg_data_reg[248] = {24'h3a1e26  };
assign cfg_data_reg[249] = {24'h3a1160  };
assign cfg_data_reg[250] = {24'h3a1f14  };
assign cfg_data_reg[251] = {24'h300802  };
assign cfg_data_reg[252] = {24'h303521  };
 
assign cfg_data_reg[253] = {24'h3c01b4  };
assign cfg_data_reg[254] = {24'h3c0004  };
 
assign cfg_data_reg[255] = {24'h3a197c  };
 
assign cfg_data_reg[256] = {24'h58002c  };
assign cfg_data_reg[257] = {24'h580117  };
assign cfg_data_reg[258] = {24'h580211  };
assign cfg_data_reg[259] = {24'h580311  };
assign cfg_data_reg[260] = {24'h580415  };
assign cfg_data_reg[261] = {24'h580529  };
assign cfg_data_reg[262] = {24'h580608  };
assign cfg_data_reg[263] = {24'h580706  };
assign cfg_data_reg[264] = {24'h580804  };
assign cfg_data_reg[265] = {24'h580904  };
assign cfg_data_reg[266] = {24'h580a05  };
assign cfg_data_reg[267] = {24'h580b07  };
assign cfg_data_reg[268] = {24'h580c06  };
assign cfg_data_reg[269] = {24'h580d03  };
assign cfg_data_reg[270] = {24'h580e01  };
assign cfg_data_reg[271] = {24'h580f01  };
assign cfg_data_reg[272] = {24'h581003  };
assign cfg_data_reg[273] = {24'h581106  };
 
assign cfg_data_reg[274] = {24'h581206  };
assign cfg_data_reg[275] = {24'h581302  };
assign cfg_data_reg[276] = {24'h581401  };
assign cfg_data_reg[277] = {24'h581501  };
assign cfg_data_reg[278] = {24'h581604  };
assign cfg_data_reg[279] = {24'h581707  };
assign cfg_data_reg[280] = {24'h581806  };
assign cfg_data_reg[281] = {24'h581907  };
assign cfg_data_reg[282] = {24'h581a06  };
assign cfg_data_reg[283] = {24'h581b06  };
assign cfg_data_reg[284] = {24'h581c06  };
assign cfg_data_reg[285] = {24'h581d0e  };
assign cfg_data_reg[286] = {24'h581e31  };
assign cfg_data_reg[287] = {24'h581f12  };
assign cfg_data_reg[288] = {24'h582011  };
assign cfg_data_reg[289] = {24'h582111  };
assign cfg_data_reg[290] = {24'h582211  };
assign cfg_data_reg[291] = {24'h58232f  };
assign cfg_data_reg[292] = {24'h582412  };
assign cfg_data_reg[293] = {24'h582525  };
assign cfg_data_reg[294] = {24'h582639  };
assign cfg_data_reg[295] = {24'h582729  };
assign cfg_data_reg[296] = {24'h582827  };
assign cfg_data_reg[297] = {24'h582939  };
assign cfg_data_reg[298] = {24'h582a26  };
assign cfg_data_reg[299] = {24'h582b33  };
assign cfg_data_reg[300] = {24'h582c24  };
assign cfg_data_reg[301] = {24'h582d39  };
assign cfg_data_reg[302] = {24'h582e28  };
assign cfg_data_reg[303] = {24'h582f21  };
assign cfg_data_reg[304] = {24'h583040  };
assign cfg_data_reg[305] = {24'h583121  };
assign cfg_data_reg[306] = {24'h583217  };
assign cfg_data_reg[307] = {24'h583317  };
assign cfg_data_reg[308] = {24'h583415  };
assign cfg_data_reg[309] = {24'h583511  };
assign cfg_data_reg[310] = {24'h583624  };
assign cfg_data_reg[311] = {24'h583727  };
assign cfg_data_reg[312] = {24'h583826  };
assign cfg_data_reg[313] = {24'h583926  };
assign cfg_data_reg[314] = {24'h583a26  };
assign cfg_data_reg[315] = {24'h583b28  };
assign cfg_data_reg[316] = {24'h583c14  };
assign cfg_data_reg[317] = {24'h583dee  };
assign cfg_data_reg[318] = {24'h40051a  };
 
assign cfg_data_reg[319] = {24'h538126   };
assign cfg_data_reg[320] = {24'h538250   };
 
assign cfg_data_reg[321] = {24'h53830c   };
assign cfg_data_reg[322] = {24'h538409   };
assign cfg_data_reg[323] = {24'h538574   };
assign cfg_data_reg[324] = {24'h53867d   };
assign cfg_data_reg[325] = {24'h53877e   };
assign cfg_data_reg[326] = {24'h538875   };
assign cfg_data_reg[327] = {24'h538909   };
assign cfg_data_reg[328] = {24'h538b98   };
assign cfg_data_reg[329] = {24'h538a01   };
 
assign cfg_data_reg[330] = {24'h558002   };
assign cfg_data_reg[331] = {24'h558801   };
assign cfg_data_reg[332] = {24'h558340   };
assign cfg_data_reg[333] = {24'h558410   };
assign cfg_data_reg[334] = {24'h55890f   };
assign cfg_data_reg[335] = {24'h558a00   };
assign cfg_data_reg[336] = {24'h558b3f   };
 
assign cfg_data_reg[337] = {24'h530825   };
assign cfg_data_reg[338] = {24'h530408   };
assign cfg_data_reg[339] = {24'h530530   };
assign cfg_data_reg[340] = {24'h530610   };
assign cfg_data_reg[341] = {24'h530720   };
 
assign cfg_data_reg[342] = {24'h5180ff   };
assign cfg_data_reg[343] = {24'h5181f2   };
assign cfg_data_reg[344] = {24'h518211   };
assign cfg_data_reg[345] = {24'h518314   };
assign cfg_data_reg[346] = {24'h518425   };
assign cfg_data_reg[347] = {24'h518524   };
assign cfg_data_reg[348] = {24'h518610   };
assign cfg_data_reg[349] = {24'h518712   };
assign cfg_data_reg[350] = {24'h518810   };
assign cfg_data_reg[351] = {24'h518980   };
assign cfg_data_reg[352] = {24'h518a54   };
assign cfg_data_reg[353] = {24'h518bb8   };
assign cfg_data_reg[354] = {24'h518cb2   };
assign cfg_data_reg[355] = {24'h518d42   };
assign cfg_data_reg[356] = {24'h518e3a   };
assign cfg_data_reg[357] = {24'h518f56   };
assign cfg_data_reg[358] = {24'h519046   };
assign cfg_data_reg[359] = {24'h5191f0   };
assign cfg_data_reg[360] = {24'h5192f    };
assign cfg_data_reg[361] = {24'h519370   };
 
assign cfg_data_reg[362] = {24'h5194f0   };
assign cfg_data_reg[363] = {24'h5195f0   };
assign cfg_data_reg[364] = {24'h51963    };
assign cfg_data_reg[365] = {24'h51971    };
assign cfg_data_reg[366] = {24'h51986    };
assign cfg_data_reg[367] = {24'h519962   };
assign cfg_data_reg[368] = {24'h519a4    };
assign cfg_data_reg[369] = {24'h519b0    };
assign cfg_data_reg[370] = {24'h519c4    };
assign cfg_data_reg[371] = {24'h519de7   };
assign cfg_data_reg[372] = {24'h519e38   };

endmodule