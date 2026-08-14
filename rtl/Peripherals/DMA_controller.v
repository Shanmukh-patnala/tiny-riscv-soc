`timescale 1ns/1ps
`include "dma_pkg.vh"

module dma_fsm(

    input wire clk,
    input wire rst,

    input wire start,

    input wire transfer_done,

    input wire mem_ready,

    output reg [2:0] state

);
  
//------------------------------------------------------------
// Next State Register
//------------------------------------------------------------

reg [2:0] next_state;

//------------------------------------------------------------
// State Register
//------------------------------------------------------------

always @(posedge clk or posedge rst)
begin

    if(rst)

        state <= `DMA_IDLE;

    else

        state <= next_state;

end

//------------------------------------------------------------
// Next State Logic
//------------------------------------------------------------

always @(*)
begin

    next_state = state;

    case(state)

    //--------------------------------------------------------
    // IDLE
    //--------------------------------------------------------

    `DMA_IDLE:
    begin

        if(start)

            next_state = `DMA_READ;

    end

    //--------------------------------------------------------
    // READ
    //--------------------------------------------------------
      
`DMA_READ:
begin

    if (mem_ready)
        next_state = `DMA_WRITE;
    else
        next_state = `DMA_READ;

end

    //--------------------------------------------------------
    // WRITE
    //--------------------------------------------------------

`DMA_WRITE:
begin

    if (mem_ready)
        next_state = `DMA_UPDATE;
    else
        next_state = `DMA_WRITE;

end

    //--------------------------------------------------------
    // UPDATE
    //--------------------------------------------------------

`DMA_UPDATE:
begin

    //--------------------------------------------------------
    // Last transfer has just completed
    //--------------------------------------------------------

    if(transfer_done)
        next_state = `DMA_DONE;

    //--------------------------------------------------------
    // Continue next transfer
    //--------------------------------------------------------

    else
        next_state = `DMA_READ;

end

    //--------------------------------------------------------
    // DONE
    //--------------------------------------------------------

    `DMA_DONE:
    begin

        next_state = `DMA_IDLE;

    end

    //--------------------------------------------------------
    // Default
    //--------------------------------------------------------

    default:
    begin

        next_state = `DMA_IDLE;

    end

    endcase

end

endmodule

`timescale 1ns/1ps
`include "dma_pkg.vh"

module dma_controller(

    //------------------------------------------------------------
    // Clock / Reset
    //------------------------------------------------------------

    input wire clk,
    input wire rst,

    //------------------------------------------------------------
    // CPU Interface
    //------------------------------------------------------------

    input wire start,

    input wire [`DMA_ADDR_WIDTH-1:0] src_addr,

    input wire [`DMA_ADDR_WIDTH-1:0] dst_addr,

    input wire [`DMA_LENGTH_WIDTH-1:0] transfer_length,

    //------------------------------------------------------------
    // Memory Interface
    //------------------------------------------------------------

    input wire [`DMA_DATA_WIDTH-1:0] mem_read_data,
    input wire mem_ready,

    output reg [`DMA_ADDR_WIDTH-1:0] mem_read_addr,

    output reg [`DMA_ADDR_WIDTH-1:0] mem_write_addr,

    output reg [`DMA_DATA_WIDTH-1:0] mem_write_data,

    output reg mem_read,

    output reg mem_write,

    //------------------------------------------------------------
    // Status
    //------------------------------------------------------------

    output reg busy,

    output reg done

);
//------------------------------------------------------------
// FSM
//------------------------------------------------------------

wire [2:0] state;

//------------------------------------------------------------
// Internal Registers
//------------------------------------------------------------

reg [`DMA_ADDR_WIDTH-1:0] current_src;

reg [`DMA_ADDR_WIDTH-1:0] current_dst;

reg [`DMA_LENGTH_WIDTH-1:0] length_counter;

reg [`DMA_DATA_WIDTH-1:0] data_buffer;

wire transfer_done;
//------------------------------------------------------------
// DMA FSM
//------------------------------------------------------------
  
dma_fsm FSM(

    .clk(clk),
    .rst(rst),

    .start(start),

    .transfer_done(transfer_done),

    .mem_ready(mem_ready),

    .state(state)

);
//------------------------------------------------------------
// Transfer Complete
//------------------------------------------------------------

assign transfer_done = (length_counter <= 16'd1);
//------------------------------------------------------------
// DMA Registers
//------------------------------------------------------------

always @(posedge clk or posedge rst)
begin

    if(rst)
    begin

        current_src <= 0;

        current_dst <= 0;

        length_counter <= 0;

        data_buffer <= 0;

    end

    else
    begin

        case(state)

        //----------------------------------------------------
        // IDLE
        //----------------------------------------------------

        `DMA_IDLE:
        begin

            if(start)
            begin

                current_src <= src_addr;

                current_dst <= dst_addr;

                length_counter <= transfer_length;

            end

        end
        //----------------------------------------------------
        // READ
        //----------------------------------------------------

        `DMA_READ:
begin

    if (mem_ready)
        data_buffer <= mem_read_data;

end
        //----------------------------------------------------
        // WRITE
        //----------------------------------------------------

        `DMA_WRITE:
        begin

            // Data already buffered

        end 
        //----------------------------------------------------
        // UPDATE
        //----------------------------------------------------

        `DMA_UPDATE:
        begin

            current_src <= current_src + 4;

            current_dst <= current_dst + 4;

            if(length_counter != 0)

                length_counter <= length_counter - 1;

        end
        endcase

    end

end
//------------------------------------------------------------
// Memory Control Logic
//------------------------------------------------------------

always @(*)
begin

    //--------------------------------------------------------
    // Default Outputs
    //--------------------------------------------------------

    mem_read       = 1'b0;

    mem_write      = 1'b0;

    mem_read_addr  = current_src;

    mem_write_addr = current_dst;

    mem_write_data = data_buffer;

    case(state)

    //--------------------------------------------------------
    // IDLE
    //--------------------------------------------------------

    `DMA_IDLE:
    begin

        mem_read  = 1'b0;

        mem_write = 1'b0;

    end

    //--------------------------------------------------------
    // READ
    //--------------------------------------------------------

    `DMA_READ:
    begin

        mem_read = 1'b1;

    end

    //--------------------------------------------------------
    // WRITE
    //--------------------------------------------------------

    `DMA_WRITE:
    begin

        mem_write = 1'b1;

    end

    //--------------------------------------------------------
    // UPDATE
    //--------------------------------------------------------

    `DMA_UPDATE:
    begin

        mem_read  = 1'b0;

        mem_write = 1'b0;

    end

    //--------------------------------------------------------
    // DONE
    //--------------------------------------------------------

    `DMA_DONE:
    begin

        mem_read  = 1'b0;

        mem_write = 1'b0;

    end

    endcase

end
//------------------------------------------------------------
// Status Logic
//------------------------------------------------------------

always @(*)
begin

    busy = 1'b0;

    done = 1'b0;

    case(state)

    //--------------------------------------------------------
    // IDLE
    //--------------------------------------------------------

    `DMA_IDLE:
    begin

        busy = 1'b0;

        done = 1'b0;

    end

    //--------------------------------------------------------
    // READ
    //--------------------------------------------------------

    `DMA_READ:
    begin

        busy = 1'b1;

        done = 1'b0;

    end

    //--------------------------------------------------------
    // WRITE
    //--------------------------------------------------------

    `DMA_WRITE:
    begin

        busy = 1'b1;

        done = 1'b0;

    end

    //--------------------------------------------------------
    // UPDATE
    //--------------------------------------------------------

    `DMA_UPDATE:
    begin

        busy = 1'b1;

        done = 1'b0;

    end

    //--------------------------------------------------------
    // DONE
    //--------------------------------------------------------

    `DMA_DONE:
    begin

        busy = 1'b0;

        done = 1'b1;

    end

    //--------------------------------------------------------
    // Default
    //--------------------------------------------------------

    default:
    begin

        busy = 1'b0;

        done = 1'b0;

    end

    endcase

end  
endmodule

`timescale 1ns/1ps
`include "dma_pkg.vh"

module dma_top(

    //------------------------------------------------------------
    // Clock / Reset
    //------------------------------------------------------------

    input wire clk,
    input wire rst,

    //------------------------------------------------------------
    // CPU Configuration Interface
    //------------------------------------------------------------

    input wire start,

    input wire [`DMA_ADDR_WIDTH-1:0] src_addr,

    input wire [`DMA_ADDR_WIDTH-1:0] dst_addr,

    input wire [`DMA_LENGTH_WIDTH-1:0] transfer_length,
  
    input wire mem_ready,

    //------------------------------------------------------------
    // Memory Interface
    //------------------------------------------------------------

    input wire [`DMA_DATA_WIDTH-1:0] mem_read_data,

    output wire [`DMA_ADDR_WIDTH-1:0] mem_read_addr,

    output wire [`DMA_ADDR_WIDTH-1:0] mem_write_addr,

    output wire [`DMA_DATA_WIDTH-1:0] mem_write_data,

    output wire mem_read,

    output wire mem_write,

    //------------------------------------------------------------
    // Status
    //------------------------------------------------------------

    output wire busy,

    output wire done

);

    //------------------------------------------------------------
    // DMA Controller
    //------------------------------------------------------------

    dma_controller DMA(

        .clk(clk),
        .rst(rst),

        .start(start),

        .src_addr(src_addr),

        .dst_addr(dst_addr),

        .transfer_length(transfer_length),

        .mem_read_data(mem_read_data),

        .mem_read_addr(mem_read_addr),

        .mem_write_addr(mem_write_addr),

        .mem_write_data(mem_write_data),

        .mem_read(mem_read),

        .mem_write(mem_write),
        
        .mem_ready(mem_ready),

        .busy(busy),

        .done(done)

    );

endmodule