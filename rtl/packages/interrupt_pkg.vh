`ifndef INTERRUPT_PKG_VH
`define INTERRUPT_PKG_VH

//------------------------------------------------------------
// Interrupt Sources
//------------------------------------------------------------

`define NUM_INTERRUPTS     5
`define INT_ID_WIDTH       3

`define IRQ_TIMER          0
`define IRQ_UART           1
`define IRQ_SPI            2
`define IRQ_I2C            3
`define IRQ_DMA            4

//------------------------------------------------------------
// Register Map  (offsets from interrupt block base 0x1C0)
//------------------------------------------------------------
// BUGFIX: previous version had ENABLE/PENDING swapped and an
// INT_ID_REG that didn't exist in interrupt_axi_wrapper. This
// now matches interrupt_axi_wrapper's REG_ENABLE / REG_PENDING /
// REG_CONTROL / REG_STATUS *exactly*, and matches the Phase 6D
// doc's 0x1C0/0x1C4/0x1C8/0x1CC map.
//------------------------------------------------------------

`define INT_ENABLE_REG     8'h00   // R/W : bit[4:0] = irq_enable
`define INT_PENDING_REG    8'h04   // RO  : bit[4:0] = pending
`define INT_ACK_REG        8'h08   // WO  : bit0 = ack (self-clearing pulse)
`define INT_STATUS_REG     8'h0C   // RO  : bit0 = interrupt, bit[3:1] = interrupt_id

`endif
