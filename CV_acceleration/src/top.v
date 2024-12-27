`timescale 1ns / 1ps

module top (
    input clk,          // 27 MHz clock
    input rst_n,        // Active low reset
    output uart_tx,     // UART TX pin
    output Voltage
);

// Parameters
parameter CLK_FREQ = 27;        // 27 MHz
parameter BAUD_RATE = 115200;   // 115200 bps

// Signals
wire clk_135_MHz;

// Registers
reg[31:0] counter_135_MHz;
reg Voltage_reg;

// Instantiate rPLL at 135MHz
Gowin_rPLL PLL_135_MHz(
    .clkout(clk_135_MHz), //output clkout
    .clkin(clk) //input clkin
);

// Quickly check if LED blinks every 1 second at 135MHz 
always @(posedge clk_135_MHz or negedge rst_n) begin
    if (!rst_n) begin
        counter_135_MHz <= 0;
        Voltage_reg <= 1'b0;
    end else begin
        if (counter_135_MHz == 135_000_000 - 1) begin
            counter_135_MHz <= 0;
            Voltage_reg <= ~Voltage_reg;
        end else begin
            counter_135_MHz <= counter_135_MHz + 1;
            Voltage_reg <= Voltage_reg;
        end
    end
end

// Combinatorial logic
assign Voltage = Voltage_reg;

endmodule