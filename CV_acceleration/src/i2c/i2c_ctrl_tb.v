`timescale 1ns / 1ps

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
  reg [7:0] slave_memory[0:255];  // Slave device memory
  reg [7:0] received_addr;
  reg [7:0] received_data;
  integer bit_count;
  reg is_reading;

  // Bidirectional SDA with pull-up behavior
  assign i2c_sda = sda_slave;  // If it is High Z, then Master takes control

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

  // Slave behavior with immediate ACK response
  always @(*) begin
    case (dut.state)
      dut.ACK_1, dut.ACK_2, dut.ACK_3, dut.ACK_4, dut.ACK_5: begin
        sda_slave = 1'b0;  // Immediate ACK
      end

      default: begin
        sda_slave = 1'bz;
      end
    endcase
  end

  // Bit counter for read operations
  always @(negedge i2c_scl) begin
    if (!sys_rst_n) begin
      bit_count  = 0;
      is_reading = 0;
    end else if (dut.state == dut.START_2) begin
      is_reading = 1;
      bit_count  = 0;
    end else if (dut.state == dut.RD_DATA) begin
      bit_count = (bit_count + 1) % 8;
    end
  end

  // Initialize slave memory
  initial begin
    for (integer i = 0; i < 256; i = i + 1) slave_memory[i] = i;
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
    wait (i2c_end);
    @(posedge sys_clk);
    i2c_start = 0;
    wr_en = 0;

    // Delay between operations
    #2000;

    $display("Test completed");
    $finish;
  end

  // Monitor block for debugging
  // initial begin
  //     $monitor("Time=%0t state=%d scl=%b sda=%b sda_slave=%b end=%b data=%h",
  //              $time, dut.state, i2c_scl, i2c_sda, sda_slave, i2c_end, rd_data);
  // end

  // Macros debugging
  always @(posedge i2c_clk) begin
    if (`CHECK_START(i2c_sda, i2c_scl)) begin
      $display("Time = %0t: START condition detected", $time);
    end
  end

  // Log complete transactions
  reg [3:0] prev_state;
  reg [7:0] current_byte;

  initial begin
    current_byte <= 8'h00;
    prev_state   <= 8'h0;
  end


  always @(posedge i2c_scl) begin
    // Only shift in bits when we're receiving valid data
    current_byte <= {current_byte[6:0], i2c_sda};

    prev_state   <= dut.state;

    // Detect when we're leaving a SEND state
    case (prev_state)
      dut.SEND_D_ADDR: begin
        if (dut.state == dut.ACK_1) begin
          `DECODE_I2C_ADDR(current_byte);
          `DECODE_I2C_RW(current_byte);
        end
      end
      dut.SEND_B_ADDR_H: begin
        if (dut.state == dut.ACK_2) $display("Byte Address High: 0x%h", current_byte);
      end
      dut.SEND_B_ADDR_L: begin
        if (dut.state == dut.ACK_3) $display("Byte Address Low: 0x%h", current_byte);
      end
      dut.WR_DATA: begin
        if (dut.state == dut.ACK_4) $display("Write Data: 0x%h", current_byte);
      end
      dut.SEND_RD_ADDR: begin
        if (dut.state == dut.ACK_5) $display("Read Address: 0x%h", current_byte);
      end
      dut.RD_DATA: begin
        if (dut.state == dut.N_ACK) $display("Read Data: 0x%h", current_byte);
      end
    endcase
  end


endmodule
