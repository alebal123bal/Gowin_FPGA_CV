`timescale 1ns/1ns
module tb_ov5640_top();

//// Parameters and Internal Signals ////

// Parameter definitions
parameter H_VALID = 10'd640,    // Horizontal valid data
          H_TOTAL = 10'd784;    // Horizontal scan period
parameter V_SYNC  = 10'd4,      // Vertical sync
          V_BACK  = 10'd18,     // Vertical back porch
          V_VALID = 10'd480,    // Vertical valid data
          V_FRONT = 10'd8,      // Vertical front porch
          V_TOTAL = 10'd510;    // Vertical scan period

// Wire definitions
wire ov5640_href;              // Horizontal sync signal
wire ov5640_vsync;             // Vertical sync signal
wire cfg_done;                 // Register configuration complete
wire sccb_scl;                 // SCL signal
wire sccb_sda;                 // SDA signal
wire wr_en;                    // Image data valid enable signal
wire [15:0] wr_data;          // Image data
wire ov5640_rst_n;            // Simulated ov5640 reset signal

// Register definitions
reg sys_clk;                   // Simulated clock signal
reg sys_rst_n;                 // Simulated reset signal
reg ov5640_pclk;              // Simulated camera clock signal
reg [7:0] ov5640_data;        // Simulated camera image data
reg [11:0] cnt_h;             // Horizontal sync counter
reg [9:0] cnt_v;              // Vertical sync counter

//// Main Code ////

// Clock and reset signal initialization
initial
begin
    sys_clk = 1'b1;
    ov5640_pclk = 1'b1;
    sys_rst_n <= 1'b0;
    #200
    sys_rst_n <= 1'b1;
end

always #20 sys_clk = ~sys_clk;
always #20 ov5640_pclk = ~ov5640_pclk;

assign ov5640_rst_n = sys_rst_n && cfg_done;

// cnt_h: Horizontal sync counter
always @(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        cnt_h <= 12'd0;
    else if(cnt_h == ((H_TOTAL * 2) - 1'b1))
        cnt_h <= 12'd0;
    else
        cnt_h <= cnt_h + 1'd1;

// ov5640_href: Horizontal sync signal
assign ov5640_href = (((cnt_h >= 0) 
                    && (cnt_h <= ((H_VALID * 2) - 1'b1)))
                    && ((cnt_v >= (V_SYNC + V_BACK))
                    && (cnt_v <= (V_SYNC + V_BACK + V_VALID - 1'b1))))
                    ? 1'b1 : 1'b0;

// cnt_v: Vertical sync counter
always @(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        cnt_v <= 10'd0;
    else if((cnt_v == (V_TOTAL - 1'b1)) 
            && (cnt_h == ((H_TOTAL * 2) - 1'b1)))
        cnt_v <= 10'd0;
    else if(cnt_h == ((H_TOTAL * 2) - 1'b1))
        cnt_v <= cnt_v + 1'd1;
    else
        cnt_v <= cnt_v;

// vsync: Vertical sync signal
assign ov5640_vsync = (cnt_v <= (V_SYNC - 1'b1)) ? 1'b1 : 1'b0;

// ov5640_data: Simulated camera image data
always @(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        ov5640_data <= 8'd0;
    else if(ov5640_href == 1'b1)
        ov5640_data <= ov5640_data + 1'b1;
    else
        ov5640_data <= 8'd0;

//// Module Instantiation ////

// ov5640 Top Module Instance
ov5640_top ov5640_top_inst(
    .sys_clk        (sys_clk),        // System clock
    .sys_rst_n      (sys_rst_n),      // Reset signal
    .sys_init_done  (ov5640_rst_n),   // System initialization complete (SDRAM + Camera)

    .ov5640_pclk    (ov5640_pclk),    // Camera pixel clock
    .ov5640_href    (ov5640_href),    // Camera horizontal sync signal
    .ov5640_vsync   (ov5640_vsync),   // Camera vertical sync signal
    .ov5640_data    (ov5640_data),    // Camera image data

    .cfg_done       (cfg_done),        // Register configuration complete
    .sccb_scl       (sccb_scl),        // SCL signal
    .sccb_sda       (sccb_sda),        // SDA signal
    .ov5640_wr_en   (wr_en),           // Image data valid enable signal
    .ov5640_data_out(wr_data)          // Image data output
);

// Simulation stop time
initial begin
    #40000000
    $stop;          // Or $finish;
end

endmodule