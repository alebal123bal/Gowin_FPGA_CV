module tb_ddio_out;

    // Testbench signals
    reg clk;
    reg rst_n;
    reg data_r;         // Input for rising edge
    reg data_f;         // Input for falling edge
    wire dout;          // DDR serialized output

    // Instantiate the ddio_out module
    ddio_out uut (
        .clk(clk),
        .rst_n(rst_n),
        .data_r(data_r),
        .data_f(data_f),
        .dout(dout)
    );

    // Clock generation (50 MHz clock, 20 ns period)
    initial begin
        clk = 0;
        forever #10 clk = ~clk; // Toggle every 10 ns
    end

    // Stimulus
    initial begin
        // Initialize inputs
        rst_n = 0;
        data_r = 0;
        data_f = 0;

        // Release reset
        #20 rst_n = 1;

        // Apply test data
        #20 data_r = 1; data_f = 0; // Rising edge -> 1, Falling edge -> 0
        #20 data_r = 0; data_f = 1; // Rising edge -> 0, Falling edge -> 1
        #20 data_r = 1; data_f = 1; // Rising edge -> 1, Falling edge -> 1
        #20 data_r = 0; data_f = 0; // Rising edge -> 0, Falling edge -> 0

        // Stop simulation
        #100 $stop;
    end

endmodule