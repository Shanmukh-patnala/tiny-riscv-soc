`ifndef SPI_PKG_VH
`define SPI_PKG_VH

//------------------------------------------------------------
// SPI Parameters
//------------------------------------------------------------

`define SPI_DATA_WIDTH      8
`define SPI_CLK_DIV_WIDTH   8

//------------------------------------------------------------
// SPI Modes
//------------------------------------------------------------

`define SPI_MODE0 2'b00
`define SPI_MODE1 2'b01
`define SPI_MODE2 2'b10
`define SPI_MODE3 2'b11

//------------------------------------------------------------
// FSM States
//------------------------------------------------------------

`define SPI_IDLE   3'd0
`define SPI_LOAD   3'd1
`define SPI_SHIFT  3'd2
`define SPI_DONE   3'd3

//------------------------------------------------------------
// Register Addresses
//------------------------------------------------------------

`define SPI_CTRL_REG     8'h00
`define SPI_STATUS_REG   8'h04
`define SPI_TX_REG       8'h08
`define SPI_RX_REG       8'h0C
`define SPI_CLKDIV_REG   8'h10

//------------------------------------------------------------
// Control Register Bits
//------------------------------------------------------------

`define SPI_CTRL_START   0
`define SPI_CTRL_CPOL    1
`define SPI_CTRL_CPHA    2
`define SPI_CTRL_CS      3

//------------------------------------------------------------
// Status Register Bits
//------------------------------------------------------------

`define SPI_STATUS_BUSY  0
`define SPI_STATUS_DONE  1

`endif