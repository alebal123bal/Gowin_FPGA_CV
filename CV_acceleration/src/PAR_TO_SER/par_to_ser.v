module par_to_ser (
    input wire clk_5x,          // Input clock running at 5x the data rate
    input wire rst_n,           // Active-low reset
    input wire [9:0] par_data,  // Input 10-bit parallel data

    output wire ser_data_p,     // Positive differential serial output
    output wire ser_data_n      // Negative differential serial output
);

    ///
    // **Parameter and Internal Signals**
    ///
    // Extract rising and falling edge data from the parallel input
    wire [4:0] data_rise = {par_data[8], par_data[6], par_data[4], par_data[2], par_data[0]};
    wire [4:0] data_fall = {par_data[9], par_data[7], par_data[5], par_data[3], par_data[1]};

    // Registers for shift operations
    reg [4:0] data_rise_s = 0;  // Shift register for rising edge data
    reg [4:0] data_fall_s = 0;  // Shift register for falling edge data
    reg [2:0] cnt = 0;          // 3-bit counter for tracking the serialization process

    ///
    // **Serialization Logic**
    ///
    always @(posedge clk_5x or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 3'd0;
            data_rise_s <= 5'd0;
            data_fall_s <= 5'd0;
        end else begin
            // Reset the counter after 5 cycles (to serialize 5 bits)
            cnt <= (cnt[2]) ? 3'd0 : cnt + 3'd1;

            // Shift the data for rising and falling edges
            data_rise_s <= cnt[2] ? data_rise : data_rise_s[4:1];
            data_fall_s <= cnt[2] ? data_fall : data_fall_s[4:1];
        end
    end

    ///
    // **Instantiate DDR Output Buffers**
    ///
    // Differential Serial Data Output (Positive)
    ddio_out ddio_out_inst0 (
        .clk(~clk_5x),                // Clock input
        .rst_n(rst_n),               // Active-low reset
        .data_r(data_rise_s[0]),     // LSB of rising edge shift register
        .data_f(data_fall_s[0]),     // LSB of falling edge shift register
        .dout(ser_data_p)            // Positive serial output
    );

    // Differential Serial Data Output (Negative)
    ddio_out ddio_out_inst1 (
        .clk(~clk_5x),                // Clock input
        .rst_n(rst_n),               // Active-low reset
        .data_r(~data_rise_s[0]),    // Inverted LSB of rising edge shift register
        .data_f(~data_fall_s[0]),    // Inverted LSB of falling edge shift register
        .dout(ser_data_n)            // Negative serial output
    );

endmodule