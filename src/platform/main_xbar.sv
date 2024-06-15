// just a wrapper around wbxbar + some assignments
// contains the main xbar for the cpu and the peripherals
module main_xbar
import platform_pkg::*;
(
    input clk_i,
    input rstn_i,

    wishbone_if.SLAVE lsu_wb_if,
    wishbone_if.SLAVE instr_fetch_wb_if,

    wishbone_if.MASTER slave_wb_if [MAIN_XBAR_NUM_SLAVES]
);

// master interconnect lines
logic [MAIN_XBAR_NUM_MASTERS-1:0] mcyc, mstb, mwe;
logic [MAIN_XBAR_NUM_MASTERS*MAIN_WB_AW-1:0] maddr;
logic [MAIN_XBAR_NUM_MASTERS*MAIN_WB_DW-1:0] mdata_o;
logic [MAIN_XBAR_NUM_MASTERS*MAIN_WB_DW/8-1:0] msel;
logic [MAIN_XBAR_NUM_MASTERS-1:0] mstall, mack, merr;
logic [MAIN_XBAR_NUM_MASTERS*MAIN_WB_DW-1:0] mdata_i;

// slave interconnect lines
logic [MAIN_XBAR_NUM_SLAVES-1:0] scyc, sstb, swe;
logic [MAIN_XBAR_NUM_SLAVES*MAIN_WB_AW-1:0] saddr;
logic [MAIN_XBAR_NUM_SLAVES*MAIN_WB_DW-1:0] sdata_i;
logic [MAIN_XBAR_NUM_SLAVES*MAIN_WB_DW/8-1:0] ssel;
logic [MAIN_XBAR_NUM_SLAVES-1:0] sstall, sack, serr;
logic [MAIN_XBAR_NUM_SLAVES*MAIN_WB_DW-1:0] sdata_o;

// connect the master side to the systemverilog interfaces
// shit needs to be done manually unfortunately

// for the cpu's fetch interface
assign mcyc[MAIN_XBAR_FETCH_MASTER_IDX] = instr_fetch_wb_if.cyc;
assign mstb[MAIN_XBAR_FETCH_MASTER_IDX] = instr_fetch_wb_if.stb;
assign mwe[MAIN_XBAR_FETCH_MASTER_IDX] = instr_fetch_wb_if.we;
assign maddr[MAIN_XBAR_FETCH_MASTER_IDX*MAIN_WB_AW +: MAIN_WB_AW] = instr_fetch_wb_if.addr;
assign mdata_o[MAIN_XBAR_FETCH_MASTER_IDX*MAIN_WB_DW +: MAIN_WB_DW] = instr_fetch_wb_if.wdata;
assign msel[MAIN_XBAR_FETCH_MASTER_IDX*MAIN_WB_DW/8 +: MAIN_WB_DW/8] = instr_fetch_wb_if.sel;

assign instr_fetch_wb_if.stall = mstall[MAIN_XBAR_FETCH_MASTER_IDX];
assign instr_fetch_wb_if.ack = mack[MAIN_XBAR_FETCH_MASTER_IDX];
assign instr_fetch_wb_if.rdata = mdata_i[MAIN_XBAR_FETCH_MASTER_IDX*MAIN_WB_DW +: MAIN_WB_DW];
assign instr_fetch_wb_if.err = merr[MAIN_XBAR_FETCH_MASTER_IDX];

// for the cpu's lsu interface
assign mcyc[MAIN_XBAR_LSU_MASTER_IDX] = lsu_wb_if.cyc;
assign mstb[MAIN_XBAR_LSU_MASTER_IDX] = lsu_wb_if.stb;
assign mwe[MAIN_XBAR_LSU_MASTER_IDX] = lsu_wb_if.we;
assign maddr[MAIN_XBAR_LSU_MASTER_IDX*MAIN_WB_AW +: MAIN_WB_AW] = lsu_wb_if.addr;
assign mdata_o[MAIN_XBAR_LSU_MASTER_IDX*MAIN_WB_DW +: MAIN_WB_DW] = lsu_wb_if.wdata;
assign msel[MAIN_XBAR_LSU_MASTER_IDX*MAIN_WB_DW/8 +: MAIN_WB_DW/8] = lsu_wb_if.sel;

assign lsu_wb_if.stall = mstall[MAIN_XBAR_LSU_MASTER_IDX];
assign lsu_wb_if.ack = mack[MAIN_XBAR_LSU_MASTER_IDX];
assign lsu_wb_if.rdata = mdata_i[MAIN_XBAR_LSU_MASTER_IDX*MAIN_WB_DW +: MAIN_WB_DW];
assign lsu_wb_if.err = merr[MAIN_XBAR_LSU_MASTER_IDX];

// connect the slave side to the systemverilog interfaces
generate
    for (genvar i = 0 ; i < MAIN_XBAR_NUM_SLAVES; ++i) begin: connect_slave_wb_ifs
        assign slave_wb_if[i].cyc = scyc[i];
        assign slave_wb_if[i].stb = sstb[i];
        assign slave_wb_if[i].we = swe[i];
        assign slave_wb_if[i].addr = saddr[i*MAIN_WB_AW +: MAIN_WB_AW];
        assign slave_wb_if[i].wdata = sdata_i[i*MAIN_WB_DW +: MAIN_WB_DW];
        assign slave_wb_if[i].sel = ssel[i*MAIN_WB_DW/8 +: MAIN_WB_DW/8];

        assign sstall[i] = slave_wb_if[i].stall;
        assign sack[i] = slave_wb_if[i].ack;
        assign sdata_o[i*MAIN_WB_DW +: MAIN_WB_DW] = slave_wb_if[i].rdata;
        assign serr[i] = slave_wb_if[i].err;
    end
endgenerate

// Zipcpu wishbone crossbar
wbxbar
#(  .NM(MAIN_XBAR_NUM_MASTERS),
    .NS(MAIN_XBAR_NUM_SLAVES),
    .AW(MAIN_WB_AW),
    .DW(MAIN_WB_DW),
    .SLAVE_ADDR(MAIN_XBAR_BASE_ADDRESSES),
    .SLAVE_MASK(MAIN_XBAR_MASKS),
    .LGMAXBURST(MAIN_XBAR_LGMAXBURST),
    .OPT_TIMEOUT(MAIN_XBAR_OPT_TIMEOUT),
    .OPT_DBLBUFFER(MAIN_XBAR_OPT_DBLBUFFER),
    .OPT_LOWPOWER(MAIN_XBAR_OPT_LOWPOWER)
)
wbxbar_main_i
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

endmodule: main_xbar
