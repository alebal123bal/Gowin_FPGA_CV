module green_screen_gen (
    input wire clk_27,         // 27MHz clock
    input wire rst_n,          // Active low reset
    
    output reg [7:0] rgb_red,
    output reg [7:0] rgb_green,
    output reg [7:0] rgb_blue,
    output reg hsync,
    output reg vsync,
    output reg de
);

    // Timing parameters for 800x600 at 60 Hz
    parameter H_ACTIVE = 800;  // Active video width
    parameter H_FRONT  = 40;   // Horizontal front porch
    parameter H_SYNC   = 128;  // Horizontal sync pulse width
    parameter H_BACK   = 88;   // Horizontal back porch
    parameter H_TOTAL  = 1056; // Total horizontal pixels (800 + 40 + 128 + 88)

    parameter V_ACTIVE = 600;  // Active video height
    parameter V_FRONT  = 1;    // Vertical front porch
    parameter V_SYNC   = 4;    // Vertical sync pulse width
    parameter V_BACK   = 23;   // Vertical back porch
    parameter V_TOTAL  = 628;  // Total vertical lines (600 + 1 + 4 + 23)

    // Horizontal and vertical counters
    reg [11:0] h_count;        // Horizontal pixel counter
    reg [11:0] v_count;        // Vertical line counter

    // Horizontal and vertical counter logic
    always @(posedge clk_27 or negedge rst_n) begin
        if (!rst_n) begin
            h_count <= 12'd0;
            v_count <= 12'd0;
        end else begin
            if (h_count == H_TOTAL - 1) begin
                h_count <= 12'd0;
                if (v_count == V_TOTAL - 1)
                    v_count <= 12'd0;
                else
                    v_count <= v_count + 12'd1;
            end else
                h_count <= h_count + 12'd1;
        end
    end

    // Generate sync signals and data enable
    always @(posedge clk_27 or negedge rst_n) begin
        if (!rst_n) begin
            hsync <= 1'b1;      // Horizontal sync (default high)
            vsync <= 1'b1;      // Vertical sync (default high)
            de <= 1'b0;         // Data enable (default low)
            rgb_red <= 8'd0;    // Default red color
            rgb_green <= 8'd0;  // Default green color
            rgb_blue <= 8'd0;   // Default blue color
        end else begin
            // Horizontal sync generation (negative polarity for 800x600 at 60 Hz)
            hsync <= ~((h_count >= (H_ACTIVE + H_FRONT)) && 
                       (h_count < (H_ACTIVE + H_FRONT + H_SYNC)));
            
            // Vertical sync generation (negative polarity for 800x600 at 60 Hz)
            vsync <= ~((v_count >= (V_ACTIVE + V_FRONT)) && 
                       (v_count < (V_ACTIVE + V_FRONT + V_SYNC)));
            
            // Data enable generation (active during active video area)
            de <= (h_count < H_ACTIVE) && (v_count < V_ACTIVE);

            // Generate full green color when in active video area
            if ((h_count < H_ACTIVE) && (v_count < V_ACTIVE)) begin
                rgb_red <= 8'd0;       // No red
                rgb_green <= 8'd255;   // Full green
                rgb_blue <= 8'd0;      // No blue
            end else begin
                rgb_red <= 8'd0;       // No color outside active area
                rgb_green <= 8'd0;
                rgb_blue <= 8'd0;
            end
        end
    end

endmodule