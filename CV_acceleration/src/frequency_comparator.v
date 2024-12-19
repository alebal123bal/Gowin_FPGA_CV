module frequency_comparator #(
    parameter EXPECTED_FREQ = 54_000_000,  // 54 MHz in Hz
    parameter TOLERANCE_PERCENT = 1         // 1% tolerance
)(
    input wire clk,              // System clock
    input wire rst_n,            // Active low reset
    input wire [31:0] measured_freq,  // Measured frequency value
    input wire new_data_valid,   // Pulses high when new frequency data is valid
    
    output reg freq_match,       // High when frequency is within tolerance
    output reg freq_too_high,    // High when frequency is above tolerance
    output reg freq_too_low      // High when frequency is below tolerance
);

    // Calculate tolerance range
    localparam TOLERANCE = (EXPECTED_FREQ * TOLERANCE_PERCENT) / 100;
    localparam FREQ_MIN = EXPECTED_FREQ - TOLERANCE;
    localparam FREQ_MAX = EXPECTED_FREQ + TOLERANCE;

    // Comparison logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            freq_match <= 1'b0;
            freq_too_high <= 1'b0;
            freq_too_low <= 1'b0;
        end else if (new_data_valid) begin
            if (measured_freq >= FREQ_MIN && measured_freq <= FREQ_MAX) begin
                freq_match <= 1'b1;
                freq_too_high <= 1'b0;
                freq_too_low <= 1'b0;
            end else if (measured_freq > FREQ_MAX) begin
                freq_match <= 1'b0;
                freq_too_high <= 1'b1;
                freq_too_low <= 1'b0;
            end else begin // measured_freq < FREQ_MIN
                freq_match <= 1'b0;
                freq_too_high <= 1'b0;
                freq_too_low <= 1'b1;
            end
        end
    end

endmodule