interface wishbone_if;

logic cyc;
logic stb;
logic lock;

logic we;
logic [31:0] addr;
logic [3:0] sel;
logic [31:0] wdata;

logic [31:0] rdata;
logic rty;
logic ack;
logic stall;
logic err;

modport MASTER (output cyc,
                output stb,
                output lock,
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
               input lock,
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