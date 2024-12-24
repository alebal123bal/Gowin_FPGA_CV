// ============================================================
//
// This code is adapted from 野火FPGA Verilog开发实战指南
// Source: https://doc.embedfire.com/fpga/altera/ep4ce10_pro/zh/latest/code/hdmi.html
// © Copyright 2020, embedfire-野火
//
// Module: HDMI_8b_10b_encoding
// Description: This module implements an encoding mechanism that
//              converts an 8-bit input into a 10-bit encoded output.
//              It uses several control signals, including `de`, `c0`,
//              `c1`, and performs a two-stage encoding process. The
//              module also manages a disparity counter to ensure
//              balanced data encoding.
// 
// Inputs:
//  - sys_clk   : System clock signal
//  - sys_rst_n : Reset signal (active low)
//  - data_in   : 8-bit input data to be encoded
//  - c0        : Control signal c0
//  - c1        : Control signal c1
//  - de        : Enable signal
// 
// Outputs:
//  - data_out  : 10-bit encoded output data
// 
// Parameters:
//  - DATA_OUT0, DATA_OUT1, DATA_OUT2, DATA_OUT3: Predefined 10-bit
//    values for control signal outputs when `de` is not enabled.
// 
// Author: Alessandro Balzan
// Date: 12/24/2024
// ============================================================

module HDMI_8b_10b_encoding (
    input wire sys_clk,          // System clock signal
    input wire sys_rst_n,        // Reset signal, active low
    input wire [7:0] data_in,    // 8-bit input data to be encoded
    input wire c0,               // Control signal c0
    input wire c1,               // Control signal c1
    input wire de,               // Enable signal

    output reg [9:0] data_out    // 10-bit encoded output data
);

////
// \* Parameter and Internal Signal \//
////

// Parameter definitions
parameter DATA_OUT0 = 10'b1101010100,
          DATA_OUT1 = 10'b0010101011,
          DATA_OUT2 = 10'b0101010100,
          DATA_OUT3 = 10'b1010101011;

// Wire definitions
wire condition_1;       // Condition 1
wire condition_2;       // Condition 2
wire condition_3;       // Condition 3
wire [8:0] q_m;         // Intermediate 9-bit encoded data

// Register definitions
reg [3:0] data_in_n1;   // Number of 1s in the input data
reg [7:0] data_in_reg;  // Latched input data
reg [3:0] q_m_n1;       // Number of 1s in the intermediate encoded data
reg [3:0] q_m_n0;       // Number of 0s in the intermediate encoded data
reg [4:0] cnt;          // Disparity counter (difference of 1s and 0s)
reg de_reg1, de_reg2;   // Latched enable signals
reg c0_reg1, c0_reg2;   // Latched control signal c0
reg c1_reg1, c1_reg2;   // Latched control signal c1
reg [8:0] q_m_reg;      // Latched intermediate encoded data

////
// \* Main Code \//
////

// Count the number of 1s in the input data
always @(posedge sys_clk or negedge sys_rst_n)
    if (sys_rst_n == 1'b0)
        data_in_n1 <= 4'd0;
    else
        data_in_n1 <= data_in[0] + data_in[1] + data_in[2]
                    + data_in[3] + data_in[4] + data_in[5]
                    + data_in[6] + data_in[7];

// Latch the input data
always @(posedge sys_clk or negedge sys_rst_n)
    if (sys_rst_n == 1'b0)
        data_in_reg <= 8'b0;
    else
        data_in_reg <= data_in;

// Condition 1: Determines the encoding phase based on the number of 1s
assign condition_1 = ((data_in_n1 > 4'd4) || ((data_in_n1 == 4'd4) && (data_in_reg[0] == 1'b1)));

// First-stage encoding: Generate 9-bit intermediate data (q_m)
assign q_m[0] = data_in_reg[0];
assign q_m[1] = (condition_1) ? (q_m[0] ^~ data_in_reg[1]) : (q_m[0] ^ data_in_reg[1]);
assign q_m[2] = (condition_1) ? (q_m[1] ^~ data_in_reg[2]) : (q_m[1] ^ data_in_reg[2]);
assign q_m[3] = (condition_1) ? (q_m[2] ^~ data_in_reg[3]) : (q_m[2] ^ data_in_reg[3]);
assign q_m[4] = (condition_1) ? (q_m[3] ^~ data_in_reg[4]) : (q_m[3] ^ data_in_reg[4]);
assign q_m[5] = (condition_1) ? (q_m[4] ^~ data_in_reg[5]) : (q_m[4] ^ data_in_reg[5]);
assign q_m[6] = (condition_1) ? (q_m[5] ^~ data_in_reg[6]) : (q_m[5] ^ data_in_reg[6]);
assign q_m[7] = (condition_1) ? (q_m[6] ^~ data_in_reg[7]) : (q_m[6] ^ data_in_reg[7]);
assign q_m[8] = (condition_1) ? 1'b0 : 1'b1;

// Calculate the number of 1s and 0s in the intermediate data (q_m)
always @(posedge sys_clk or negedge sys_rst_n)
    if (sys_rst_n == 1'b0) begin
        q_m_n1 <= 4'd0;
        q_m_n0 <= 4'd0;
    end else begin
        q_m_n1 <= q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7];
        q_m_n0 <= 4'd8 - (q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7]);
    end

// Condition 2: Check for balanced intermediate data
assign condition_2 = ((cnt == 5'd0) || (q_m_n1 == q_m_n0));

// Condition 3: Check for disparity
assign condition_3 = (((~cnt[4] == 1'b1) && (q_m_n1 > q_m_n0)) ||
                      ((cnt[4] == 1'b1) && (q_m_n0 > q_m_n1)));

// Synchronize signals using flip-flops
always @(posedge sys_clk or negedge sys_rst_n)
    if (sys_rst_n == 1'b0) begin
        de_reg1 <= 1'b0;
        de_reg2 <= 1'b0;
        c0_reg1 <= 1'b0;
        c0_reg2 <= 1'b0;
        c1_reg1 <= 1'b0;
        c1_reg2 <= 1'b0;
        q_m_reg <= 9'b0;
    end else begin
        de_reg1 <= de;
        de_reg2 <= de_reg1;
        c0_reg1 <= c0;
        c0_reg2 <= c0_reg1;
        c1_reg1 <= c1;
        c1_reg2 <= c1_reg1;
        q_m_reg <= q_m;
    end

// Generate the final 10-bit encoded output and update the disparity counter
always @(posedge sys_clk or negedge sys_rst_n)
    if (sys_rst_n == 1'b0) begin
        data_out <= 10'b0;
        cnt <= 5'b0;
    end else begin
        if (de_reg2 == 1'b1) begin
            if (condition_2 == 1'b1) begin
                data_out[9] <= ~q_m_reg[8];
                data_out[8] <= q_m_reg[8];
                data_out[7:0] <= (q_m_reg[8]) ? q_m_reg[7:0] : ~q_m_reg[7:0];
                cnt <= (~q_m_reg[8]) ? (cnt + q_m_n0 - q_m_n1) : (cnt + q_m_n1 - q_m_n0);
            end else if (condition_3 == 1'b1) begin
                data_out[9] <= 1'b1;
                data_out[8] <= q_m_reg[8];
                data_out[7:0] <= ~q_m_reg[7:0];
                cnt <= cnt + {q_m_reg[8], 1'b0} + (q_m_n0 - q_m_n1);
            end else begin
                data_out[9] <= 1'b0;
                data_out[8] <= q_m_reg[8];
                data_out[7:0] <= q_m_reg[7:0];
                cnt <= cnt - {~q_m_reg[8], 1'b0} + (q_m_n1 - q_m_n0);
            end
        end else begin
            case ({c1_reg2, c0_reg2})
                2'b00: data_out <= DATA_OUT0;
                2'b01: data_out <= DATA_OUT1;
                2'b10: data_out <= DATA_OUT2;
                default: data_out <= DATA_OUT3;
            endcase
            cnt <= 5'b0;
        end
    end
endmodule