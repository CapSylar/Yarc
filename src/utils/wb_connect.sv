// cannot assign interfaces in systemverilog
// this is my answer for wishbone interfaces :)

module wb_connect
(
    wishbone_if.SLAVE wb_if_i,
    wishbone_if.MASTER wb_if_o
);

assign wb_if_o.cyc = wb_if_i.cyc;
assign wb_if_o.stb = wb_if_i.stb;
assign wb_if_o.we = wb_if_i.we;
assign wb_if_o.addr = wb_if_i.addr;
assign wb_if_o.sel = wb_if_i.sel;
assign wb_if_o.wdata = wb_if_i.wdata;

assign wb_if_i.rdata = wb_if_o.rdata;
assign wb_if_i.rty = wb_if_o.rty;
assign wb_if_i.ack = wb_if_o.ack;
assign wb_if_i.stall = wb_if_o.stall;
assign wb_if_i.err = wb_if_o.err;

endmodule: wb_connect
