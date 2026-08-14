`timescale 1ns/1ps
//--------------------------------------------------------------------------
//                         axi_interconnect
//--------------------------------------------------------------------------

//--------------------------------------------------------------------------
//                     AXI Address Decoder
//--------------------------------------------------------------------------

`include "soc_pkg.vh"

module axi_address_decoder (

    //------------------------------------------------------------
    // Address Input
    //------------------------------------------------------------

    input  wire [`ADDR_WIDTH-1:0] addr,

    //------------------------------------------------------------
    // Peripheral Select Outputs
    //------------------------------------------------------------

    output reg                    ram_sel,
    output reg                    gpio_sel,
    output reg                    timer_sel,
    output reg                    uart_sel,

    output reg                    spi_sel,
    output reg                    i2c_sel,
    output reg                    dma_sel,
    output reg                    interrupt_sel,

    //------------------------------------------------------------
    // Selected Slave ID
    //------------------------------------------------------------

    output reg [3:0]              slave_id

);

    //------------------------------------------------------------
    // Address Decode Logic
    //------------------------------------------------------------

    always @(*) begin

        //--------------------------------------------------------
        // Default Values
        //--------------------------------------------------------

        ram_sel        = 1'b0;
        gpio_sel       = 1'b0;
        timer_sel      = 1'b0;
        uart_sel       = 1'b0;

        spi_sel        = 1'b0;
        i2c_sel        = 1'b0;
        dma_sel        = 1'b0;
        interrupt_sel  = 1'b0;

        slave_id       = `SEL_NONE;

        //--------------------------------------------------------
        // RAM
        //--------------------------------------------------------

        if ((addr >= `RAM_BASE) &&
            (addr <= `RAM_END)) begin

            ram_sel  = 1'b1;
            slave_id = `SEL_RAM;

        end

        //--------------------------------------------------------
        // GPIO
        //--------------------------------------------------------

        else if ((addr >= `GPIO_BASE) &&
                 (addr <= `GPIO_END)) begin

            gpio_sel = 1'b1;
            slave_id = `SEL_GPIO;

        end

        //--------------------------------------------------------
        // TIMER
        //--------------------------------------------------------

        else if ((addr >= `TIMER_BASE) &&
                 (addr <= `TIMER_END)) begin

            timer_sel = 1'b1;
            slave_id  = `SEL_TIMER;

        end

        //--------------------------------------------------------
        // UART
        //--------------------------------------------------------

        else if ((addr >= `UART_BASE) &&
                 (addr <= `UART_END)) begin

            uart_sel  = 1'b1;
            slave_id  = `SEL_UART;

        end

        //--------------------------------------------------------
        // SPI
        //--------------------------------------------------------

        else if ((addr >= `SPI_BASE) &&
                 (addr <= `SPI_END)) begin

            spi_sel   = 1'b1;
            slave_id  = `SEL_SPI;

        end

        //--------------------------------------------------------
        // I2C
        //--------------------------------------------------------

        else if ((addr >= `I2C_BASE) &&
                 (addr <= `I2C_END)) begin

            i2c_sel   = 1'b1;
            slave_id  = `SEL_I2C;

        end

        //--------------------------------------------------------
        // DMA
        //--------------------------------------------------------

        else if ((addr >= `DMA_BASE) &&
                 (addr <= `DMA_END)) begin

            dma_sel   = 1'b1;
            slave_id  = `SEL_DMA;

        end

        //--------------------------------------------------------
        // Interrupt Controller
        //--------------------------------------------------------

        else if ((addr >= `INTERRUPT_BASE) &&
                 (addr <= `INTERRUPT_END)) begin

            interrupt_sel = 1'b1;
            slave_id       = `SEL_INTERRUPT;

        end

    end

endmodule

//.....................................................................................................
`include "soc_pkg.vh"

module axi_write_fsm (

    input wire clk,
    input wire rst_n,

    //----------------------------------------------------------
    // Master Side (CPU AXI Master)
    //----------------------------------------------------------

    input  wire [31:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output reg         s_axi_awready,

    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output reg         s_axi_wready,

    output reg [1:0]   s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,

    //----------------------------------------------------------
    // Slave Select
    //----------------------------------------------------------

    input wire ram_sel,
    input wire gpio_sel,
    input wire timer_sel,
    input wire uart_sel,

//----------------------------------------------------------
// New Slave Selects
//----------------------------------------------------------

input wire spi_sel,
input wire i2c_sel,
input wire dma_sel,
    input wire interrupt_sel,

input wire          ram_ready,

//----------------------------------------------------------
// Peripheral Control
//----------------------------------------------------------

output reg         ram_wr_en,
output reg         gpio_wr_en,
output reg         timer_wr_en,
output reg         uart_wr_en,
output reg         spi_wr_en,
output reg         i2c_wr_en,
output reg         dma_wr_en,
output reg         interrupt_wr_en,

output reg [31:0]  write_addr,
output reg [31:0]  write_data

);

    //----------------------------------------------------------
    // FSM States
    //----------------------------------------------------------

    localparam IDLE       = 2'b00;
    localparam WRITE_DATA = 2'b01;
    localparam WRITE_RESP = 2'b10;

    reg [1:0] state;
    reg [1:0] next_state;

    //----------------------------------------------------------
    // Saved Information
    //----------------------------------------------------------

    reg [31:0] saved_awaddr;

    reg saved_ram_sel;
    reg saved_gpio_sel;
    reg saved_timer_sel;
    reg saved_uart_sel;

    reg saved_spi_sel;
reg saved_i2c_sel;
reg saved_dma_sel;
reg saved_interrupt_sel;

    //----------------------------------------------------------
    // State Register
    //----------------------------------------------------------

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;

    end

    //----------------------------------------------------------
    // Next-State Logic
    //----------------------------------------------------------

    always @(*) begin

        next_state = state;

        case (state)

            //--------------------------------------------------
            // IDLE
            //--------------------------------------------------

            IDLE: begin

                if (s_axi_awvalid && s_axi_awready)
                    next_state = WRITE_DATA;

            end

            //--------------------------------------------------
            // WRITE DATA
            //--------------------------------------------------

            WRITE_DATA: begin

                if (s_axi_wvalid && s_axi_wready)
                    next_state = WRITE_RESP;

            end

            //--------------------------------------------------
            // WRITE RESPONSE
            //--------------------------------------------------

            WRITE_RESP: begin

                if (s_axi_bvalid && s_axi_bready)
                    next_state = IDLE;

            end

            //--------------------------------------------------
            // DEFAULT
            //--------------------------------------------------

            default:

                next_state = IDLE;

        endcase

    end

    //----------------------------------------------------------
    // Output Logic
    //----------------------------------------------------------

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;

            s_axi_bvalid  <= 1'b0;
            s_axi_bresp   <= `AXI_RESP_OKAY;

ram_wr_en        <= 1'b0;
gpio_wr_en       <= 1'b0;
timer_wr_en      <= 1'b0;
uart_wr_en       <= 1'b0;

spi_wr_en        <= 1'b0;
i2c_wr_en        <= 1'b0;
dma_wr_en        <= 1'b0;
interrupt_wr_en  <= 1'b0;

            write_addr    <= 32'd0;
            write_data    <= 32'd0;

            saved_awaddr  <= 32'd0;

            saved_ram_sel   <= 1'b0;
            saved_gpio_sel  <= 1'b0;
            saved_timer_sel <= 1'b0;
            saved_uart_sel  <= 1'b0;

            saved_spi_sel       <= 1'b0;
            saved_i2c_sel       <= 1'b0;
saved_dma_sel       <= 1'b0;
saved_interrupt_sel <= 1'b0;

        end

        else begin

//--------------------------------------------------
// Default outputs
//--------------------------------------------------

ram_wr_en        <= 1'b0;
gpio_wr_en       <= 1'b0;
timer_wr_en      <= 1'b0;
uart_wr_en       <= 1'b0;

spi_wr_en        <= 1'b0;
i2c_wr_en        <= 1'b0;
dma_wr_en        <= 1'b0;
interrupt_wr_en  <= 1'b0;

            case (state)

                //--------------------------------------------------
                // IDLE
                //--------------------------------------------------

                IDLE: begin

                    s_axi_awready <= 1'b1;
                    s_axi_wready  <= 1'b0;
                    s_axi_bvalid  <= 1'b0;

                    if (s_axi_awvalid) begin

                        saved_awaddr <= s_axi_awaddr;

                        saved_ram_sel   <= ram_sel;
                        saved_gpio_sel  <= gpio_sel;
                        saved_timer_sel <= timer_sel;
                        saved_uart_sel  <= uart_sel;

                        saved_spi_sel       <= spi_sel;
                        saved_i2c_sel       <= i2c_sel;
                        saved_dma_sel       <= dma_sel;
                        saved_interrupt_sel <= interrupt_sel;

                    end

                end

                //--------------------------------------------------
                // WRITE DATA
                //--------------------------------------------------

                WRITE_DATA: begin

                    s_axi_awready <= 1'b0;
                    s_axi_wready  <= 1'b1;

                    if (s_axi_wvalid && s_axi_wready) begin

                        write_addr <= saved_awaddr;
                        write_data <= s_axi_wdata;

                       if(saved_ram_sel)
    ram_wr_en <= 1'b1;

else if(saved_gpio_sel)
    gpio_wr_en <= 1'b1;

else if(saved_timer_sel)
    timer_wr_en <= 1'b1;

else if(saved_uart_sel)
    uart_wr_en <= 1'b1;

else if(saved_spi_sel)
    spi_wr_en <= 1'b1;

else if(saved_i2c_sel)
    i2c_wr_en <= 1'b1;

else if(saved_dma_sel)
    dma_wr_en <= 1'b1;

else if(saved_interrupt_sel)
    interrupt_wr_en <= 1'b1;

                    end

                end

                //--------------------------------------------------
                // WRITE RESPONSE
                //--------------------------------------------------

                WRITE_RESP: begin

                    s_axi_wready <= 1'b0;

                    if (!s_axi_bvalid) begin

                        // Only RAM/cache has real multi-cycle
                        // latency (backed by SDRAM); every other
                        // peripheral is genuinely always-ready, so
                        // only gate completion on ram_ready when
                        // RAM was the selected target.
                        if (!saved_ram_sel || ram_ready) begin

                            s_axi_bvalid <= 1'b1;
                            s_axi_bresp  <= `AXI_RESP_OKAY;

                        end

                    end

                    else if (s_axi_bready) begin

                        s_axi_bvalid <= 1'b0;

                    end
                  s_axi_awready <= 1'b0;

                end

            endcase

        end

    end



endmodule

//.........................................................................................
`timescale 1ns/1ps

`include "soc_pkg.vh"

module axi_read_fsm (

    input wire clk,
    input wire rst_n,

    //----------------------------------------------------------
    // AXI Read Address Channel
    //----------------------------------------------------------

    input  wire [31:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output reg         s_axi_arready,

    //----------------------------------------------------------
    // AXI Read Data Channel
    //----------------------------------------------------------

    output reg [31:0]  s_axi_rdata,
    output reg [1:0]   s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready,

    //----------------------------------------------------------
    // Slave Selects
    //----------------------------------------------------------

    input wire ram_sel,
    input wire gpio_sel,
    input wire timer_sel,
    input wire uart_sel,
    input wire spi_sel,
    input wire i2c_sel,
    input wire dma_sel,
    input wire interrupt_sel,

    //----------------------------------------------------------
    // RAM Ready
    //----------------------------------------------------------

    input wire ram_ready,

    //----------------------------------------------------------
    // Peripheral Read Data
    //----------------------------------------------------------

    input wire [31:0] ram_rdata,
    input wire [31:0] gpio_rdata,
    input wire [31:0] timer_rdata,
    input wire [31:0] uart_rdata,
    input wire [31:0] spi_rdata,
    input wire [31:0] i2c_rdata,
    input wire [31:0] dma_rdata,
    input wire [31:0] interrupt_rdata,

    //----------------------------------------------------------
    // Peripheral Read Enables
    //----------------------------------------------------------

    output reg ram_rd_en,
    output reg gpio_rd_en,
    output reg timer_rd_en,
    output reg uart_rd_en,
    output reg spi_rd_en,
    output reg i2c_rd_en,
    output reg dma_rd_en,
    output reg interrupt_rd_en,

    //----------------------------------------------------------
    // Read Address
    //----------------------------------------------------------

    output reg [31:0] read_addr

);

    //----------------------------------------------------------
    // FSM States
    //----------------------------------------------------------

    localparam IDLE      = 2'b00;
    localparam READ_DATA = 2'b01;
    localparam READ_WAIT = 2'b10;
    localparam READ_RESP = 2'b11;

    reg [1:0] state;
    reg [1:0] next_state;

    //----------------------------------------------------------
    // Saved Address
    //----------------------------------------------------------

    reg [31:0] saved_araddr;

    //----------------------------------------------------------
    // State Register
    //----------------------------------------------------------

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;

    end

    //----------------------------------------------------------
    // Next-State Logic
    //----------------------------------------------------------

    always @(*) begin

        next_state = state;

        case (state)

            IDLE: begin

                if (s_axi_arvalid && s_axi_arready)
                    next_state = READ_DATA;

            end

            READ_DATA: begin

                next_state = READ_WAIT;

            end

            READ_WAIT: begin

                next_state = READ_RESP;

            end

            READ_RESP: begin

                if (s_axi_rvalid && s_axi_rready)
                    next_state = IDLE;

            end

            default:
                next_state = IDLE;

        endcase

    end

    //----------------------------------------------------------
    // Output / FSM Logic
    //----------------------------------------------------------

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            s_axi_arready <= 1'b0;

            s_axi_rdata   <= 32'd0;
            s_axi_rresp   <= `AXI_RESP_OKAY;
            s_axi_rvalid  <= 1'b0;

            ram_rd_en       <= 1'b0;
            gpio_rd_en      <= 1'b0;
            timer_rd_en     <= 1'b0;
            uart_rd_en      <= 1'b0;
            spi_rd_en       <= 1'b0;
            i2c_rd_en       <= 1'b0;
            dma_rd_en       <= 1'b0;
            interrupt_rd_en <= 1'b0;

            read_addr      <= 32'd0;
            saved_araddr   <= 32'd0;

        end

        else begin

            //--------------------------------------------------
            // Default one-cycle read enables
            //--------------------------------------------------

            ram_rd_en       <= 1'b0;
            gpio_rd_en      <= 1'b0;
            timer_rd_en     <= 1'b0;
            uart_rd_en      <= 1'b0;
            spi_rd_en       <= 1'b0;
            i2c_rd_en       <= 1'b0;
            dma_rd_en       <= 1'b0;
            interrupt_rd_en <= 1'b0;

            case (state)

                //------------------------------------------------
                // IDLE
                //------------------------------------------------

                IDLE: begin

                    s_axi_arready <= 1'b1;
                    s_axi_rvalid  <= 1'b0;

                    if (s_axi_arvalid) begin
                        saved_araddr <= s_axi_araddr;
                    end

                end

                //------------------------------------------------
                // READ DATA
                //------------------------------------------------

                READ_DATA: begin

                    s_axi_arready <= 1'b0;

                    read_addr <= saved_araddr;

                    if (ram_sel)
                        ram_rd_en <= 1'b1;

                    else if (gpio_sel)
                        gpio_rd_en <= 1'b1;

                    else if (timer_sel)
                        timer_rd_en <= 1'b1;

                    else if (uart_sel)
                        uart_rd_en <= 1'b1;

                    else if (spi_sel)
                        spi_rd_en <= 1'b1;

                    else if (i2c_sel)
                        i2c_rd_en <= 1'b1;

                    else if (dma_sel)
                        dma_rd_en <= 1'b1;

                    else if (interrupt_sel)
                        interrupt_rd_en <= 1'b1;

                end

                //------------------------------------------------
                // READ WAIT
                //------------------------------------------------

                READ_WAIT: begin

                    /*
                     * RAM may require multiple cycles.
                     * Other peripherals are currently
                     * treated as zero/additional-cycle latency.
                     */

                    if (ram_sel)
                        ram_rd_en <= 1'b1;

                    else if (gpio_sel)
                        gpio_rd_en <= 1'b1;

                    else if (timer_sel)
                        timer_rd_en <= 1'b1;

                    else if (uart_sel)
                        uart_rd_en <= 1'b1;

                    else if (spi_sel)
                        spi_rd_en <= 1'b1;

                    else if (i2c_sel)
                        i2c_rd_en <= 1'b1;

                    else if (dma_sel)
                        dma_rd_en <= 1'b1;

                    else if (interrupt_sel)
                        interrupt_rd_en <= 1'b1;

                end

                //------------------------------------------------
                // READ RESPONSE
                //------------------------------------------------

                READ_RESP: begin

                    //------------------------------------------------
                    // Select returned data
                    //------------------------------------------------

                    if (!s_axi_rvalid) begin

                        if (ram_sel)
                            s_axi_rdata <= ram_rdata;

                        else if (gpio_sel)
                            s_axi_rdata <= gpio_rdata;

                        else if (timer_sel)
                            s_axi_rdata <= timer_rdata;

                        else if (uart_sel)
                            s_axi_rdata <= uart_rdata;

                        else if (spi_sel)
                            s_axi_rdata <= spi_rdata;

                        else if (i2c_sel)
                            s_axi_rdata <= i2c_rdata;

                        else if (dma_sel)
                            s_axi_rdata <= dma_rdata;

                        else if (interrupt_sel)
                            s_axi_rdata <= interrupt_rdata;

                        else
                            s_axi_rdata <= 32'd0;

                        //------------------------------------------------
                        // RAM may be multi-cycle
                        //------------------------------------------------

                        if (!ram_sel || ram_ready) begin

                            s_axi_rvalid <= 1'b1;
                            s_axi_rresp  <= `AXI_RESP_OKAY;

                        end

                    end

                    //------------------------------------------------
                    // AXI Master accepted response
                    //------------------------------------------------

                    else if (s_axi_rready) begin

                        s_axi_rvalid <= 1'b0;

                    end

                end

            endcase

        end

    end

endmodule
//..................................(main)........................................................
`include "soc_pkg.vh"

module axi_interconnect (

    input wire clk,
    input wire rst_n,

    //---------------------------------------------------------
    // AXI Master Interface (from cpu_axi_master)
    //---------------------------------------------------------

    // Write Address Channel

    input  wire [31:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output wire        s_axi_awready,

    // Write Data Channel

    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output wire        s_axi_wready,

    // Write Response Channel

    output wire [1:0]  s_axi_bresp,
    output wire        s_axi_bvalid,
    input  wire        s_axi_bready,

    // Read Address Channel

    input  wire [31:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,

    // Read Data Channel

    output wire [31:0] s_axi_rdata,
    output wire [1:0]  s_axi_rresp,
    output wire        s_axi_rvalid,
    input  wire        s_axi_rready,

    //---------------------------------------------------------
    // Peripheral Interface
    //---------------------------------------------------------

    input wire [31:0] ram_rdata,
    input wire [31:0] gpio_rdata,
    input wire [31:0] timer_rdata,
    input wire [31:0] uart_rdata,
    input  wire [31:0] spi_rdata,
    input  wire [31:0] i2c_rdata,
    input wire [31:0] interrupt_rdata,
    input wire [31:0] dma_rdata,

    input wire         ram_ready,

    output wire        ram_wr_en,
    output wire        gpio_wr_en,
    output wire        timer_wr_en,
    output wire        uart_wr_en,

    output wire        ram_rd_en,
    output wire        gpio_rd_en,
    output wire        timer_rd_en,
    output wire        uart_rd_en,

    output wire [31:0] write_addr,
    output wire [31:0] write_data,
    output wire [31:0] read_addr,

output wire spi_wr_en,
output wire spi_rd_en,

output wire i2c_wr_en,
output wire i2c_rd_en,

output wire dma_wr_en,
output wire dma_rd_en,


output wire interrupt_wr_en,
output wire interrupt_rd_en

);

    //---------------------------------------------------------
    // Write Decoder Signals
    //---------------------------------------------------------

    wire ram_wr_sel;
    wire gpio_wr_sel;
    wire timer_wr_sel;
    wire uart_wr_sel;
    wire spi_wr_sel;
    wire i2c_wr_sel;
    wire dma_wr_sel;
    wire interrupt_wr_sel;

    //---------------------------------------------------------
    // Read Decoder Signals
    //---------------------------------------------------------

    wire ram_rd_sel;
    wire gpio_rd_sel;
    wire timer_rd_sel;
    wire uart_rd_sel;
    wire spi_rd_sel;
    wire i2c_rd_sel;
    wire dma_rd_sel;
    wire interrupt_rd_sel;

    //---------------------------------------------------------
    // Write Address Decoder
    //---------------------------------------------------------

axi_address_decoder WRITE_DECODER (

    .addr(s_axi_awaddr),

    .ram_sel(ram_wr_sel),
    .gpio_sel(gpio_wr_sel),
    .timer_sel(timer_wr_sel),
    .uart_sel(uart_wr_sel),

    .spi_sel(spi_wr_sel),
    .i2c_sel(i2c_wr_sel),
    .dma_sel(dma_wr_sel),
    .interrupt_sel(interrupt_wr_sel),

    .slave_id()

);

    //---------------------------------------------------------
    // Read Address Decoder
    //---------------------------------------------------------

axi_address_decoder READ_DECODER (

    .addr(s_axi_araddr),

    .ram_sel(ram_rd_sel),
    .gpio_sel(gpio_rd_sel),
    .timer_sel(timer_rd_sel),
    .uart_sel(uart_rd_sel),

    .spi_sel(spi_rd_sel),
    .i2c_sel(i2c_rd_sel),
    .dma_sel(dma_rd_sel),
    .interrupt_sel(interrupt_rd_sel),

    .slave_id()

);

    //---------------------------------------------------------
    // Write FSM
    //---------------------------------------------------------

axi_write_fsm WRITE_FSM (

    .clk(clk),
    .rst_n(rst_n),

    .s_axi_awaddr(s_axi_awaddr),
    .s_axi_awvalid(s_axi_awvalid),
    .s_axi_awready(s_axi_awready),

    .s_axi_wdata(s_axi_wdata),
    .s_axi_wstrb(s_axi_wstrb),
    .s_axi_wvalid(s_axi_wvalid),
    .s_axi_wready(s_axi_wready),

    .s_axi_bresp(s_axi_bresp),
    .s_axi_bvalid(s_axi_bvalid),
    .s_axi_bready(s_axi_bready),

    //--------------------------------------------------
    // Decoder Selects
    //--------------------------------------------------

    .ram_sel(ram_wr_sel),
    .gpio_sel(gpio_wr_sel),
    .timer_sel(timer_wr_sel),
    .uart_sel(uart_wr_sel),

    .spi_sel(spi_wr_sel),
    .i2c_sel(i2c_wr_sel),
    .dma_sel(dma_wr_sel),

    // BUGFIX: axi_write_fsm's port is named `interrupt_sel` /
    // `interrupt_wr_en`, not `intc_sel` / `intc_wr_en`. The old
    // names didn't match any port or any declared net, so Verilog
    // implicit-declared throwaway 1-bit wires here that were never
    // connected to the real interrupt_wr_sel/interrupt_wr_en signals.
    .interrupt_sel(interrupt_wr_sel),

    .ram_ready(ram_ready),

    //--------------------------------------------------
    // Peripheral Enables
    //--------------------------------------------------

    .ram_wr_en(ram_wr_en),
    .gpio_wr_en(gpio_wr_en),
    .timer_wr_en(timer_wr_en),
    .uart_wr_en(uart_wr_en),

    .spi_wr_en(spi_wr_en),
    .i2c_wr_en(i2c_wr_en),
    .dma_wr_en(dma_wr_en),
    .interrupt_wr_en(interrupt_wr_en),

    //--------------------------------------------------
    // Address/Data
    //--------------------------------------------------

    .write_addr(write_addr),
    .write_data(write_data)

);

    //---------------------------------------------------------
    // Read FSM
    //---------------------------------------------------------
    // BUGFIX: this instantiation was missing entirely. Without it,
    // every read-channel output of axi_interconnect (s_axi_arready,
    // s_axi_rdata/rresp/rvalid, all *_rd_en, and read_addr) was an
    // undriven wire (floating 'z), so any AXI read from the CPU
    // would stall forever waiting on ARREADY -- this is the root
    // cause of a Phase 7 hang/timeout independent of the interrupt
    // naming bug above.
    //---------------------------------------------------------

axi_read_fsm READ_FSM (

    .clk(clk),
    .rst_n(rst_n),

    .s_axi_araddr(s_axi_araddr),
    .s_axi_arvalid(s_axi_arvalid),
    .s_axi_arready(s_axi_arready),

    .s_axi_rdata(s_axi_rdata),
    .s_axi_rresp(s_axi_rresp),
    .s_axi_rvalid(s_axi_rvalid),
    .s_axi_rready(s_axi_rready),

    //--------------------------------------------------
    // Decoder Selects
    //--------------------------------------------------

    .ram_sel(ram_rd_sel),
    .gpio_sel(gpio_rd_sel),
    .timer_sel(timer_rd_sel),
    .uart_sel(uart_rd_sel),

    .spi_sel(spi_rd_sel),
    .i2c_sel(i2c_rd_sel),
    .dma_sel(dma_rd_sel),
    .interrupt_sel(interrupt_rd_sel),

    .ram_ready(ram_ready),

    //--------------------------------------------------
    // Peripheral Read Data
    //--------------------------------------------------

    .ram_rdata(ram_rdata),
    .gpio_rdata(gpio_rdata),
    .timer_rdata(timer_rdata),
    .uart_rdata(uart_rdata),
    .spi_rdata(spi_rdata),
    .i2c_rdata(i2c_rdata),
    .dma_rdata(dma_rdata),
    .interrupt_rdata(interrupt_rdata),

    //--------------------------------------------------
    // Peripheral Read Enables
    //--------------------------------------------------

    .ram_rd_en(ram_rd_en),
    .gpio_rd_en(gpio_rd_en),
    .timer_rd_en(timer_rd_en),
    .uart_rd_en(uart_rd_en),
    .spi_rd_en(spi_rd_en),
    .i2c_rd_en(i2c_rd_en),
    .dma_rd_en(dma_rd_en),
    .interrupt_rd_en(interrupt_rd_en),

    .read_addr(read_addr)

);

endmodule