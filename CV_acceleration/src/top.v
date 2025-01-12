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

//===================================================
// DDR3 interface
wire                   memory_clk         ;
wire                   dma_clk         	  ;
wire                   DDR_pll_lock       ;
wire                   cmd_ready          ;
wire[2:0]              cmd                ;
wire                   cmd_en             ;
wire[5:0]              app_burst_number   ;
wire[ADDR_WIDTH-1:0]   addr               ;
wire                   wr_data_rdy        ;
wire                   wr_data_en         ;
wire                   wr_data_end        ;
wire[DATA_WIDTH-1:0]   wr_data            ;   
wire[DATA_WIDTH/8-1:0] wr_data_mask       ;   
wire                   rd_data_valid      ;  
wire                   rd_data_end        ;//unused 
wire[DATA_WIDTH-1:0]   rd_data            ;   
wire                   init_calib_complete;

//According to IP parameters to choose
`define	    WR_VIDEO_WIDTH_16
`define	DEF_WR_VIDEO_WIDTH 16

`define	    RD_VIDEO_WIDTH_16
`define	DEF_RD_VIDEO_WIDTH 16

`define	USE_THREE_FRAME_BUFFER

`define	DEF_ADDR_WIDTH 28 
`define	DEF_SRAM_DATA_WIDTH 128

//The memory is organized with byte-sized storage units, and has a total capacity of 2^27 * 16 bits,
// which equals 2 Gigabits. An additional rank address bit has been added.
// The full address is composed of {rank[0], bank[2:0], row[13:0], column[9:0]}.
parameter ADDR_WIDTH          = `DEF_ADDR_WIDTH;

//This relates to the generated DDR3 IP. The DDR3 is 2 Gigabits, x16 (meaning 16 data bits wide externally),
// and uses a 1:4 clock ratio.
// This results in a fixed internal data bus width of 128 bits.
parameter DATA_WIDTH          = `DEF_SRAM_DATA_WIDTH;
parameter WR_VIDEO_WIDTH      = `DEF_WR_VIDEO_WIDTH;  
parameter RD_VIDEO_WIDTH      = `DEF_RD_VIDEO_WIDTH;  

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
    .clk_27         (I_clk      ),
    .rst_n          (I_rst_n    ),
    .camera_pwnd    (cmos_pwdn  ),
    .camera_rstn    (cmos_rst_n )
);

//=========================================================================
// DDR3 PLL (400MHz)
mem_pll mem_pll_m0(
	.clkin          (I_clk           ),
	.clkout         (memory_clk      ),
	.lock           (DDR_pll_lock    )
);

//=========================================================================
// DDR3 interface
DDR3MI DDR3_Memory_Interface_Top_inst
(
    .clk                (pix_clk            ),
    .memory_clk         (memory_clk         ),
    .pll_lock           (DDR_pll_lock       ),
    .rst_n              (I_rst_n            ),
    .app_burst_number   (app_burst_number   ),
    .cmd_ready          (cmd_ready          ),
    .cmd                (cmd                ),
    .cmd_en             (cmd_en             ),
    .addr               (addr               ),
    .wr_data_rdy        (wr_data_rdy        ),
    .wr_data            (wr_data            ),
    .wr_data_en         (wr_data_en         ),
    .wr_data_end        (wr_data_end        ),
    .wr_data_mask       (wr_data_mask       ),
    .rd_data            (rd_data            ),
    .rd_data_valid      (rd_data_valid      ),
    .rd_data_end        (rd_data_end        ),
    .sr_req             (1'b0               ),
    .ref_req            (1'b0               ),
    .sr_ack             (                   ),
    .ref_ack            (                   ),
    .init_calib_complete(init_calib_complete),
    .clk_out            (dma_clk            ),
    .burst              (1'b1               ),
    // mem interface
    .ddr_rst            (                 ),
    .O_ddr_addr         (ddr_addr         ),
    .O_ddr_ba           (ddr_bank         ),
    .O_ddr_cs_n         (ddr_cs         ),
    .O_ddr_ras_n        (ddr_ras        ),
    .O_ddr_cas_n        (ddr_cas        ),
    .O_ddr_we_n         (ddr_we         ),
    .O_ddr_clk          (ddr_ck          ),
    .O_ddr_clk_n        (ddr_ck_n        ),
    .O_ddr_cke          (ddr_cke          ),
    .O_ddr_odt          (ddr_odt          ),
    .O_ddr_reset_n      (ddr_reset_n      ),
    .O_ddr_dqm          (ddr_dm           ),
    .IO_ddr_dq          (ddr_dq           ),
    .IO_ddr_dqs         (ddr_dqs          ),
    .IO_ddr_dqs_n       (ddr_dqs_n        )
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