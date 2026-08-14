`ifndef SOC_PKG_VH
`define SOC_PKG_VH

//---------------------------------------------------------
// Global Parameters
//---------------------------------------------------------

`define DATA_WIDTH 32
`define ADDR_WIDTH 32

`define RAM_DEPTH 1024
`define ROM_DEPTH 256

//---------------------------------------------------------
// AXI Response Codes
//---------------------------------------------------------

`define AXI_RESP_OKAY    2'b00
`define AXI_RESP_SLVERR  2'b10

//---------------------------------------------------------
// Peripheral Select Encoding
//---------------------------------------------------------

`define SEL_NONE        4'd0
`define SEL_RAM         4'd1
`define SEL_GPIO        4'd2
`define SEL_TIMER       4'd3
`define SEL_UART        4'd4
`define SEL_SPI         4'd5
`define SEL_I2C         4'd6
`define SEL_DMA         4'd7
`define SEL_INTERRUPT   4'd8

//---------------------------------------------------------
// Memory Map
//---------------------------------------------------------

// RAM
`define RAM_BASE         32'h0000_0000
`define RAM_END          32'h0000_003F

// GPIO
`define GPIO_BASE        32'h0000_0040
`define GPIO_END         32'h0000_007F

// TIMER
`define TIMER_BASE       32'h0000_0080
`define TIMER_END        32'h0000_00BF

// UART
`define UART_BASE        32'h0000_00C0
`define UART_END         32'h0000_00FF

// SPI
`define SPI_BASE         32'h0000_0100
`define SPI_END          32'h0000_013F

// I2C
`define I2C_BASE         32'h0000_0140
`define I2C_END          32'h0000_017F

// DMA
`define DMA_BASE         32'h0000_0180
`define DMA_END          32'h0000_01BF

// Interrupt Controller
`define INTERRUPT_BASE   32'h0000_01C0
`define INTERRUPT_END    32'h0000_01FF

`endif