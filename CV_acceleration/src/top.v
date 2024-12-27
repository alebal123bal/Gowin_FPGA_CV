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


// Combinatorial logic
assign Voltage = !rst_n;

endmodule