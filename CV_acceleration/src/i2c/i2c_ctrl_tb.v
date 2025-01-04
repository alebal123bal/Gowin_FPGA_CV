`timescale 1ns/1ps

module i2c_ctrl_tb;
    // Clock and reset signals
    reg sys_clk;
    reg sys_rst_n;
    
    // Control signals
    reg wr_en;
    reg rd_en;
    reg i2c_start;
    reg addr_num;
    reg [15:0] byte_addr;
    reg [7:0] wr_data;
    
    // Output signals
    wire i2c_clk;
    wire i2c_end;
    wire [7:0] rd_data;
    wire i2c_scl;
    wire i2c_sda;
    
    // Slave behavior signals
    reg sda_slave;
    reg [7:0] slave_memory [0:255]; // Slave device memory
    reg [7:0] received_addr;
    reg [7:0] received_data;
    integer bit_count;
    reg is_reading;

    // Bidirectional SDA with pull-up behavior
    wire sda_out;
    assign i2c_sda = (sda_slave === 1'b0 || sda_out === 1'b0) ? 1'b0 : 1'bz;

    // DUT instantiation
    i2c_ctrl #(
        .DEVICE_ADDR(7'b111_1000),
        .SYS_CLK_FREQ(26'd50_000_000),
        .SCL_FREQ(18'd250_000)
    ) dut (
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .i2c_start(i2c_start),
        .addr_num(addr_num),
        .byte_addr(byte_addr),
        .wr_data(wr_data),
        .i2c_clk(i2c_clk),
        .i2c_end(i2c_end),
        .rd_data(rd_data),
        .i2c_scl(i2c_scl),
        .i2c_sda(i2c_sda)
    );

    // Clock generation - 50MHz
    initial begin
        sys_clk = 0;
        forever #10 sys_clk = ~sys_clk;
    end

    // Track state transitions for ACK timing
    reg [3:0] prev_state;
    always @(posedge i2c_clk) begin
        prev_state <= dut.state;
    end

    // Slave behavior with immediate ACK response
    always @(*) begin
        case (dut.state)
            dut.ACK_1, dut.ACK_2, dut.ACK_3, dut.ACK_4, dut.ACK_5: begin
                sda_slave = 1'b0; // Immediate ACK
            end
            
            dut.RD_DATA: begin
                if (is_reading) begin
                    sda_slave = (slave_memory[byte_addr] >> (7 - bit_count)) & 1'b1;
                end else begin
                    sda_slave = 1'bz;
                end
            end
            
            default: begin
                sda_slave = 1'bz;
            end
        endcase
    end

    // Bit counter for read operations
    always @(negedge i2c_scl) begin
        if (!sys_rst_n) begin
            bit_count = 0;
            is_reading = 0;
        end else if (dut.state == dut.SEND_D_ADDR && bit_count == 7) begin
            is_reading = received_addr[0];
            bit_count = 0;
        end else if (dut.state == dut.RD_DATA) begin
            bit_count = (bit_count + 1) % 8;
        end
    end

    // Debug counter (1 to 9)
    reg [3:0] debug_counter;
    reg counter_enable;
    
    // Counter enable logic - starts at first negedge of i2c_scl
    always @(negedge i2c_scl or negedge sys_rst_n) begin
        if (!sys_rst_n)
            counter_enable <= 1'b0;
        else if (dut.state == dut.START_1)
            counter_enable <= 1'b1;
        else if (dut.state == dut.IDLE)
            counter_enable <= 1'b0;
    end

    // Debug counter
    always @(negedge i2c_scl or negedge sys_rst_n) begin
        if (!sys_rst_n)
            debug_counter <= 4'd1;
        else if (counter_enable) begin
            if (debug_counter == 4'd9 || debug_counter == 4'd0)
                debug_counter <= 4'd1;
            else
                debug_counter <= debug_counter + 4'd1;
        end
        else
            debug_counter <= 4'd1;
    end


    // Initialize slave memory
    initial begin
        for (integer i = 0; i < 256; i = i + 1)
            slave_memory[i] = i;
    end

    // Test sequence
    initial begin
        // Initialize signals
        sys_rst_n = 0;
        wr_en = 0;
        rd_en = 0;
        i2c_start = 0;
        addr_num = 1'b1;
        byte_addr = 16'h0000;
        wr_data = 8'h00;
        bit_count = 0;
        is_reading = 0;

        // Reset sequence
        #100;
        sys_rst_n = 1;
        #100;

        // Write sequence
        @(posedge sys_clk);
        wr_en = 1;
        rd_en = 0;
        i2c_start = 1;
        addr_num = 1'b1;
        byte_addr = 16'hFFFF;
        wr_data = 8'hAA;

        // Wait for completion
        wait(i2c_end);
        @(posedge sys_clk);
        i2c_start = 0;
        wr_en = 0;

        // Delay between operations
        #2000;

        // Read sequence
        @(posedge sys_clk);
        wr_en = 0;
        rd_en = 1;
        i2c_start = 1;
        addr_num = 1'b1;
        byte_addr = 16'hFFFF;

        // Wait for completion
        wait(i2c_end);
        @(posedge sys_clk);
        i2c_start = 0;
        rd_en = 0;

        // Add delay to observe results
        #5000;

        $display("Test completed");
        $finish;
    end

    // Monitor block for debugging
    initial begin
        $monitor("Time=%0t state=%d scl=%b sda=%b sda_slave=%b end=%b data=%h",
                 $time, dut.state, i2c_scl, i2c_sda, sda_slave, i2c_end, rd_data);
    end

endmodule