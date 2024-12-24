`timescale 1ns / 1ps

module top (
    input clk,          // 27 MHz clock
    input rst_n,        // Active low reset
    input sel_button,   // Input for source selection
    output uart_tx,     // UART TX pin
    output Voltage,
    output PLL_ok
);

// Parameters
parameter CLK_FREQ = 27;        // 27 MHz
parameter BAUD_RATE = 115200;   // 115200 bps
parameter MESSAGE_LEN = 15;     // Length of "Hello World x\r\n"

// Registers
reg [131:0] message_buf;
reg [3:0] char_index;
reg [7:0] tx_data;
reg tx_data_valid;
reg [26:0] counter_main;            // Sufficient bits to count to ~27,000,000
reg [31:0] counter_rPLL;            // More than sufficient bits to count to ~54,000,000
reg [7:0] letter;             // 8 bits to represent A-Z (0-25)
reg sending;
reg source_select;            // Register to hold the toggled state
reg source_select_prev;       // For edge detection
reg freq_comp_ready;        // High once every second

// Wires
wire tx_data_ready;
wire freq_match;
wire freq_high;
wire freq_low;
wire [7:0] rom_data;         // Data from ROM
wire [3:0] rom_addr;         // Address for ROM
wire pll_clk;                // Wire for PLL output


// Button debounce and toggle logic
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        source_select <= 1'b0;
        source_select_prev <= 1'b0;
    end else begin
        source_select_prev <= sel_button;
        if (sel_button && !source_select_prev) begin  // Rising edge detection
            source_select <= !source_select;
        end
    end
end

// UART TX instance
uart_tx #(
    .CLK_FRE(CLK_FREQ),
    .BAUD_RATE(BAUD_RATE)
) uart_tx_inst (
    .clk(clk),
    .rst_n(rst_n),
    .tx_data(tx_data),
    .tx_data_valid(tx_data_valid),
    .tx_data_ready(tx_data_ready),
    .tx_pin(uart_tx)
);

// pROM instance
Gowin_pROM my_ROM(
    .dout(rom_data),        // output [7:0] dout
    .clk(clk),             // input clk
    .oce(1'b1),            // input oce
    .ce(1'b1),             // input ce
    .reset(!rst_n),        // input reset
    .ad(rom_addr)          // input [3:0] ad
);

// PLL instance
Gowin_rPLL pll_inst (
    .clkout(pll_clk),
    .clkin(clk)
);

// frequency_comparator instance
frequency_comparator #(
    .EXPECTED_FREQ(54_000_000),  // 54 MHz
    .TOLERANCE_PERCENT(1)         // 1% tolerance
) freq_comp (
    .clk(clk),
    .rst_n(rst_n),
    .measured_freq(counter_rPLL),
    .new_data_valid(freq_comp_ready),
    .freq_match(freq_match),
    .freq_too_high(freq_high),
    .freq_too_low(freq_low)
);

assign rom_addr = char_index;  // Use char_index as ROM address

// Synchronous Initialization of the Message Buffer
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Initialize static part of the message
        message_buf <= { "Hello World ", 8'h00, 8'h0D, 8'h0A }; // Reserve byte for 'x' at position 12
    end else begin

    end
end

// 1-second counter @27MHz
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        counter_main <= 0;
        freq_comp_ready <= 0;
    end else if (counter_main == (CLK_FREQ * 27'd1_000_000 - 1)) begin // 27 MHz * 1s
        counter_main <= 0;
        freq_comp_ready <= 1;
    end else begin
        counter_main <= counter_main + 1;
        freq_comp_ready <= 0;
    end
end


// 1-second counter @Custom frequency (used to check correct bhv of rPLL)
always @(posedge pll_clk or negedge rst_n) begin
    if (!rst_n) begin
        counter_rPLL <= 0;
    end else if (counter_rPLL == (CLK_FREQ * 54'd1_000_000 - 1)) begin
        counter_rPLL <= 0;
    end else begin
        counter_rPLL <= counter_rPLL + 1;
    end
end

// Letter incrementer
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        letter <= 8'd0; // Start with 'A'
    end else if (counter_main == (CLK_FREQ * 27'd1_000_000 - 1)) begin
        if (letter == 25) // If 'Z', wrap around to 'A'
            letter <= 8'd0;
        else
            letter <= letter + 8'd1;
    end
end

// UART transmission logic
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        char_index <= 4'd0;
        tx_data_valid <= 1'b0;
        sending <= 1'b0;
        tx_data <= 8'd0;
    end else begin
        if (counter_main == 0 && !sending) begin
            sending <= 1'b1;
            char_index <= 4'd0;
        end

        if (sending) begin
            if (tx_data_ready && !tx_data_valid) begin
                if (char_index < MESSAGE_LEN) begin
                    if (source_select) begin
                        // Use ROM data
                        tx_data <= rom_data;
                    end else begin
                        // Use original message buffer
                        if (char_index == 4'd12) begin
                            tx_data <= 8'h41 + letter;
                        end else begin
                            tx_data <= message_buf[8*(MESSAGE_LEN-1 - char_index) +: 8];
                        end
                    end
                    tx_data_valid <= 1'b1;
                end else begin
                    sending <= 1'b0;
                    char_index <= 4'd0;
                end
            end else begin
                tx_data_valid <= 1'b0;
                if (tx_data_ready && tx_data_valid) begin
                    char_index <= char_index + 4'd1;
                end
            end
        end else begin
            tx_data_valid <= 1'b0;
        end
    end
end

// Combinatorial logic
assign Voltage = !rst_n;
assign PLL_ok = freq_low;

endmodule