`timescale 1ns/1ps

module tb_par_to_ser;

    // Testbench Signals
    reg clk_5x;                // 5x clock signal
    reg rst_n;                 // Active-low reset
    reg [9:0] par_data;        // Parallel input data
    wire ser_data_p;           // Positive serial output
    wire ser_data_n;           // Negative serial output

    // Clock generation
    initial begin
        clk_5x = 0;
        forever #10 clk_5x = ~clk_5x;
    end

    // Instantiate the DUT (Device Under Test)
    par_to_ser uut (
        .clk_5x(clk_5x),
        .rst_n(rst_n),          // Connect reset
        .par_data(par_data),
        .ser_data_p(ser_data_p),
        .ser_data_n(ser_data_n)
    );

    // Test Sequence
    initial begin
        // Initialize signals
        rst_n = 0;             // Assert reset
        par_data = 10'b0;

        // Release reset after 5 ns
        #50 rst_n = 1;          // Deassert reset

        // Apply test data
        #20  par_data = 10'b11010_01100;  // Test case 1: Mixed bits
        // #50 par_data = 10'b11110_00001;  // Test case 2: Mostly high, one low
        // #50 par_data = 10'b00001_11110;  // Test case 3: Mostly low, one high
        // #50 par_data = 10'b10101_01010;  // Test case 4: Alternating bits
        // #50 par_data = 10'b11111_11111;  // Test case 5: All high
        // #50 par_data = 10'b00000_00000;  // Test case 6: All low

        // Finish simulation
        #200 $stop;
    end

    // Monitor outputs
    initial begin
        $monitor("Time: %0t | par_data: %b | ser_data_p: %b | ser_data_n: %b", 
                 $time, par_data, ser_data_p, ser_data_n);
    end

endmodule