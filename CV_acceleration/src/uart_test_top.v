`timescale 1ns / 1ps

module top_alternative (
    input clk,      // 27 MHz clock
    input rst_n,    // Active low reset
    output uart_tx, // UART TX pin
    output Voltage
);

// Parameters
parameter CLK_FREQ = 27;       // 27 MHz
parameter BAUD_RATE = 115200;  // 115200 bps
parameter MESSAGE_LEN = 15;    // Length of "Hello World x\r\n"

// Registers
reg [131:0] message_buf; // 15 characters * 8 bits = 120 bits (+ extra if needed)
reg [3:0] char_index;
reg [7:0] tx_data;
reg tx_data_valid;
reg [26:0] counter;  // Sufficient bits to count to ~27,000,000
reg [7:0] letter;    // 8 bits to represent A-Z (0-25)
reg sending;

// Wires
wire tx_data_ready;

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
    .tx_pin(uart_tx)  // Connected to the renamed output
);

// Synchronous Initialization of the Message Buffer
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Initialize static part of the message
        message_buf <= { "Hello World ", 8'h00, 8'h0D, 8'h0A }; // Reserve byte for 'x' at position 12
        // Alternatively, initialize to all zeros and set specific bytes if needed
    end else begin
        // No dynamic changes to the static message part
        // Only the 'x' character is dynamic and handled in transmission logic
    end
end

// 1-second counter
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        counter <= 0;
    end else if (counter == (CLK_FREQ * 27'd1_000_000 - 1)) begin // 27 MHz * 1s
        counter <= 0;
    end else begin
        counter <= counter + 1;
    end
end

// Letter incrementer
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        letter <= 8'd0;  // Start with 'A'
    end else if (counter == (CLK_FREQ * 27'd1_000_000 - 1)) begin
        if (letter == 25)  // If 'Z', wrap around to 'A'
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
    end else begin
        // Start sending at the beginning of each second
        if (counter == 0 && !sending) begin
            sending <= 1'b1;
            char_index <= 4'd0;
        end

        if (sending) begin
            if (tx_data_ready && !tx_data_valid) begin
                if (char_index < MESSAGE_LEN) begin
                    if (char_index == 4'd12) begin
                        tx_data <= 8'h41 + letter;  // 'A' is ASCII 65 (0x41)
                    end else begin
                        tx_data <= message_buf[8*(MESSAGE_LEN-1 - char_index) +: 8];
                        // Adjust slicing according to bit ordering
                    end
                    tx_data_valid <= 1'b1;
                end else begin
                    // Sending complete
                    sending <= 1'b0;
                    char_index <= 4'd0;
                end
            end else begin
                tx_data_valid <= 1'b0; // Ensure tx_data_valid is a pulse
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

endmodule