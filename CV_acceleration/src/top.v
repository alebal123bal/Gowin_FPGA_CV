`timescale 1ns / 1ps

module top
(
    input             I_clk           , //27Mhz
    input             I_rst_n         ,
    output     [3:0]  O_led           , 
    output            O_tmds_clk_p    ,
    output            O_tmds_clk_n    ,
    output     [2:0]  O_tmds_data_p   ,//{r,g,b}
    output     [2:0]  O_tmds_data_n   ,
    inout             cmos_scl,          //cmos i2c clock
	inout             cmos_sda,          //cmos i2c data
	input             cmos_vsync,        //cmos vsync coming from OV5640
	input             cmos_href,         //cmos hsync refrence,data valid coming from OV5640
	input             cmos_pclk,         //cmos pixel clock coming from OV5640
    output            cmos_xclk,         //cmos externl clock 
	input   [7:0]     cmos_db,           //cmos data coming from OV5640
	output            cmos_rst_n,        //cmos reset 
	output            cmos_pwdn,         //cmos power down
    output  [7:0]     PMOD_wire          //Frequency measurements with DSO: they should all be converted to T = 1 second for correctness
);

//==================================================
reg  [31:0] run_cnt;

//--------------------------
wire        tp0_vs_in  ;
wire        tp0_hs_in  ;
wire        tp0_de_in ;
wire [ 7:0] tp0_data_r/*synthesis syn_keep=1*/;
wire [ 7:0] tp0_data_g/*synthesis syn_keep=1*/;
wire [ 7:0] tp0_data_b/*synthesis syn_keep=1*/;


//===================================================
//HDMI4 TX
wire serial_clk;
wire pll_lock;
wire hdmi4_rst_n;
wire pix_clk;

//===================================================
// Debug wires and regs to measure with oscilloscope
wire debug_wire_HMDI_clk;
reg debug_reg_CMOS_clk;

//===================================================
// OV5640 camera
wire cmos_clk;
reg [24:0] counter_CMOS_clk;        // 25 bits can count up to 33,554,432
wire debug_PCLK;
assign debug_PCLK = cmos_href;

//=========================================================================
// I2C master controller for OV5640 registers setup using I2C_MASTER_Top


//===================================================
// LUT for OV5640 registers
wire[9:0] lut_index;
wire[31:0] lut_data;

//===========================================================================
//Timing and testpattern generator
testpattern testpattern_inst
(
    .I_pxl_clk   (pix_clk            ),//pixel clock
    .I_rst_n     (hdmi4_rst_n        ),//low active
                                                         // 800x600   // 1024x768  // 1280x720    
    .I_h_total   (12'd1650           ),//hor total time  // 12'd1056  // 12'd1344  // 12'd1650  
    .I_h_sync    (12'd40             ),//hor sync time   // 12'd128   // 12'd136   // 12'd40    
    .I_h_bporch  (12'd220            ),//hor back porch  // 12'd88    // 12'd160   // 12'd220   
    .I_h_res     (12'd1280           ),//hor resolution  // 12'd800   // 12'd1024  // 12'd1280  
    .I_v_total   (12'd750            ),//ver total time  // 12'd628   // 12'd806   // 12'd750    
    .I_v_sync    (12'd5              ),//ver sync time   // 12'd4     // 12'd6     // 12'd5     
    .I_v_bporch  (12'd20             ),//ver back porch  // 12'd23    // 12'd29    // 12'd20    
    .I_v_res     (12'd720            ),//ver resolution  // 12'd600   // 12'd768   // 12'd720    
    .I_hs_pol    (1'b1               ),//HS polarity , 0:negetive ploarity，1：positive polarity
    .I_vs_pol    (1'b1               ),//VS polarity , 0:negetive ploarity，1：positive polarity
    .O_de        (tp0_de_in          ),   
    .O_hs        (tp0_hs_in          ),
    .O_vs        (tp0_vs_in          ),
    .O_data_r    (tp0_data_r         ),   
    .O_data_g    (tp0_data_g         ),
    .O_data_b    (tp0_data_b         ),
    .FPS_measure_DSO(debug_wire_HMDI_clk)
);


//==============================================================================
//PLL for TMDS TX(HDMI4) @ 371.25MHz
TMDS_rPLL u_tmds_rpll
(.clkin     (I_clk     ),
.clkout    (serial_clk),
.lock      (pll_lock  )
);

assign hdmi4_rst_n = I_rst_n & pll_lock;

//==============================================================================
//PLL for HDMI @ 74.25MHz
CLKDIV u_clkdiv
(.RESETN(hdmi4_rst_n)
,.HCLKIN(serial_clk) //clk  x5
,.CLKOUT(pix_clk)    //clk  x1
,.CALIB (1'b1)
);
defparam u_clkdiv.DIV_MODE="5";
defparam u_clkdiv.GSREN="false";

//==============================================================================
//Actual HDMI transmitter, receiving input from testpattern and interfacing with physical HDMI cable
DVI_TX_Top DVI_TX_Top_inst
(
    .I_rst_n       (hdmi4_rst_n   ),  //asynchronous reset, low active
    .I_serial_clk  (serial_clk    ),
    .I_rgb_clk     (pix_clk       ),  //pixel clock
    .I_rgb_vs      (tp0_vs_in     ), 
    .I_rgb_hs      (tp0_hs_in     ),    
    .I_rgb_de      (tp0_de_in     ), 
    .I_rgb_r       (  tp0_data_r ),  //tp0_data_r
    .I_rgb_g       (  tp0_data_g  ),  
    .I_rgb_b       (  tp0_data_b  ),  
    .O_tmds_clk_p  (O_tmds_clk_p  ),  //Positive clock
    .O_tmds_clk_n  (O_tmds_clk_n  ),
    .O_tmds_data_p (O_tmds_data_p ),  //{r,g,b}
    .O_tmds_data_n (O_tmds_data_n )
);

//=========================================================================
//PLL for OV5640 @ xxMHz


//=========================================================================
//I2C controller for OV5640 registers setup


//=========================================================================
//Configure look-up table
lut_ov5640_rgb565_1280_720 lut_ov5640_rgb565_1280_720_m0(
	.lut_index                  (lut_index                ),
	.lut_data                   (lut_data                 )
);


//===================================================
//Test main clock source @ 27MHz (untested atm)
always @(posedge I_clk or negedge I_rst_n) //I_clk
begin
    if(!I_rst_n)
        run_cnt <= 32'd0;
    else if(run_cnt >= 32'd27_000_000)
        run_cnt <= 32'd0;
    else
        run_cnt <= run_cnt + 1'b1;
end

//===================================================
//LED test
assign  O_led[0] = 1;
assign  O_led[1] = 1;
assign  O_led[2] = 1;
assign  O_led[3] = I_rst_n;

//===================================================
//CMOS PLL frequency test

// 24MHz = 24,000,000 cycles per second
localparam HALF_PERIOD = 12_000_000;
    
always @(posedge cmos_clk or negedge I_rst_n) begin
    if (!I_rst_n) begin
        counter_CMOS_clk <= 0;
        debug_reg_CMOS_clk <= 0;
    end else begin
        if (counter_CMOS_clk == HALF_PERIOD - 1) begin
            counter_CMOS_clk <= 0;
            debug_reg_CMOS_clk <= ~debug_reg_CMOS_clk;
        end else begin
            counter_CMOS_clk <= counter_CMOS_clk + 1;
        end
    end
end

//===================================================
// State machine to iterate through the LUT


//===================================================
// Camera control signals
assign cmos_xclk = cmos_clk;    // Connect external (from FPGA) to camera clock
assign cmos_pwdn = 1'b0;        // Power down inactive
assign cmos_rst_n = 1'b1;       // Reset inactive

//===================================================
// Debug through PMOD connectors
assign PMOD_wire[0] = debug_wire_HMDI_clk;    //HDMI @ 74.25MHz
assign PMOD_wire[1] = debug_reg_CMOS_clk;    //OV5640 @ 24MHz
assign PMOD_wire[2] = debug_PCLK;    //OV5640 @ 24MHz

endmodule