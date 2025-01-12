`timescale 1ns / 1ps

module top
(
    input               I_clk               ,   //27Mhz
    input               I_rst_n             ,
    output     [3:0]    O_led               , 
    
    // HDMI
    output              O_tmds_clk_p        ,
    output              O_tmds_clk_n        ,
    output     [2:0]    O_tmds_data_p       ,   //{r,g,b}
    output     [2:0]    O_tmds_data_n       ,
    
    // OV5640
    inout               cmos_scl            ,   //cmos i2c clock
	inout               cmos_sda            ,   //cmos i2c data
	input               cmos_vsync          ,   //cmos vsync coming from OV5640
	input               cmos_href           ,   //cmos hsync refrence,data valid coming from OV5640
	input               cmos_pclk           ,   //cmos pixel clock coming from OV5640
    output              cmos_xclk           ,   //cmos externl clock 
	input   [7:0]       cmos_db             ,   //cmos data coming from OV5640
	output              cmos_rst_n          ,   //cmos reset 
	output              cmos_pwdn           ,   //cmos power down

    // DDR3
	output [14-1:0]     ddr_addr            ,   //ROW_WIDTH=14
	output [3-1:0]      ddr_bank            ,   //BANK_WIDTH=3
	output              ddr_cs              ,
	output              ddr_ras             ,
	output              ddr_cas             ,
	output              ddr_we              ,
	output              ddr_ck              ,
	output              ddr_ck_n            ,
	output              ddr_cke             ,
	output              ddr_odt             ,
	output              ddr_reset_n         ,
	output [2-1:0]      ddr_dm              ,   //DM_WIDTH=2
	inout [16-1:0]      ddr_dq              ,   //DQ_WIDTH=16
	inout [2-1:0]       ddr_dqs             ,   //DQS_WIDTH=2
	inout [2-1:0]       ddr_dqs_n           ,   //DQS_WIDTH=2

    // UART TX
    output            uart_tx               ,

    // PMOD CONNECTORS
    output  [7:0]     PMOD_wire             //To logic analyzer
);


//===================================================
// HDMI4 TX
wire        tp0_vs_in   ;   // Vertical sync
wire        tp0_hs_in   ;   // Horizontal sync
wire        tp0_de_in   ;   // Data enable
wire [ 7:0] tp0_data_r  /*synthesis syn_keep=1*/;
wire [ 7:0] tp0_data_g  /*synthesis syn_keep=1*/;
wire [ 7:0] tp0_data_b  /*synthesis syn_keep=1*/;
wire        serial_clk  ;   // 371.25MHz
wire        pll_lock    ;
wire        hdmi4_rst_n ;
wire        pix_clk     ;   // 74.25MHz

//===================================================
// OV5640 camera
wire        cmos_clk_24;
wire        write_en;
wire        cfg_done;
wire        sys_init_done;
assign      sys_init_done = 1'b1;

//===========================================================================
// Timing generator
timing_tx timing_tx_inst
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
    .I_hs_pol    (1'b1               ),//HS polarity , 0:negative polarity，1：positive polarity
    .I_vs_pol    (1'b1               ),//VS polarity , 0:negative polarity，1：positive polarity
    .O_de        (tp0_de_in          ),   
    .O_hs        (tp0_hs_in          ),
    .O_vs        (tp0_vs_in          )
);

//===========================================================================
//Testpattern generator
red_green_fade red_green_fade_inst
(
    .I_pxl_clk   (pix_clk            ),//pixel clock
    .I_rst_n     (hdmi4_rst_n        ),//low active
    .I_vs        (tp0_vs_in          ),
    .O_data_r    (tp0_data_r         ),   
    .O_data_g    (tp0_data_g         ),
    .O_data_b    (tp0_data_b         )
);

//==============================================================================
//PLL for TMDS TX(HDMI4) @ 371.25MHz
TMDS_rPLL u_tmds_rpll
(
    .clkin     (I_clk     ),
    .clkout    (serial_clk), //clk  x5  (371.25MHz)
    .lock      (pll_lock  )
);

assign hdmi4_rst_n = I_rst_n & pll_lock;    //Release reset only when PLL is working

//==============================================================================
//PLL for HDMI @ 74.25MHz
CLKDIV u_clkdiv
(
    .RESETN     (hdmi4_rst_n    ),
    .HCLKIN     (serial_clk     ),  //clk  x5  (371.25MHz)
    .CLKOUT     (pix_clk        ),  //clk  x1  ( 74.25MHz)
    .CALIB      (1'b1           )
);
defparam u_clkdiv.DIV_MODE="5";
defparam u_clkdiv.GSREN="false";

//==============================================================================
//Actual HDMI transmitter, receiving input from testpattern and interfacing with PHYSICAL HDMI cable
DVI_TX_Top DVI_TX_Top_inst
(
    .I_rst_n       (hdmi4_rst_n   ),  //asynchronous reset, low active
    .I_serial_clk  (serial_clk    ),
    .I_rgb_clk     (pix_clk       ),  //pixel clock
    .I_rgb_vs      (tp0_vs_in     ), 
    .I_rgb_hs      (tp0_hs_in     ),    
    .I_rgb_de      (tp0_de_in     ), 
    .I_rgb_r       (tp0_data_r    ),
    .I_rgb_g       (tp0_data_g    ),  
    .I_rgb_b       (tp0_data_b    ),  
    .O_tmds_clk_p  (O_tmds_clk_p  ),  //Positive clock
    .O_tmds_clk_n  (O_tmds_clk_n  ),
    .O_tmds_data_p (O_tmds_data_p ),  //{r,g,b}
    .O_tmds_data_n (O_tmds_data_n )
);

//=========================================================================
//PLL for OV5640 @ 24MHz
CMOS_rPLL CMOS_rPLL_inst
(
    .clkout     (cmos_clk_24    ), //output clkout
    .clkin      (I_clk          ) //input clkin
);

//=========================================================================
// OV5640 setup
ov5640_top ov5640_top_inst
(
    .sys_clk        (cmos_clk_24    ),// System clock
    .sys_rst_n      (I_rst_n        ),// Reset signal
    .sys_init_done  (sys_init_done  ),// Unused atm
    .ov5640_pclk    (cmos_pclk      ),// Camera pixel clock @42MHz
    .ov5640_href    (cmos_href      ),// Camera horizontal sync signal
    .ov5640_vsync   (cmos_vsync     ),// Camera vertical sync signal
    .ov5640_data    (cmos_db        ),// Camera image data

    .cfg_done       (cfg_done       ),// Register configuration complete
    .sccb_scl       (cmos_scl       ),// SCL signal
    .sccb_sda       (cmos_sda       ),// SDA signal
    .ov5640_wr_en   (write_en       ),// Image data valid enable signal
    .ov5640_data_out(               ) // Image data output 16 bit
);

assign cmos_xclk = cmos_clk_24;    // Connect external (from FPGA) to OV5640 clock

// Instantiate OV5640 Control
power_on_delay pod_inst 
(
    .clk_27     (I_clk      ),
    .rst_n      (I_rst_n    ),
    .camera_pwnd(cmos_pwdn  ),
    .camera_rstn(cmos_rst_n )
);

//===================================================
// Print Control


//===================================================
// LED test
assign  O_led[0] = 1;
assign  O_led[1] = 1;
assign  O_led[2] = 1;
assign  O_led[3] = I_rst_n;

//===================================================
// Frequency test: convert to 1 second counters

localparam HALF_PERIOD = 21_000_000;

reg [31:0] counter_CMOS_clk;        // 32 bits can count up to 2.14 Billion
reg debug_reg_CMOS_clk;
    
always @(posedge cmos_pclk or negedge I_rst_n) begin
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
// Debug through PMOD connectors
assign PMOD_wire[0] = I_rst_n;

assign PMOD_wire[1] = cmos_scl;
assign PMOD_wire[2] = cmos_sda;      

assign PMOD_wire[3] = cmos_pwdn;    
assign PMOD_wire[4] = cmos_rst_n;

assign PMOD_wire[5] = cmos_vsync;

assign PMOD_wire[6] = debug_reg_CMOS_clk;


endmodule