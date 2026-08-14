`timescale 1ns/1ps
`include "i2c_pkg.vh"

module i2c_fsm(

    //------------------------------------------------------------
    // Clock / Reset
    //------------------------------------------------------------

    input wire clk,
    input wire rst,

    //------------------------------------------------------------
    // Control Inputs
    //------------------------------------------------------------

    input wire start,

    input wire rw,

    input wire ack_received,

    input wire byte_done,

    //------------------------------------------------------------
    // FSM Output
    //------------------------------------------------------------

    output reg [3:0] state

);
//------------------------------------------------------------
// State Register
//------------------------------------------------------------

reg [3:0] next_state;

always @(posedge clk or posedge rst)
begin

    if(rst)

        state <= `I2C_IDLE;

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

    `I2C_IDLE:
    begin

        if(start)

            next_state = `I2C_START;

    end

    //--------------------------------------------------------
    // START
    //--------------------------------------------------------

    `I2C_START:
    begin

        next_state = `I2C_ADDRESS;

    end

    //--------------------------------------------------------
    // ADDRESS
    //--------------------------------------------------------

    `I2C_ADDRESS:
    begin

        if(byte_done)

            next_state = `I2C_ACK1;

    end

    //--------------------------------------------------------
    // ACK AFTER ADDRESS
    //--------------------------------------------------------

    `I2C_ACK1:
    begin

        if(byte_done)
        begin

            if(ack_received)
            begin

                if(rw)

                    next_state = `I2C_READ;

                else

                    next_state = `I2C_WRITE;

            end

            else

                next_state = `I2C_STOP;

        end

    end

    //--------------------------------------------------------
    // WRITE
    //--------------------------------------------------------

    `I2C_WRITE:
    begin

        if(byte_done)

            next_state = `I2C_ACK2;

    end

    //--------------------------------------------------------
    // READ
    //--------------------------------------------------------

    `I2C_READ:
    begin

        if(byte_done)

            next_state = `I2C_ACK2;

    end

    //--------------------------------------------------------
    // ACK AFTER DATA
    //--------------------------------------------------------

    `I2C_ACK2:
    begin

        if(byte_done)

            next_state = `I2C_STOP;

    end

    //--------------------------------------------------------
    // STOP
    //--------------------------------------------------------

    `I2C_STOP:
    begin

        if(byte_done)

            next_state = `I2C_DONE;

    end

    //--------------------------------------------------------
    // DONE
    //--------------------------------------------------------

    `I2C_DONE:
    begin

        next_state = `I2C_IDLE;

    end

    //--------------------------------------------------------
    // Default
    //--------------------------------------------------------

    default:

        next_state = `I2C_IDLE;

    endcase

end

endmodule

`timescale 1ns/1ps
`include "i2c_pkg.vh"

module i2c_master(

    //------------------------------------------------------------
    // Clock / Reset
    //------------------------------------------------------------

    input wire clk,
    input wire rst,

    //------------------------------------------------------------
    // CPU Interface
    //------------------------------------------------------------

    input wire start,

    input wire rw,

    input wire [6:0] slave_addr,

    input wire [7:0] tx_data,

    output reg [7:0] rx_data,

    output reg busy,

    output reg done,

    //------------------------------------------------------------
    // Clock Divider
    //------------------------------------------------------------

    input wire [`I2C_CLK_DIV_WIDTH-1:0] clk_div,

    //------------------------------------------------------------
    // I2C Bus
    //------------------------------------------------------------

    inout wire sda,

    output reg scl

);
//------------------------------------------------------------
// FSM
//------------------------------------------------------------

wire [3:0] state;

//------------------------------------------------------------
// Shift Registers
//------------------------------------------------------------

reg [7:0] tx_shift_reg;
reg [7:0] rx_shift_reg;

reg [7:0] address_shift_reg;

//------------------------------------------------------------
// Counters
//------------------------------------------------------------

reg [3:0] bit_counter;

reg [`I2C_CLK_DIV_WIDTH-1:0] clk_counter;

//------------------------------------------------------------
// Status
//------------------------------------------------------------

reg byte_done;
reg ack_received;

//------------------------------------------------------------
// SDA Control
//------------------------------------------------------------

reg sda_out;
reg sda_oe;

wire sda_in;
//------------------------------------------------------------
// Open Drain SDA
//------------------------------------------------------------

assign sda = sda_oe ? sda_out : 1'bz;

assign sda_in = sda;
//------------------------------------------------------------
// FSM
//------------------------------------------------------------

i2c_fsm FSM(

    .clk(clk),

    .rst(rst),

    .start(start),

    .rw(rw),

    .ack_received(ack_received),

    .byte_done(byte_done),

    .state(state)

);
//------------------------------------------------------------
// Clock Divider
//------------------------------------------------------------

wire scl_tick;

assign scl_tick = (clk_counter == clk_div);  
  
  

reg [3:0] next_state;
//------------------------------------------------------------
// Clock Divider Logic
//------------------------------------------------------------

always @(posedge clk or posedge rst)
begin

    if(rst)

        clk_counter <= 0;

    else
    begin

        if(clk_counter == clk_div)

            clk_counter <= 0;

        else

            clk_counter <= clk_counter + 1;

    end

end
//------------------------------------------------------------
// I2C Transfer Logic
//------------------------------------------------------------

always @(posedge clk or posedge rst)
begin

if(rst)
begin

    scl              <= 1'b1;

    tx_shift_reg     <= 8'd0;
    rx_shift_reg     <= 8'd0;

    address_shift_reg <= 8'd0;

    bit_counter      <= 4'd0;

    byte_done        <= 1'b0;

    ack_received     <= 1'b0;

    rx_data          <= 8'd0;

    //--------------------------------------------------------
    // SDA reset
    // Release the open-drain bus during reset
    //--------------------------------------------------------

    sda_out <= 1'b1;
    sda_oe  <= 1'b0;

end

    else
    begin

        byte_done    <= 1'b0;
        ack_received <= 1'b0;

        case(state)
        //----------------------------------------------------
        // START
        //----------------------------------------------------

        `I2C_START:
        begin

            scl <= 1'b1;

            sda_out <= 1'b0;
            sda_oe  <= 1'b1;

            address_shift_reg <=
            {
                slave_addr,
                rw
            };

            bit_counter <= 4'd8;

        end
        //----------------------------------------------------
        // ADDRESS
        //----------------------------------------------------

        `I2C_ADDRESS:
        begin

            if(scl_tick)
            begin

                scl <= ~scl;

                if(!scl)
                begin

                    sda_out <= address_shift_reg[7];

                    address_shift_reg <=
                    {
                        address_shift_reg[6:0],
                        1'b0
                    };

                end

                else
                begin

                    if(bit_counter == 0)

                        byte_done <= 1'b1;

                    else

                        bit_counter <= bit_counter - 1;

                end

            end

        end
        //----------------------------------------------------
        // ACK AFTER ADDRESS
        //----------------------------------------------------

        `I2C_ACK1:
        begin

            sda_oe <= 1'b0;

            if(scl_tick)
            begin

                scl <= ~scl;

                if(scl)
                begin

                    ack_received <= ~sda_in;
                    byte_done    <= 1'b1;

                    // Preload for the next phase (WRITE or READ) --
                    // bit_counter is left at 0 after ADDRESS finishes,
                    // so without this, WRITE/READ would inherit that
                    // stale value instead of starting a fresh 8-bit
                    // count. tx_shift_reg preload is only used by
                    // WRITE; harmless if READ is taken instead.
                    bit_counter  <= 4'd7;
                    tx_shift_reg <= tx_data;

                end

            end

        end
        //----------------------------------------------------
        // WRITE
        //----------------------------------------------------

        `I2C_WRITE:
        begin

            if(scl_tick)
            begin

                scl <= ~scl;

                if(!scl)
                begin

                    sda_oe  <= 1'b1;

                    sda_out <= tx_shift_reg[7];

                    tx_shift_reg <=
                    {
                        tx_shift_reg[6:0],
                        1'b0
                    };

                end

                else
                begin

                    if(bit_counter == 0)

                        byte_done <= 1'b1;

                    else

                        bit_counter <= bit_counter - 1;

                end

            end

        end
        //----------------------------------------------------
        // READ
        //----------------------------------------------------

        `I2C_READ:
        begin

            sda_oe <= 1'b0;

            if(scl_tick)
            begin

                scl <= ~scl;

                if(scl)
                begin

                    rx_shift_reg <=
                    {
                        rx_shift_reg[6:0],
                        sda_in
                    };

                    if(bit_counter == 0)
                    begin

                        rx_data <=
                        {
                            rx_shift_reg[6:0],
                            sda_in
                        };

                        byte_done <= 1'b1;

                    end

                    else

                        bit_counter <= bit_counter - 1;

                end

            end

        end
        //----------------------------------------------------
        // ACK AFTER DATA
        //----------------------------------------------------

        `I2C_ACK2:
        begin

            sda_oe <= 1'b0;

            if(scl_tick)
            begin

                scl <= ~scl;

                if(scl)
                begin

                    ack_received <= ~sda_in;
                    byte_done    <= 1'b1;

                end

            end

        end
        //----------------------------------------------------
        // STOP
        //----------------------------------------------------

        `I2C_STOP:
        begin

            if(scl_tick)
            begin

                case(bit_counter)

                    // Phase 0: take control of the bus, drive SDA low
                    // while SCL is still low (setup).
                    4'd0:
                    begin

                        sda_oe      <= 1'b1;
                        sda_out     <= 1'b0;
                        scl         <= 1'b0;
                        bit_counter <= 4'd1;

                    end

                    // Phase 1: raise SCL while SDA stays low.
                    4'd1:
                    begin

                        scl         <= 1'b1;
                        bit_counter <= 4'd2;

                    end

                    // Phase 2: raise SDA while SCL is held high --
                    // this edge is the actual STOP condition.
                    default:
                    begin

                        sda_out   <= 1'b1;
                        byte_done <= 1'b1;

                    end

                endcase

            end

        end
        endcase

    end

end
//------------------------------------------------------------
// Status Logic
//------------------------------------------------------------

always @(*)
begin

    //--------------------------------------------------------
    // Default Outputs
    //--------------------------------------------------------

    busy = 1'b0;

    done = 1'b0;

    case(state)

    //--------------------------------------------------------
    // IDLE
    //--------------------------------------------------------

    `I2C_IDLE:
    begin

        busy = 1'b0;

        done = 1'b0;

    end

    //--------------------------------------------------------
    // START
    //--------------------------------------------------------

    `I2C_START:
    begin

        busy = 1'b1;

        done = 1'b0;

    end

    //--------------------------------------------------------
    // ADDRESS
    //--------------------------------------------------------

    `I2C_ADDRESS:
    begin

        busy = 1'b1;

        done = 1'b0;

    end

    //--------------------------------------------------------
    // ACK1
    //--------------------------------------------------------

    `I2C_ACK1:
    begin

        busy = 1'b1;

        done = 1'b0;

    end

    //--------------------------------------------------------
    // WRITE
    //--------------------------------------------------------

    `I2C_WRITE:
    begin

        busy = 1'b1;

        done = 1'b0;

    end

    //--------------------------------------------------------
    // READ
    //--------------------------------------------------------

    `I2C_READ:
    begin

        busy = 1'b1;

        done = 1'b0;

    end

    //--------------------------------------------------------
    // ACK2
    //--------------------------------------------------------

    `I2C_ACK2:
    begin

        busy = 1'b1;

        done = 1'b0;

    end

    //--------------------------------------------------------
    // STOP
    //--------------------------------------------------------

    `I2C_STOP:
    begin

        busy = 1'b1;

        done = 1'b0;

    end

    //--------------------------------------------------------
    // DONE
    //--------------------------------------------------------

    `I2C_DONE:
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
`include "i2c_pkg.vh"

module i2c_top(

    //------------------------------------------------------------
    // Clock / Reset
    //------------------------------------------------------------

    input wire clk,
    input wire rst,

    //------------------------------------------------------------
    // CPU Interface
    //------------------------------------------------------------

    input wire start,

    input wire rw,

    input wire [6:0] slave_addr,

    input wire [7:0] tx_data,

    input wire [`I2C_CLK_DIV_WIDTH-1:0] clk_div,

    output wire [7:0] rx_data,

    output wire busy,

    output wire done,

    //------------------------------------------------------------
    // I2C Interface
    //------------------------------------------------------------

    inout wire sda,

    output wire scl

);

    //------------------------------------------------------------
    // I2C Master
    //------------------------------------------------------------

    i2c_master MASTER(

        .clk(clk),
        .rst(rst),

        .start(start),

        .rw(rw),

        .slave_addr(slave_addr),

        .tx_data(tx_data),

        .rx_data(rx_data),

        .busy(busy),

        .done(done),

        .clk_div(clk_div),

        .sda(sda),

        .scl(scl)

    );

endmodule