`ifndef DMA_PKG_VH
`define DMA_PKG_VH

//------------------------------------------------------------
// Parameters
//------------------------------------------------------------

`define DMA_ADDR_WIDTH      32
`define DMA_DATA_WIDTH      32
`define DMA_LENGTH_WIDTH    16

//------------------------------------------------------------
// FSM States
//------------------------------------------------------------

`define DMA_IDLE    3'd0
`define DMA_READ    3'd1
`define DMA_WRITE   3'd2
`define DMA_UPDATE  3'd3
`define DMA_DONE    3'd4

//------------------------------------------------------------
// Register Map
//------------------------------------------------------------

`define DMA_SRC_REG      8'h00
`define DMA_DST_REG      8'h04
`define DMA_LEN_REG      8'h08
`define DMA_CTRL_REG     8'h0C
`define DMA_STATUS_REG   8'h10

//------------------------------------------------------------
// Control Register Bits
//------------------------------------------------------------

`define DMA_CTRL_START   0

//------------------------------------------------------------
// Status Register Bits
//------------------------------------------------------------

`define DMA_STATUS_BUSY  0
`define DMA_STATUS_DONE  1

`endif