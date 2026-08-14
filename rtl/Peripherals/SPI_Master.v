`timescale 1ns/1ps
`include "spi_pkg.vh"

module spi_fsm(

    //------------------------------------------------------------
    // Clock / Reset
    //------------------------------------------------------------

    input wire clk,
    input wire rst,

    //------------------------------------------------------------
    // Control Inputs
    //------------------------------------------------------------

    input wire start,
    input wire shift_done,

    //------------------------------------------------------------
    // FSM Output
    //------------------------------------------------------------

    output reg [2:0] state

);

//------------------------------------------------------------
// State Register
//------------------------------------------------------------

reg [2:0] next_state;

//------------------------------------------------------------
// Sequential Logic
//------------------------------------------------------------

always @(posedge clk or posedge rst)
begin

    if(rst)

        state <= `SPI_IDLE;

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

        //----------------------------------------
        // IDLE
        //----------------------------------------

        `SPI_IDLE:
        begin

            if(start)

                next_state = `SPI_LOAD;

        end

        //----------------------------------------
        // LOAD
        //----------------------------------------

        `SPI_LOAD:
        begin

            next_state = `SPI_SHIFT;

        end

        //----------------------------------------
        // SHIFT
        //----------------------------------------

        `SPI_SHIFT:
        begin

            if(shift_done)

                next_state = `SPI_DONE;

        end

        //----------------------------------------
        // DONE
        //----------------------------------------

        `SPI_DONE:
        begin

            next_state = `SPI_IDLE;

        end

        //----------------------------------------
        // Default
        //----------------------------------------

        default:

            next_state = `SPI_IDLE;

    endcase

end

endmodule


`timescale 1ns/1ps
`include "spi_pkg.vh"

module spi_master(

    //------------------------------------------------------------
    // Clock / Reset
    //------------------------------------------------------------

    input wire clk,
    input wire rst,

    //------------------------------------------------------------
    // CPU Interface
    //------------------------------------------------------------

    input wire start,
    input wire [7:0] tx_data,

    output reg [7:0] rx_data,
    output reg busy,
    output reg done,

    //------------------------------------------------------------
    // Clock Divider
    //------------------------------------------------------------

    input wire [`SPI_CLK_DIV_WIDTH-1:0] clk_div,

    //------------------------------------------------------------
    // SPI Interface
    //------------------------------------------------------------

    output reg sclk,
    output reg mosi,
    input wire miso,
    output reg cs_n

);

    //------------------------------------------------------------
    // Internal Signals
    //------------------------------------------------------------

    wire [2:0] state;

    reg shift_done;
    wire spi_tick;

    reg [`SPI_CLK_DIV_WIDTH-1:0] clk_counter;

    reg [7:0] shift_reg_tx;
    reg [7:0] shift_reg_rx;

    reg [2:0] bit_counter;

    //------------------------------------------------------------
    // SPI FSM
    //------------------------------------------------------------

    spi_fsm FSM(
        .clk        (clk),
        .rst        (rst),
        .start      (start),
        .shift_done (shift_done),
        .state      (state)
    );

    //------------------------------------------------------------
    // Clock Divider
    //------------------------------------------------------------

    assign spi_tick = (clk_counter == clk_div);

    //------------------------------------------------------------
    // Clock Divider Counter
    //------------------------------------------------------------

    always @(posedge clk or posedge rst)
    begin

        if (rst)
            clk_counter <= 0;

        else begin

            if (clk_counter == clk_div)
                clk_counter <= 0;

            else
                clk_counter <= clk_counter + 1'b1;

        end

    end

    //------------------------------------------------------------
    // SPI Shift Logic
    //------------------------------------------------------------

    always @(posedge clk or posedge rst)
    begin

        if (rst)
        begin

            shift_reg_tx <= 8'd0;
            shift_reg_rx <= 8'd0;

            bit_counter  <= 3'd0;

            shift_done   <= 1'b0;

            rx_data      <= 8'd0;

            sclk         <= 1'b0;
            mosi         <= 1'b0;

        end

        else
        begin

            //----------------------------------------------------
            // Default
            //----------------------------------------------------

            shift_done <= 1'b0;

            //----------------------------------------------------
            // FSM
            //----------------------------------------------------

            case(state)

                //------------------------------------------------
                // LOAD
                //------------------------------------------------

                `SPI_LOAD:
                begin

                    shift_reg_tx <= tx_data;

                    shift_reg_rx <= 8'd0;

                    bit_counter <= 3'd7;

                    sclk <= 1'b0;

                    //------------------------------------------------
                    // Put first TX bit on MOSI before shifting
                    //------------------------------------------------

                    mosi <= tx_data[7];

                end


                //------------------------------------------------
                // SHIFT
                //------------------------------------------------

                `SPI_SHIFT:
                begin

                    if (spi_tick)
                    begin

                        //------------------------------------------------
                        // Current SCLK LOW
                        //
                        // Generate rising edge and sample MISO
                        //------------------------------------------------

                        if (sclk == 1'b0)
                        begin

                            sclk <= 1'b1;

                            //------------------------------------------------
                            // Sample MISO
                            //------------------------------------------------

                            shift_reg_rx <=
                            {
                                shift_reg_rx[6:0],
                                miso
                            };

                            //------------------------------------------------
                            // Last receive bit
                            //------------------------------------------------

                            if (bit_counter == 3'd0)
                            begin

                                rx_data <=
                                {
                                    shift_reg_rx[6:0],
                                    miso
                                };

                                //------------------------------------------------
                                // Do NOT finish yet.
                                //
                                // We still need the final falling edge
                                // so the last TX bit completes correctly.
                                //------------------------------------------------

                            end

                        end

                        //------------------------------------------------
                        // Current SCLK HIGH
                        //
                        // Generate falling edge and transmit next bit
                        //------------------------------------------------

                        else
                        begin

                            sclk <= 1'b0;

                            //------------------------------------------------
                            // Shift TX register
                            //------------------------------------------------

                            if (bit_counter != 3'd0)
                            begin

                                mosi <= shift_reg_tx[6];

                                shift_reg_tx <=
                                {
                                    shift_reg_tx[6:0],
                                    1'b0
                                };

                                bit_counter <= bit_counter - 1'b1;

                            end

                            else
                            begin

                                //------------------------------------------------
                                // Final falling edge completed.
                                //
                                // Now the complete 8-bit transaction
                                // is finished.
                                //------------------------------------------------

                                shift_done <= 1'b1;

                            end

                        end

                    end

                end


                //------------------------------------------------
                // DONE
                //------------------------------------------------

                `SPI_DONE:
                begin

                    sclk <= 1'b0;

                    mosi <= 1'b0;

                end


                //------------------------------------------------
                // DEFAULT
                //------------------------------------------------

                default:
                begin

                    sclk <= 1'b0;
                    mosi <= 1'b0;

                end

            endcase

        end

    end

    //------------------------------------------------------------
    // Status / Control Logic
    //------------------------------------------------------------

    always @(*)
    begin

        //--------------------------------------------------------
        // Defaults
        //--------------------------------------------------------

        busy = 1'b0;
        done = 1'b0;
        cs_n = 1'b1;

        //--------------------------------------------------------
        // FSM State
        //--------------------------------------------------------

        case(state)

            //----------------------------------------------------
            // IDLE
            //----------------------------------------------------

            `SPI_IDLE:
            begin

                busy = 1'b0;
                done = 1'b0;
                cs_n = 1'b1;

            end


            //----------------------------------------------------
            // LOAD
            //----------------------------------------------------

            `SPI_LOAD:
            begin

                busy = 1'b1;
                done = 1'b0;
                cs_n = 1'b0;

            end


            //----------------------------------------------------
            // SHIFT
            //----------------------------------------------------

            `SPI_SHIFT:
            begin

                busy = 1'b1;
                done = 1'b0;
                cs_n = 1'b0;

            end


            //----------------------------------------------------
            // DONE
            //----------------------------------------------------

            `SPI_DONE:
            begin

                busy = 1'b0;
                done = 1'b1;
                cs_n = 1'b1;

            end


            //----------------------------------------------------
            // DEFAULT
            //----------------------------------------------------

            default:
            begin

                busy = 1'b0;
                done = 1'b0;
                cs_n = 1'b1;

            end

        endcase

    end

endmodule
 
`timescale 1ns/1ps
`include "spi_pkg.vh"

module spi_top(

    //------------------------------------------------------------
    // Clock / Reset
    //------------------------------------------------------------

    input wire clk,
    input wire rst,

    //------------------------------------------------------------
    // CPU Interface
    //------------------------------------------------------------

    input wire start,

    input wire [7:0] tx_data,

    input wire [`SPI_CLK_DIV_WIDTH-1:0] clk_div,

    output wire [7:0] rx_data,

    output wire busy,

    output wire done,

    //------------------------------------------------------------
    // SPI Interface
    //------------------------------------------------------------

    output wire sclk,

    output wire mosi,

    input wire miso,

    output wire cs_n

);

    //------------------------------------------------------------
    // SPI Master
    //------------------------------------------------------------

    spi_master MASTER(

        .clk(clk),
        .rst(rst),

        .start(start),

        .tx_data(tx_data),

        .rx_data(rx_data),

        .busy(busy),

        .done(done),

        .clk_div(clk_div),

        .sclk(sclk),

        .mosi(mosi),

        .miso(miso),

        .cs_n(cs_n)

    );

endmodule