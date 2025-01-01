`timescale 1ns / 1ps

module tb_i2c_lut;

    // Clock and reset signals
    reg clk;
    reg rst_n;

    // I2C signals (bidirectional)
    wire i2c_scl;
    wire i2c_sda;

    // LUT signals
    wire [9:0] lut_index;
    wire [31:0] lut_data;

    // Flags for configuration state
    wire done_reg_config;
    wire err_reg_config;

    // Internal variables for monitoring
    integer i;

    // Generate clock signal
    initial begin
        clk = 0;
        forever #10 clk = ~clk; // 50MHz clock
    end

    // Generate reset signal
    initial begin
        rst_n = 0;
        #100 rst_n = 1; // Release reset after 100ns
    end

    // Instantiate the LUT module
    lut_ov5640_rgb565_1280_720 uut_lut (
        .lut_index(lut_index),
        .lut_data(lut_data)
    );

    // Instantiate the I2C configuration module
    i2c_config uut_i2c (
        .rst(~rst_n),
        .clk(clk),
        .clk_div_cnt(16'd500),  // Adjust as needed for proper I2C timing
        .i2c_addr_2byte(1'b1), // OV5640 uses 2-byte register addresses
        .lut_index(lut_index),
        .lut_dev_addr(lut_data[31:24]),
        .lut_reg_addr(lut_data[23:8]),
        .lut_reg_data(lut_data[7:0]),
        .error(err_reg_config),
        .done(done_reg_config),
        .i2c_scl(i2c_scl),
        .i2c_sda(i2c_sda)
    );

    // Pull-up resistors for I2C lines
    pullup(i2c_scl);
    pullup(i2c_sda);

    // Monitor signals
    initial begin
        $display("Time\t\tlut_index\tlut_data\t\tdone\t\terror");
        $monitor("%0dns\t%d\t\t%h\t%b\t%b",
                 $time, lut_index, lut_data, done_reg_config, err_reg_config);
    end

    // Test the configuration process
    initial begin
        // Wait for reset deassertion
        wait(rst_n == 1);

        // Wait for the configuration process to complete
        wait(done_reg_config == 1);

        // Check for errors
        if (err_reg_config == 1) begin
            $display("I2C configuration failed!");
        end else begin
            $display("I2C configuration completed successfully!");
        end

        // End simulation
        #1000;
        $finish;
    end

endmodule