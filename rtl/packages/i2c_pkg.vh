`ifndef I2C_PKG_VH
`define I2C_PKG_VH

//------------------------------------------------------------
// Parameters
//------------------------------------------------------------

`define I2C_DATA_WIDTH     8
`define I2C_ADDR_WIDTH     7
`define I2C_CLK_DIV_WIDTH  16

//------------------------------------------------------------
// FSM States
//------------------------------------------------------------

`define I2C_IDLE        4'd0
`define I2C_START       4'd1
`define I2C_ADDRESS     4'd2
`define I2C_ACK1        4'd3
`define I2C_WRITE       4'd4
`define I2C_READ        4'd5
`define I2C_ACK2        4'd6
`define I2C_STOP        4'd7
`define I2C_DONE        4'd8

//------------------------------------------------------------
// Register Map
//------------------------------------------------------------

`define I2C_CTRL_REG      8'h00
`define I2C_STATUS_REG    8'h04
`define I2C_ADDR_REG      8'h08
`define I2C_TX_REG        8'h0C
`define I2C_RX_REG        8'h10
`define I2C_CLKDIV_REG    8'h14

//------------------------------------------------------------
// Control Register
//------------------------------------------------------------

`define I2C_CTRL_START    0
`define I2C_CTRL_RW       1

//------------------------------------------------------------
// Status Register
//------------------------------------------------------------

`define I2C_STATUS_BUSY   0
`define I2C_STATUS_DONE   1
`define I2C_STATUS_ACK    2

`endif