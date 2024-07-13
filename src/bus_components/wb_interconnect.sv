// a dead simple wishbone interconnect
// supports a single master and N slaves
// does not protect the master when it addresses a second slave before the ack from the first arrives
// flags and error when a non-existant slave is addressed

module wb_interconnect
#(parameter int NUM_SLAVES = 2,
parameter int AW = 0,
parameter bit [AW-1:0] START_ADDRESS[NUM_SLAVES],
parameter bit [AW-1:0] MASK[NUM_SLAVES])
(
    input clk_i,
    input rstn_i,

    // interconnect slave interface
    wishbone_if.SLAVE intercon_if,

    // slave facing interfaces
    wishbone_if.MASTER wb_if[NUM_SLAVES]
);

logic [31:0] rdata_d, rdata_q;
logic ack_d, ack_q, stall, error;

logic slave_valid;
logic [$clog2(NUM_SLAVES)-1:0] slave_index;

logic trans_valid;
assign trans_valid = intercon_if.cyc & intercon_if.stb;

// determine if a slave is addressed

logic [NUM_SLAVES-1:0] addressed;

generate
    for (genvar i = 0; i < NUM_SLAVES; ++i)
        assign addressed[i] = ((wb_if[i].addr & MASK[i]) == START_ADDRESS[i]);
endgenerate

assign slave_valid = |addressed;

always_comb
begin
    slave_index = '0;

    for (int i = 0; i < NUM_SLAVES; ++i)
        if (addressed[i])
        begin
            slave_index = i[$bits(slave_index)-1:0];
            break;
        end
end

// extract some signals from the array of interfaces into separate vectors
// so we can use them in always_comb blocks
logic [NUM_SLAVES-1:0] slave_ack;
logic [NUM_SLAVES-1:0] slave_stall;
logic [31:0] slave_rdata [NUM_SLAVES];

generate
    for (genvar i = 0; i < NUM_SLAVES; ++i)
    begin
        assign slave_ack[i] = wb_if[i].ack;
        assign slave_stall[i] = wb_if[i].stall;
        assign slave_rdata[i] = wb_if[i].rdata;
    end
endgenerate

// determine rdata
always_comb
begin
    rdata_d = '0;

    for (int i = 0; i < NUM_SLAVES; ++i)
        if (slave_ack[i])
            rdata_d = slave_rdata[i];
end

// always_ff @(posedge clk_i)
//     if (!rstn_i) rdata_q <= '0;
//     else         rdata_q <= rdata_d;

always_comb
begin
    ack_d = '0;

    for (int i = 0; i < NUM_SLAVES; ++i)
        if (slave_ack[i])
            ack_d = 1'b1;
end

// always_ff @(posedge clk_i)
//     if (!rstn_i) ack_q <= '0;
//     else         ack_q <= ack_d;

always_comb
begin
    stall = '0;

    for (int i = 0; i < NUM_SLAVES; ++i)
        if (slave_stall[i])
            stall = 1'b1;
end

assign error = trans_valid & !slave_valid;

// wishbone interface with master
assign intercon_if.rdata = rdata_d;
assign intercon_if.rty = '0;
assign intercon_if.ack = ack_d;
assign intercon_if.stall = stall;
assign intercon_if.err = error;

// wishbone interface with slaves connections

generate
    for (genvar i = 0; i < NUM_SLAVES; ++i)
    begin: slave_connections
        assign wb_if[i].cyc = intercon_if.cyc;
        assign wb_if[i].stb = intercon_if.stb & addressed[i];

        assign wb_if[i].we = intercon_if.we;
        assign wb_if[i].addr = intercon_if.addr;
        assign wb_if[i].sel = intercon_if.sel;
        assign wb_if[i].wdata =  intercon_if.wdata;
    end
endgenerate

endmodule: wb_interconnect
