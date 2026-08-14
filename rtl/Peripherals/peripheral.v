`timescale 1ns/1ps
//--------------------------------------------------------------------------
//                     Tiny SoC architecture
//--------------------------------------------------------------------------

`include "soc_pkg.vh"

module instruction_rom #(
    parameter DEPTH = `ROM_DEPTH
)(
    input  wire [`ADDR_WIDTH-1:0] addr,
    output reg  [`DATA_WIDTH-1:0] instr
);

    //---------------------------------------------------------
    // ROM Array
    //---------------------------------------------------------

    reg [`DATA_WIDTH-1:0] memory [0:DEPTH-1];

    wire [$clog2(DEPTH)-1:0] word_addr;

    assign word_addr = addr[$clog2(DEPTH)+1:2];


    //---------------------------------------------------------
    // Instruction Fetch
    //---------------------------------------------------------

always @(*) begin
    instr = memory[word_addr];
end


    //---------------------------------------------------------
    // Initialize ROM
    //---------------------------------------------------------

    integer i;

    initial begin

        // Fill entire ROM with NOPs

        for (i = 0; i < DEPTH; i = i + 1)
            memory[i] = 32'h00000013;

        // Load program

        $readmemh("program.mem", memory);

    end

endmodule

//..........................................................................

`include "soc_pkg.vh"

module gpio #(

    parameter WIDTH = `DATA_WIDTH

)(

    input wire clk,
    input wire rst_n,

    //---------------------------------------------------------
    // AXI Write Interface
    //---------------------------------------------------------

    input wire             wr_en,
    input wire [WIDTH-1:0] wdata,

    //---------------------------------------------------------
    // AXI Read Interface
    //---------------------------------------------------------

    input wire             rd_en,
    output reg [WIDTH-1:0] rdata,

    //---------------------------------------------------------
    // External GPIO
    //---------------------------------------------------------

    input wire [WIDTH-1:0] gpio_in,
    output reg [WIDTH-1:0] gpio_out

);

    //---------------------------------------------------------
    // GPIO Output Register
    //---------------------------------------------------------

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            gpio_out <= {WIDTH{1'b0}};

        end

        else if (wr_en) begin

            gpio_out <= wdata;


        end

    end

//---------------------------------------------------------
// GPIO Read Logic
//---------------------------------------------------------

always @(posedge clk or negedge rst_n) begin

    if (!rst_n)

        rdata <= {WIDTH{1'b0}};

    else if (rd_en)

        rdata <= gpio_out;

end

endmodule

//...........................................................................
`include "soc_pkg.vh"

module timer #(

    parameter WIDTH = `DATA_WIDTH

)(

    input  wire                 clk,
    input  wire                 rst_n,

    //---------------------------------------------------------
    // AXI-Lite Interface
    //---------------------------------------------------------

    input  wire                 wr_en,
    input  wire                 rd_en,
    input  wire [WIDTH-1:0]     wdata,

    output reg  [WIDTH-1:0]     rdata,

    //---------------------------------------------------------
    // Timer Interrupt
    //---------------------------------------------------------

    output reg                  irq

);

    //---------------------------------------------------------
    // Timer Registers
    //---------------------------------------------------------

    reg [WIDTH-1:0] timer_count;
    reg [WIDTH-1:0] timer_compare;
    reg             timer_enable;

    //---------------------------------------------------------
    // Write Logic
    //---------------------------------------------------------

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            timer_compare <= {WIDTH{1'b0}};
            timer_enable  <= 1'b0;

        end

        else begin

            if (wr_en) begin

                timer_compare <= wdata;
                timer_enable  <= 1'b1;


            end

            else if (timer_enable &&
              (timer_count >= timer_compare)) begin

                timer_enable <= 1'b0;

            end

        end

    end

    //---------------------------------------------------------
    // Counter Logic
    //---------------------------------------------------------

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n)

            timer_count <= {WIDTH{1'b0}};

        else if (timer_enable)

            timer_count <= timer_count + 1'b1;

        else

            timer_count <= {WIDTH{1'b0}};

    end

    //---------------------------------------------------------
    // Interrupt Logic
    //---------------------------------------------------------

    always @(posedge clk or negedge rst_n) begin

     if (!rst_n)

         irq <= 1'b0;

     else if (timer_enable &&
              (timer_count >= timer_compare))

         irq <= 1'b1;

     else

         irq <= 1'b0;

    end

//---------------------------------------------------------
// Read Logic
//---------------------------------------------------------

always @(posedge clk or negedge rst_n) begin

    if (!rst_n)

        rdata <= {WIDTH{1'b0}};

    else if (rd_en)

        rdata <= timer_count;

end



endmodule

//...........................................................................
`include "soc_pkg.vh"

module uart #(

    parameter WIDTH = `DATA_WIDTH

)(

    input  wire                 clk,
    input  wire                 rst_n,

    //---------------------------------------------------------
    // AXI-Lite Interface
    //---------------------------------------------------------

    input  wire                 wr_en,
    input  wire                 rd_en,
    input  wire [WIDTH-1:0]     wdata,

    output reg  [WIDTH-1:0]     rdata,

    //---------------------------------------------------------
    // UART Pins
    //---------------------------------------------------------

    input  wire                 rx,
    output reg                  tx

);

    //---------------------------------------------------------
    // UART Registers
    //---------------------------------------------------------

    reg [7:0] tx_reg;
    reg [7:0] rx_reg;

    //---------------------------------------------------------
    // Transmit Logic
    //---------------------------------------------------------

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            tx_reg <= 8'd0;
            tx     <= 1'b1;   // UART idle state

        end

        else if (wr_en) begin

            tx_reg <= wdata[7:0];

            // Temporary UART output

            tx <= wdata[0];

        end

    end

    //---------------------------------------------------------
    // Receive Logic
    //---------------------------------------------------------

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n)

            rx_reg <= 8'd0;

        else

            rx_reg <= {7'd0, rx};

    end

//---------------------------------------------------------
// Read Logic
//---------------------------------------------------------

always @(posedge clk or negedge rst_n) begin

    if (!rst_n)

        rdata <= {WIDTH{1'b0}};

    else if (rd_en)

        // Return transmitted data for testing

        rdata <= {24'd0, tx_reg};

end

endmodule

//...........................................................................
`include "soc_pkg.vh"

module data_ram #(
    parameter DEPTH = `RAM_DEPTH
)(
    input  wire                     clk,
    input  wire                     rst_n,

    input  wire                     wr_en,
    input  wire                     rd_en,

    input  wire [`ADDR_WIDTH-1:0]   addr,
    input  wire [`DATA_WIDTH-1:0]   wdata,

    output reg  [`DATA_WIDTH-1:0]   rdata
);

    //---------------------------------------------------------
    // Memory Array
    //---------------------------------------------------------

    reg [`DATA_WIDTH-1:0] memory [0:DEPTH-1];

    wire [$clog2(DEPTH)-1:0] word_addr;

    assign word_addr = addr[$clog2(DEPTH)+1:2];

    //---------------------------------------------------------
    // Initialize Memory
    //---------------------------------------------------------

    integer i;

    initial begin

        for (i = 0; i < DEPTH; i = i + 1)
            memory[i] = 32'd0;

    end

    //---------------------------------------------------------
    // Write Logic
    //---------------------------------------------------------

    always @(posedge clk) begin

        if (wr_en)
            memory[word_addr] <= wdata;

    end

    //---------------------------------------------------------
    // Read Logic
    //---------------------------------------------------------

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n)
            rdata <= 32'd0;

        else if (rd_en)
            rdata <= memory[word_addr];

    end

   

endmodule