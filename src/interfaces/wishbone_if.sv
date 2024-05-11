interface wishbone_if
#(parameter int ADDRESS_WIDTH = 32, parameter int DATA_WIDTH = 32);

logic cyc;
logic stb;

logic we;
logic [ADDRESS_WIDTH-1:0] addr;
logic [(DATA_WIDTH/8)-1:0] sel;
logic [DATA_WIDTH-1:0] wdata;

logic [DATA_WIDTH-1:0] rdata;
logic rty;
logic ack;
logic stall;
logic err;

modport MASTER (output cyc,
                output stb,
                output we,
                output addr,
                output sel,
                output wdata,
                input rdata,
                input rty,
                input ack,
                input stall,
                input err);

modport SLAVE (input cyc,
               input stb,
               input we,
               input addr,
               input sel,
               input wdata,
               output rdata,
               output rty,
               output ack,
               output stall,
               output err);

endinterface: wishbone_if
