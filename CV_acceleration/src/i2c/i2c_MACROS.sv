// I2C Protocol Checker Macros

// Start condition: Pull down sda while i2c clock is high
`define CHECK_START(sda, scl) \
    $fell(sda) && (scl === 1'b1)

// Stop condition: Release sda (gets pulled up) while i2c clock is high
`define CHECK_STOP(sda, scl) \
    $rose(sda) && (scl === 1'b1)

`define DECODE_I2C_ADDR(byte) \
    $display("I2C Address: 0x%h (7-bit)", byte >> 1)

`define DECODE_I2C_RW(byte) \
    $display("R/W bit: %s", (byte & 1) ? "Read" : "Write")

`define CHECK_ACK(sda) \
    $display("ACK status: %s", sda ? "NACK" : "ACK")