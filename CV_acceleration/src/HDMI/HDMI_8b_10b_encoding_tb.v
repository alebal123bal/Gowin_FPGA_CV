`timescale 1ns / 1ps

module HDMI_8b_10b_encoding_tb;

    // Inputs
    reg sys_clk;
    reg sys_rst_n;
    reg [7:0] data_in;
    reg c0;
    reg c1;
    reg de;

    // Outputs
    wire [9:0] data_out;
    wire [9:0] data_out_orig;

    // Loop vars
    integer i;
    integer N_SAMPLES = 20;


    // Instantiate the DUT (Device Under Test)
    HDMI_8b_10b_encoding uut (
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),
        .data_in(data_in),
        .c0(c0),
        .c1(c1),
        .de(de),
        .data_out(data_out)
    );

    // Instantiate original IP for cross check validation
    encode uut_orig (
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),
        .data_in(data_in),
        .c0(c0),
        .c1(c1),
        .de(de),
        .data_out(data_out_orig)
    );


    // Clock generation (50 MHz, period = 20 ns)
    initial sys_clk = 0;
    always #10 sys_clk = ~sys_clk;

    // Test sequence for speicific validation
    initial begin
        // Initialize inputs
        sys_rst_n = 0;     // Reset is active
        data_in = 8'b0;    // Input data starts at 0
        c0 = 1'b1;
        c1 = 1'b1;
        de = 1'b0;         // Initially disabled

        // Wait for reset to finish
        #50;
        sys_rst_n = 1;     // Release reset
        de = 1;            // Enable the module

        // Apply test input
        data_in = 8'b01010101;  // Input sequence
        #100;                   // Wait for more clock cycles (output stabilizes after 2 of them)
        
        // Check output
        if (data_out == 10'b1001100110) begin
            $display("PASS: output is correct.");
        end else begin
            $display("FAIL: expected 1001100110, got %b", data_out);
        end

        // Loop many random samples
        for (i = 0; i < N_SAMPLES; i = i + 1) begin
            data_in = $random % 256;    // Get the 8 LSBs of the random value
            #40;                        // Wait for the 2 necessary clk cycles
            if (data_out == data_out_orig) begin
                $display("PASS: With random %b the 2 outputs are the same.", data_in);
            end else begin
                $display("FAIL: random %b the 2 outputs are not the same.", data_in);
            end
        end 

        // End the simulation
        #20;
        $stop;
    end

endmodule