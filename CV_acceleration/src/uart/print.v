module print_module (
    input wire print_clk,
    output wire uart_txp
);
    // Parameters
    parameter STR = 0;
    parameter HEX = 1;

    // Registers and Wires
    reg [7:0] print_seq[255:0];
    reg [7:0] seq_head = 8'd0;
    reg [7:0] seq_tail = 8'd0;

    reg [1023:0] print_buffer = 1024'h0;
    reg [6:0] print_buffer_pointer = 7'd0;

    reg last_spin_state = 0;
    reg spin_state = 0;
    reg [6:0] print_length;
    reg print_type;

    parameter PRINT_IDLE_STATE = 0;
    parameter PRINT_WAIT_STATE = 1;
    parameter PRINT_WORK_STATE = 2;
    parameter PRINT_CONV_STATE = 3;
    reg [1:0] print_state = PRINT_IDLE_STATE;

    reg [7:0] hex_lib [0:15];
    initial begin
        hex_lib[4'h0] = 8'h30;
        hex_lib[4'h1] = 8'h31;
        hex_lib[4'h2] = 8'h32;
        hex_lib[4'h3] = 8'h33;
        hex_lib[4'h4] = 8'h34;
        hex_lib[4'h5] = 8'h35;
        hex_lib[4'h6] = 8'h36;
        hex_lib[4'h7] = 8'h37;
        hex_lib[4'h8] = 8'h38;
        hex_lib[4'h9] = 8'h39;
        hex_lib[4'hA] = 8'h61;
        hex_lib[4'hB] = 8'h62;
        hex_lib[4'hC] = 8'h63;
        hex_lib[4'hD] = 8'h64;
        hex_lib[4'hE] = 8'h65;
        hex_lib[4'hF] = 8'h66;
    end

    // State Machine for Print Task
    always @(posedge print_clk) begin
        last_spin_state <= spin_state;

        case (print_state)
            PRINT_IDLE_STATE: begin
                if (spin_state != last_spin_state) begin
                    print_state <= PRINT_WAIT_STATE;
                end
            end
            PRINT_WAIT_STATE: begin
                print_state <= PRINT_WORK_STATE;
                print_buffer_pointer <= (print_type == STR) ? 7'd127 : 7'd127;
            end
            PRINT_WORK_STATE: begin
                if (print_type == STR) begin
                    if (print_buffer[print_buffer_pointer * 8 + 7 -: 8] != 8'd0) begin
                        print_seq[seq_tail] <= print_buffer[print_buffer_pointer * 8 + 7 -: 8];
                        seq_tail <= seq_tail + 8'd1;
                    end else begin
                        print_state <= PRINT_IDLE_STATE;
                    end

                    print_buffer_pointer <= print_buffer_pointer - 7'd1;

                    if (print_buffer_pointer == 7'd0) begin
                        print_state <= PRINT_IDLE_STATE;
                    end
                end else begin
                    print_seq[seq_tail] <= hex_lib[print_buffer[print_buffer_pointer * 8 + 7 -: 4]];
                    seq_tail <= seq_tail + 8'd1;
                    print_state <= PRINT_CONV_STATE;
                end
            end
            PRINT_CONV_STATE: begin
                print_seq[seq_tail] <= hex_lib[print_buffer[print_buffer_pointer * 8 + 3 -: 4]];
                seq_tail <= seq_tail + 8'd1;
                print_state <= PRINT_WORK_STATE;

                print_buffer_pointer <= print_buffer_pointer - 7'd1;

                if (print_buffer_pointer == print_length) begin
                    print_state <= PRINT_IDLE_STATE;
                end
            end
        endcase
    end

    reg uart_en;
    wire uart_bz;
    uart_tx_V2 tx(print_clk, print_seq[seq_head], uart_en, uart_bz, uart_txp);

    // UART Data Transmission
    always @(posedge print_clk) begin
        uart_en <= 1'b0;
        if (uart_en && uart_bz) begin
            seq_head <= seq_head + 8'd1;
        end
        if (seq_head != seq_tail && !uart_bz) begin
            uart_en <= 1'b1;
        end
    end

    // Print Task
    task int_print(
        input [1023:0] strin,   // Max 128 characters
        input [7:0] type_length // 8-bit width to show 128 characters
    );
    begin
        if (print_state == PRINT_IDLE_STATE) begin
            spin_state <= ~spin_state;

            if (type_length == STR) begin
                print_type <= STR;
            end else begin
                print_type <= HEX;
                print_length <= 8'd128 - type_length;
            end

            print_buffer <= strin;
        end
    end
    endtask

    `define print(a, b) int_print(a, b)

endmodule