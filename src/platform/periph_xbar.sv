// just a wrapper around wbxbar + some assignments
// contains the main xbar for the cpu and the peripherals
module periph_xbar
import platform_pkg::*;
(
    input clk_i,
    input rstn_i,

    wishbone_if.SLAVE master_wb_if,

    wishbone_if.MASTER slave_wb_if [PERIPH_XBAR_NUM_SLAVES]
);

// master interconnect lines
logic [PERIPH_XBAR_NUM_MASTERS-1:0] mcyc, mstb, mwe;
logic [PERIPH_XBAR_NUM_MASTERS*PERIPH_WB_AW-1:0] maddr;
logic [PERIPH_XBAR_NUM_MASTERS*PERIPH_WB_DW-1:0] mdata_o;
logic [PERIPH_XBAR_NUM_MASTERS*PERIPH_WB_DW/8-1:0] msel;
logic [PERIPH_XBAR_NUM_MASTERS-1:0] mstall, mack, merr;
logic [PERIPH_XBAR_NUM_MASTERS*PERIPH_WB_DW-1:0] mdata_i;

// slave interconnect lines
logic [PERIPH_XBAR_NUM_SLAVES-1:0] scyc, sstb, swe;
logic [PERIPH_XBAR_NUM_SLAVES*PERIPH_WB_AW-1:0] saddr;
logic [PERIPH_XBAR_NUM_SLAVES*PERIPH_WB_DW-1:0] sdata_i;
logic [PERIPH_XBAR_NUM_SLAVES*PERIPH_WB_DW/8-1:0] ssel;
logic [PERIPH_XBAR_NUM_SLAVES-1:0] sstall, sack, serr;
logic [PERIPH_XBAR_NUM_SLAVES*PERIPH_WB_DW-1:0] sdata_o;

// connect the master side to the systemverilog interfaces
assign mcyc = master_wb_if.cyc;
assign mstb = master_wb_if.stb;
assign mwe = master_wb_if.we;
assign maddr = master_wb_if.addr;
assign mdata_o = master_wb_if.wdata;
assign msel = master_wb_if.sel;

assign master_wb_if.stall = mstall;
assign master_wb_if.ack = mack;
assign master_wb_if.rdata = mdata_i;
assign master_wb_if.err = merr;

// connect the slave side to the systemverilog interfaces
generate
    for (genvar i = 0 ; i < PERIPH_XBAR_NUM_SLAVES; ++i) begin: connect_slave_wb_ifs
        assign slave_wb_if[i].cyc = scyc[i];
        assign slave_wb_if[i].stb = sstb[i];
        assign slave_wb_if[i].we = swe[i];
        assign slave_wb_if[i].addr = saddr[i*PERIPH_WB_AW +: PERIPH_WB_AW];
        assign slave_wb_if[i].wdata = sdata_i[i*PERIPH_WB_DW +: PERIPH_WB_DW];
        assign slave_wb_if[i].sel = ssel[i*PERIPH_WB_DW/8 +: PERIPH_WB_DW/8];

        assign sstall[i] = slave_wb_if[i].stall;
        assign sack[i] = slave_wb_if[i].ack;
        assign sdata_o[i*PERIPH_WB_DW +: PERIPH_WB_DW] = slave_wb_if[i].rdata;
        assign serr[i] = slave_wb_if[i].err;
    end
endgenerate

// Zipcpu wishbone crossbar
wbxbar
#(  .NM(PERIPH_XBAR_NUM_MASTERS),
    .NS(PERIPH_XBAR_NUM_SLAVES),
    .AW(PERIPH_WB_AW),
    .DW(PERIPH_WB_DW),
    .SLAVE_ADDR(PERIPH_XBAR_BASE_ADDRESSES),
    .SLAVE_MASK(PERIPH_XBAR_MASKS),
    .LGMAXBURST(PERIPH_XBAR_LGMAXBURST),
    .OPT_TIMEOUT(PERIPH_XBAR_OPT_TIMEOUT),
    .OPT_DBLBUFFER(PERIPH_XBAR_OPT_DBLBUFFER),
    .OPT_LOWPOWER(PERIPH_XBAR_OPT_LOWPOWER)
)
wbxbar_peripherals_i
(
    .i_clk(clk_i),
    .i_reset(~rstn_i),

    // master bus inputs
    .i_mcyc(mcyc),
    .i_mstb(mstb),
    .i_mwe(mwe),
    .i_maddr(maddr),
    .i_mdata(mdata_o),
    .i_msel(msel),

    // master return data
    .o_mstall(mstall),
    .o_mack(mack),
    .o_mdata(mdata_i),
    .o_merr(merr),

    .o_scyc(scyc),
    .o_sstb(sstb),
    .o_swe(swe),
    .o_saddr(saddr),
    .o_sdata(sdata_i),
    .o_ssel(ssel),

    // slave return data
    .i_sstall(sstall),
    .i_sack(sack),
    .i_sdata(sdata_o),
    .i_serr(serr)
);

endmodule: periph_xbar
