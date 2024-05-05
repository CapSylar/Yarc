// top wrapper for the nexys video fpga board

module nexys_fpga_top
import platform_pkg::*;
import ddr3_parameters_pkg::*;
#(
 parameter string DMEMFILE = "/home/robin/workdir/yarc_os/build/yarc.dvmem",
 parameter string IMEMFILE = "/home/robin/workdir/yarc_os/build/yarc.ivmem")
(
    input clk,
    input cpu_resetn, // active low

    output logic [7:0] led,

    // uart lines
    output uart_rx_out,
    input uart_tx_in,

    // ddr3 memory lines
    output [0:0] ddr3_clk_n_o,
    output [0:0] ddr3_clk_p_o,

    output [14:0] ddr3_addr_o,
    output [2:0] ddr3_ba_o,
    output ddr3_cas_o,
    output [0:0] ddr3_cke_o,
    output [1:0] ddr3_dm_o,

    inout [15:0] ddr3_dq_io,
    inout [1:0] ddr3_dqs_n_io,
    inout [1:0] ddr3_dqs_p_io,

    output ddr3_odt_o,
    output ddr3_ras_o,
    output ddr3_reset_o,
    output ddr3_we_o

    // hdmi lvds signal outputs
	// output hdmi_clk_n_o,
	// output hdmi_clk_p_o,
	// output [2:0] hdmi_data_n_o,
	// output [2:0] hdmi_data_p_o
);

logic sys_clk;
logic ddr3_clk;
logic ddr3_clk_90;
logic ddr3_ref_clk;
// hdmi lines
// logic pixel_clk, pixel_clk_5x;
// logic hdmi_clk;
// logic [2:0] hdmi_data;

wire external_resetn = cpu_resetn;

// generate a 50Mhz clock
clk_wiz_0 clk_wiz_0_i
(
    .clk_in1(clk),
    .reset(~external_resetn),
    .locked(clk_locked),
    .clk_out1(sys_clk),
    .clk_out2(ddr3_clk),
    .clk_out3(ddr3_clk_90),
    .clk_out4(ddr3_ref_clk)
);

// create the reset signal from btnc
logic rstn;
logic [2:0] ff_sync;
always_ff@(posedge sys_clk)
begin
    {rstn, ff_sync} <= {ff_sync, external_resetn};
end

// Instruction Memory
wishbone_if #(.ADDRESS_WIDTH(32), .DATA_WIDTH(32)) imem_wb_if();

// Instruction Memory
sp_mem_wb #(.MEMFILE(IMEMFILE), .SIZE_POT_WORDS(IMEM_SIZE_WORDS_POT), .DATA_WIDTH(DATA_WIDTH)) imem
(
    .clk_i(sys_clk),

    .cyc_i(imem_wb_if.cyc),
    .stb_i(imem_wb_if.stb),

    .we_i(imem_wb_if.we),
    .addr_i(imem_wb_if.addr[IMEM_SIZE_WORDS_POT-1:0]), // 4-byte addressable
    .sel_i(imem_wb_if.sel),
    .wdata_i(imem_wb_if.wdata),

    .rdata_o(imem_wb_if.rdata),
    .rty_o(imem_wb_if.rty),
    .ack_o(imem_wb_if.ack),
    .stall_o(imem_wb_if.stall),
    .err_o(imem_wb_if.err)
);

wishbone_if #(.ADDRESS_WIDTH(32), .DATA_WIDTH(32)) dmem_wb_if();

// Data Memory
sp_mem_wb #(.MEMFILE(DMEMFILE), .SIZE_POT_WORDS(DMEM_SIZE_WORDS_POT), .DATA_WIDTH(DATA_WIDTH)) dmem
(
    .clk_i(sys_clk),

    .cyc_i(dmem_wb_if.cyc),
    .stb_i(dmem_wb_if.stb),

    .we_i(dmem_wb_if.we),
    .addr_i(dmem_wb_if.addr[DMEM_SIZE_WORDS_POT-1:0]), // 4-byte addressable
    .sel_i(dmem_wb_if.sel),
    .wdata_i(dmem_wb_if.wdata),

    .rdata_o(dmem_wb_if.rdata),
    .rty_o(dmem_wb_if.rty),
    .ack_o(dmem_wb_if.ack),
    .stall_o(dmem_wb_if.stall),
    .err_o(dmem_wb_if.err)
);

// DDR3 memory
// wishbone up converter 32-bits <-> 128-bits
wishbone_if #(.ADDRESS_WIDTH(32), .DATA_WIDTH(32)) ddr3_wb_if();
wishbone_if #(.ADDRESS_WIDTH(32), .DATA_WIDTH(128)) wide_ddr3_wb_if();

wbupsz #(.ADDRESS_WIDTH(32),
         .WIDE_DW(128),
         .SMALL_DW(32),
         .OPT_LITTLE_ENDIAN(1'b1),
         .OPT_LOWPOWER(1'b0))
wbupsz_i
(
    .i_clk(sys_clk),
    .i_reset(~rstn),

    // incoming small port
    .i_scyc(ddr3_wb_if.cyc),
    .i_sstb(ddr3_wb_if.stb),
    .i_swe(ddr3_wb_if.we),
    .i_saddr(ddr3_wb_if.addr),
    .i_sdata(ddr3_wb_if.wdata),
    .i_ssel(ddr3_wb_if.sel),
    .o_sstall(ddr3_wb_if.stall),
    .o_sack(ddr3_wb_if.ack),
    .o_sdata(ddr3_wb_if.rdata),
    .o_serr(ddr3_wb_if.err),

    // outgoing larger bus size port
    .o_wcyc(wide_ddr3_wb_if.cyc),
    .o_wstb(wide_ddr3_wb_if.stb),
    .o_wwe(wide_ddr3_wb_if.we),
    .o_waddr(wide_ddr3_wb_if.addr),
    .o_wdata(wide_ddr3_wb_if.wdata),
    .o_wsel(wide_ddr3_wb_if.sel),
    .i_wstall(wide_ddr3_wb_if.stall),
    .i_wack(wide_ddr3_wb_if.ack),
    .i_wdata(wide_ddr3_wb_if.rdata),
    .i_werr(wide_ddr3_wb_if.err)
);

// ddr3 phy interface definitons
// DDR3 Controller 
yarc_ddr3_top #() yarc_ddr3_top_i
(
    // clock and reset
    .i_controller_clk(sys_clk),
    .i_ddr3_clk(ddr3_clk), //i_controller_clk has period of CONTROLLER_CLK_PERIOD, i_ddr3_clk has period of DDR3_CLK_PERIOD 
    .i_ref_clk(ddr3_ref_clk),
    .i_ddr3_clk_90(ddr3_clk_90),
    .i_rst_n(rstn && clk_locked), 

    // Wishbone inputs
    .wb_if(wide_ddr3_wb_if),

    // PHY Interface
    .o_ddr3_clk_p(ddr3_clk_p_o),
    .o_ddr3_clk_n(ddr3_clk_n_o),
    .o_ddr3_cke(ddr3_cke_o), // CKE
    .o_ddr3_cs_n(), // chip select signal
    .o_ddr3_odt(ddr3_odt_o), // on-die termination
    .o_ddr3_ras_n(ddr3_ras_o), // RAS#
    .o_ddr3_cas_n(ddr3_cas_o), // CAS#
    .o_ddr3_we_n(ddr3_we_o), // WE#
    .o_ddr3_reset_n(ddr3_reset_o),
    .o_ddr3_addr(ddr3_addr_o),
    .o_ddr3_ba_addr(ddr3_ba_o),
    .io_ddr3_dq(ddr3_dq_io),
    .io_ddr3_dqs(ddr3_dqs_p_io),
    .io_ddr3_dqs_n(ddr3_dqs_n_io),
    .o_ddr3_dm(ddr3_dm_o)
);

// yarc platform
yarc_platform yarc_platform_i
(
    .clk_i(sys_clk),
    .rstn_i(rstn),

    // Core <-> DMEM
    .dmem_wb_if(dmem_wb_if),

    // Core <-> IMEM
    .instr_fetch_wb_if(imem_wb_if),

    // Platform <-> Peripherals
    .led_status_o(led),

    // Platform <-> DDR3
    .ddr3_wb_if(ddr3_wb_if),

    // Platform <-> UART
    .uart_rx_i(uart_tx_in),
    .uart_tx_o(uart_rx_out)

    // Platform <-> HDMI
    // .pixel_clk_i(pixel_clk),
    // .pixel_clk_5x_i(pixel_clk_5x),
    // .hdmi_clk_o(hdmi_clk),
    // .hdmi_data_o(hdmi_data)
);

// create differential outputs for hdmi
// OBUFDS obufds_clk (.I(hdmi_clk),        .O(hdmi_clk_p_o),       .OB(hdmi_clk_n_o));
// OBUFDS obufds_c0  (.I(hdmi_data[0]),    .O(hdmi_data_p_o[0]),   .OB(hdmi_data_n_o[0]));
// OBUFDS obufds_c1  (.I(hdmi_data[1]),    .O(hdmi_data_p_o[1]),   .OB(hdmi_data_n_o[1]));
// OBUFDS obufds_c2  (.I(hdmi_data[2]),    .O(hdmi_data_p_o[2]),   .OB(hdmi_data_n_o[2]));

endmodule: nexys_fpga_top
