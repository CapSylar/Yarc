// just a wrapper around wbxbar
// contains the secondary crossbar which has both the cpu and video core as masters

module sec_xbar
import platform_pkg::*;
(
    input clk_i,
    input rstn_i,

    wishbone_if.SLAVE cpu_wb_if,
    wishbone_if.SLAVE video_wb_if,

    wishbone_if.MASTER slave_wb_if [SEC_XBAR_NUM_SLAVES]
);

wishbone_if #(.ADDRESS_WIDTH(SEC_WB_AW), .DATA_WIDTH(SEC_WB_DW)) cpu_wb_wide_if();

logic [MAIN_WB_AW_BYTE-$clog2(SEC_WB_DW/8)-SEC_WB_AW-1:0] ignore; // make simulator happy
// the cpu interface is 32-bit, we need to take it up to 128-bit and only then connect
// it to the crossbar
wbupsz #(.ADDRESS_WIDTH(MAIN_WB_AW_BYTE),
         .WIDE_DW(SEC_WB_DW),
         .SMALL_DW(MAIN_WB_DW),
         .OPT_LITTLE_ENDIAN(1'b1),
         .OPT_LOWPOWER(1'b0))
wbupsz_i
(
    .i_clk(clk_i),
    .i_reset(~rstn_i),

    // incoming small port
    .i_scyc(cpu_wb_if.cyc),
    .i_sstb(cpu_wb_if.stb),
    .i_swe(cpu_wb_if.we),
    .i_saddr(cpu_wb_if.addr),
    .i_sdata(cpu_wb_if.wdata),
    .i_ssel(cpu_wb_if.sel),
    .o_sstall(cpu_wb_if.stall),
    .o_sack(cpu_wb_if.ack),
    .o_sdata(cpu_wb_if.rdata),
    .o_serr(cpu_wb_if.err),

    // outgoing larger bus size port
    .o_wcyc(cpu_wb_wide_if.cyc),
    .o_wstb(cpu_wb_wide_if.stb),
    .o_wwe(cpu_wb_wide_if.we),
    .o_waddr({ignore, cpu_wb_wide_if.addr}),
    .o_wdata(cpu_wb_wide_if.wdata),
    .o_wsel(cpu_wb_wide_if.sel),
    .i_wstall(cpu_wb_wide_if.stall),
    .i_wack(cpu_wb_wide_if.ack),
    .i_wdata(cpu_wb_wide_if.rdata),
    .i_werr(cpu_wb_wide_if.err)
);

// master interconnect lines
logic [SEC_XBAR_NUM_MASTERS-1:0] mcyc, mstb, mwe;
logic [SEC_XBAR_NUM_MASTERS*SEC_WB_AW-1:0] maddr;
logic [SEC_XBAR_NUM_MASTERS*SEC_WB_DW-1:0] mdata_o;
logic [SEC_XBAR_NUM_MASTERS*SEC_WB_DW/8-1:0] msel;
logic [SEC_XBAR_NUM_MASTERS-1:0] mstall, mack, merr;
logic [SEC_XBAR_NUM_MASTERS*SEC_WB_DW-1:0] mdata_i;

// slave interconnect lines
logic [SEC_XBAR_NUM_SLAVES-1:0] scyc, sstb, swe;
logic [SEC_XBAR_NUM_SLAVES*SEC_WB_AW-1:0] saddr;
logic [SEC_XBAR_NUM_SLAVES*SEC_WB_DW-1:0] sdata_i;
logic [SEC_XBAR_NUM_SLAVES*SEC_WB_DW/8-1:0] ssel;
logic [SEC_XBAR_NUM_SLAVES-1:0] sstall, sack, serr;
logic [SEC_XBAR_NUM_SLAVES*SEC_WB_DW-1:0] sdata_o;

// shit needs to be done manually unfortunately

// for the cpu widened master interface
assign mcyc[SEC_XBAR_CPU_MASTER_IDX] = cpu_wb_wide_if.cyc;
assign mstb[SEC_XBAR_CPU_MASTER_IDX] = cpu_wb_wide_if.stb;
assign mwe[SEC_XBAR_CPU_MASTER_IDX] = cpu_wb_wide_if.we;
assign maddr[SEC_XBAR_CPU_MASTER_IDX*SEC_WB_AW +: SEC_WB_AW] = cpu_wb_wide_if.addr;
assign mdata_o[SEC_XBAR_CPU_MASTER_IDX*SEC_WB_DW +: SEC_WB_DW] = cpu_wb_wide_if.wdata;
assign msel[SEC_XBAR_CPU_MASTER_IDX*SEC_WB_DW/8 +: SEC_WB_DW/8] = cpu_wb_wide_if.sel;

assign cpu_wb_wide_if.stall = mstall[SEC_XBAR_CPU_MASTER_IDX];
assign cpu_wb_wide_if.ack = mack[SEC_XBAR_CPU_MASTER_IDX];
assign cpu_wb_wide_if.rdata = mdata_i[SEC_XBAR_CPU_MASTER_IDX*SEC_WB_DW +: SEC_WB_DW];
assign cpu_wb_wide_if.err = merr[SEC_XBAR_CPU_MASTER_IDX];
assign cpu_wb_wide_if.rty = '0;

// for the video master interface
assign mcyc[SEC_XBAR_VIDEO_MASTER_IDX] = video_wb_if.cyc;
assign mstb[SEC_XBAR_VIDEO_MASTER_IDX] = video_wb_if.stb;
assign mwe[SEC_XBAR_VIDEO_MASTER_IDX] = video_wb_if.we;
assign maddr[SEC_XBAR_VIDEO_MASTER_IDX*SEC_WB_AW +: SEC_WB_AW] = video_wb_if.addr;
assign mdata_o[SEC_XBAR_VIDEO_MASTER_IDX*SEC_WB_DW +: SEC_WB_DW] = video_wb_if.wdata;
assign msel[SEC_XBAR_VIDEO_MASTER_IDX*SEC_WB_DW/8 +: SEC_WB_DW/8] = video_wb_if.sel;

assign video_wb_if.stall = mstall[SEC_XBAR_VIDEO_MASTER_IDX];
assign video_wb_if.ack = mack[SEC_XBAR_VIDEO_MASTER_IDX];
assign video_wb_if.rdata = mdata_i[SEC_XBAR_VIDEO_MASTER_IDX*SEC_WB_DW +: SEC_WB_DW];
assign video_wb_if.err = merr[SEC_XBAR_VIDEO_MASTER_IDX];
assign video_wb_if.rty = '0;

// connect the slave wire side to the systemverilog interfaces
generate
    for (genvar i = 0 ; i < SEC_XBAR_NUM_SLAVES; ++i) begin: connect_slave_wb_ifs
        assign slave_wb_if[i].cyc = scyc[i];
        assign slave_wb_if[i].stb = sstb[i];
        assign slave_wb_if[i].we = swe[i];
        assign slave_wb_if[i].addr = saddr[i*SEC_WB_AW +: SEC_WB_AW];
        assign slave_wb_if[i].wdata = sdata_i[i*SEC_WB_DW +: SEC_WB_DW];
        assign slave_wb_if[i].sel = ssel[i*SEC_WB_DW/8 +: SEC_WB_DW/8];

        assign sstall[i] = slave_wb_if[i].stall;
        assign sack[i] = slave_wb_if[i].ack;
        assign sdata_o[i*SEC_WB_DW +: SEC_WB_DW] = slave_wb_if[i].rdata;
        assign serr[i] = slave_wb_if[i].err;
    end
endgenerate

wbxbar
#(
    .NM(SEC_XBAR_NUM_MASTERS),
    .NS(SEC_XBAR_NUM_SLAVES),
    .AW(SEC_WB_AW),
    .DW(SEC_WB_DW),
    .SLAVE_ADDR(SEC_XBAR_BASE_ADDRESSES),
    .SLAVE_MASK(SEC_XBAR_MASKS),
    .LGMAXBURST(SEC_XBAR_LGMAXBURST),
    .OPT_TIMEOUT(SEC_XBAR_OPT_TIMEOUT),
    .OPT_DBLBUFFER(SEC_XBAR_OPT_DBLBUFFER),
    .OPT_LOWPOWER(SEC_XBAR_OPT_LOWPOWER)
)
sec_wxbar_i
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

endmodule: sec_xbar
