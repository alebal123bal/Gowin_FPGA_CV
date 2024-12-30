module testpattern
(
    input              I_pxl_clk   ,
    input              I_rst_n     ,
    input      [11:0]  I_h_total   ,
    input      [11:0]  I_h_sync    ,
    input      [11:0]  I_h_bporch  ,
    input      [11:0]  I_h_res     ,
    input      [11:0]  I_v_total   ,
    input      [11:0]  I_v_sync    ,
    input      [11:0]  I_v_bporch  ,
    input      [11:0]  I_v_res     ,
    input              I_hs_pol    ,
    input              I_vs_pol    ,
    output             O_de        ,
    output reg         O_hs        ,
    output reg         O_vs        ,
    output reg [7:0]   O_data_r    ,
    output reg [7:0]   O_data_g    ,
    output reg [7:0]   O_data_b    
);

reg  [11:0]   V_cnt;
reg  [11:0]   H_cnt;
wire          Pout_de_w;
wire          Pout_hs_w;
wire          Pout_vs_w;

// Frame and color control
reg [4:0]     frame_count;
reg           vs_prev;
reg [7:0]     color_value;
reg           direction;

// Horizontal counter
always @(posedge I_pxl_clk or negedge I_rst_n) begin
    if (!I_rst_n)
        H_cnt <= 12'd0;
    else if (H_cnt >= (I_h_total - 1'b1))
        H_cnt <= 12'd0;
    else
        H_cnt <= H_cnt + 1'b1;
end

// Vertical counter
always @(posedge I_pxl_clk or negedge I_rst_n) begin
    if (!I_rst_n)
        V_cnt <= 12'd0;
    else if ((V_cnt >= (I_v_total - 1'b1)) && (H_cnt >= (I_h_total - 1'b1)))
        V_cnt <= 12'd0;
    else if (H_cnt >= (I_h_total - 1'b1))
        V_cnt <= V_cnt + 1'b1;
end

// Generate sync signals
assign Pout_de_w = ((H_cnt >= (I_h_sync + I_h_bporch)) && 
                    (H_cnt <= (I_h_sync + I_h_bporch + I_h_res - 1'b1))) &&
                   ((V_cnt >= (I_v_sync + I_v_bporch)) &&
                    (V_cnt <= (I_v_sync + I_v_bporch + I_v_res - 1'b1)));
assign Pout_hs_w = ~((H_cnt >= 12'd0) && (H_cnt <= (I_h_sync - 1'b1)));
assign Pout_vs_w = ~((V_cnt >= 12'd0) && (V_cnt <= (I_v_sync - 1'b1)));

always @(posedge I_pxl_clk or negedge I_rst_n) begin
    if (!I_rst_n) begin
        O_hs <= 1'b1;
        O_vs <= 1'b1;
    end else begin
        O_hs <= I_hs_pol ? ~Pout_hs_w : Pout_hs_w;
        O_vs <= I_vs_pol ? ~Pout_vs_w : Pout_vs_w;
    end
end

assign O_de = Pout_de_w;

// Frame detection and color fade control
always @(posedge I_pxl_clk or negedge I_rst_n) begin
    if (!I_rst_n) begin
        vs_prev <= 1'b0;
        frame_count <= 5'd0;
        color_value <= 8'd0;
        direction <= 1'b0;
    end else begin
        vs_prev <= O_vs;
        
        // Detect frame transition on VS falling edge
        if (vs_prev && !O_vs) begin
            if (frame_count == 5'd29) begin
                frame_count <= 5'd0;
                direction <= ~direction;
            end else begin
                frame_count <= frame_count + 1'b1;
            end
            
            // Update color value
            if (!direction)
                color_value <= frame_count * (8'd255 / 5'd29);
            else
                color_value <= 8'd255 - (frame_count * (8'd255 / 5'd29));
        end
    end
end

// Output color assignment
always @(posedge I_pxl_clk or negedge I_rst_n) begin
    if (!I_rst_n) begin
        O_data_r <= 8'd0;
        O_data_g <= 8'd255;
        O_data_b <= 8'd0;
    end else if (Pout_de_w) begin
        O_data_r <= color_value;
        O_data_g <= 8'd255 - color_value;
        O_data_b <= 8'd0;
    end else begin
        O_data_r <= 8'd0;
        O_data_g <= 8'd0;
        O_data_b <= 8'd0;
    end
end

endmodule