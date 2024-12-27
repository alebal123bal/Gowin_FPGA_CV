module ddio_out (
    input wire clk,         // Clock input
    input wire rst_n,       // Active-low reset
    input wire data_r,      // Data for rising edge (1-bit)
    input wire data_f,      // Data for falling edge (1-bit)
    output reg dout         // DDR serialized output
);

    // Internal registers for edge data
    reg data_r_reg;         // Rising edge data register
    reg data_f_reg;         // Falling edge data register

    // Latch rising edge data on the clock's rising edge
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_r_reg <= 1'b0; // Reset to 0
        else
            data_r_reg <= data_r; // Capture rising edge data
    end

    // Latch falling edge data on the clock's falling edge
    always @(negedge clk or negedge rst_n) begin
        if (!rst_n)
            data_f_reg <= 1'b0; // Reset to 0
        else
            data_f_reg <= data_f; // Capture falling edge data
    end

    // Output data on both edges of the clock
    always @(posedge clk or negedge clk) begin
        if (clk)
            dout <= data_r_reg; // Output rising edge data
        else
            dout <= data_f_reg; // Output falling edge data
    end

endmodule