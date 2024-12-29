module hdmi_ctrl (
    input wire clk_1x,         // Input system clock (1x frequency)
    input wire clk_5x,         // Input 5x system clock
    input wire sys_rst_n,      // Reset signal, active-low
    input wire [7:0] rgb_blue, // 8-bit blue color component
    input wire [7:0] rgb_green,// 8-bit green color component
    input wire [7:0] rgb_red,  // 8-bit red color component
    input wire hsync,          // Horizontal sync signal
    input wire vsync,          // Vertical sync signal
    input wire de,             // Data enable signal

    output wire hdmi_clk_p,    // HDMI differential clock positive signal
    output wire hdmi_clk_n,    // HDMI differential clock negative signal
    output wire hdmi_r_p,      // HDMI differential red positive signal
    output wire hdmi_r_n,      // HDMI differential red negative signal
    output wire hdmi_g_p,      // HDMI differential green positive signal
    output wire hdmi_g_n,      // HDMI differential green negative signal
    output wire hdmi_b_p,      // HDMI differential blue positive signal
    output wire hdmi_b_n       // HDMI differential blue negative signal
);

    ///
    // **Internal Signals**
    ///
    wire [9:0] red;    // 10-bit encoded red color component
    wire [9:0] green;  // 10-bit encoded green color component
    wire [9:0] blue;   // 10-bit encoded blue color component

    ///
    // **Module Instantiations**
    ///

    // **Encoding Blue (8b to 10b)**
    HDMI_8b_10b_encoding encode_inst0 (
        .sys_clk(clk_1x),       // System clock
        .sys_rst_n(sys_rst_n),  // Active-low reset
        .data_in(rgb_blue),     // 8-bit blue input
        .c0(hsync),             // Horizontal sync signal
        .c1(vsync),             // Vertical sync signal
        .de(de),                // Data enable signal
        .data_out(blue)         // 10-bit encoded blue output
    );

    // **Encoding Green (8b to 10b)**
    HDMI_8b_10b_encoding encode_inst1 (
        .sys_clk(clk_1x),       // System clock
        .sys_rst_n(sys_rst_n),  // Active-low reset
        .data_in(rgb_green),    // 8-bit green input
        .c0(hsync),             // Horizontal sync signal
        .c1(vsync),             // Vertical sync signal
        .de(de),                // Data enable signal
        .data_out(green)        // 10-bit encoded green output
    );

    // **Encoding Red (8b to 10b)**
    HDMI_8b_10b_encoding encode_inst2 (
        .sys_clk(clk_1x),       // System clock
        .sys_rst_n(sys_rst_n),  // Active-low reset
        .data_in(rgb_red),      // 8-bit red input
        .c0(hsync),             // Horizontal sync signal
        .c1(vsync),             // Vertical sync signal
        .de(de),                // Data enable signal
        .data_out(red)          // 10-bit encoded red output
    );

    // **Serialization for Blue Channel**
    par_to_ser par_to_ser_inst0 (
        .clk_5x(clk_5x),        // 5x system clock
        .par_data(blue),        // 10-bit encoded blue input
        .ser_data_p(hdmi_b_p),  // HDMI blue positive output
        .ser_data_n(hdmi_b_n)   // HDMI blue negative output
    );

    // **Serialization for Green Channel**
    par_to_ser par_to_ser_inst1 (
        .clk_5x(clk_5x),        // 5x system clock
        .par_data(green),       // 10-bit encoded green input
        .ser_data_p(hdmi_g_p),  // HDMI green positive output
        .ser_data_n(hdmi_g_n)   // HDMI green negative output
    );

    // **Serialization for Red Channel**
    par_to_ser par_to_ser_inst2 (
        .clk_5x(clk_5x),        // 5x system clock
        .par_data(red),         // 10-bit encoded red input
        .ser_data_p(hdmi_r_p),  // HDMI red positive output
        .ser_data_n(hdmi_r_n)   // HDMI red negative output
    );

    // **Serialization for Clock Channel**
    par_to_ser par_to_ser_inst3 (
        .clk_5x(clk_5x),        // 5x system clock
        .par_data(10'b1111100000), // Fixed clock pattern
        .ser_data_p(hdmi_clk_p),// HDMI clock positive output
        .ser_data_n(hdmi_clk_n) // HDMI clock negative output
    );

endmodule