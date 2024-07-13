// top wrapper for the nexys video fpga board

module nexys_fpga_top
import platform_pkg::*;
import ddr3_parameters_pkg::*;
#(
 parameter string DMEMFILE = "/home/robin/workdir/yarc_os/build/bootloader.dvmem",
 parameter string IMEMFILE = "/home/robin/workdir/yarc_os/build/bootloader.ivmem")
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

    output [0:0] ddr3_odt_o,
    output ddr3_ras_o,
    output ddr3_reset_o,
    output ddr3_we_o,

    // hdmi lvds signal outputs
	output hdmi_clk_n_o,
	output hdmi_clk_p_o,
	output [2:0] hdmi_data_n_o,
	output [2:0] hdmi_data_p_o
);

logic sys_clk;
logic ddr3_clk;
logic ddr3_clk_90;
logic ddr3_ref_clk;
// hdmi lines
logic pixel_clk, pixel_clk_5x;
logic [3:0] hdmi_channel;

logic clk_locked;
logic clk_wiz0_locked;
logic clk_wiz1_locked;
logic clk_wiz2_locked;

assign clk_locked = clk_wiz0_locked & clk_wiz1_locked & clk_wiz2_locked;

wire external_resetn = cpu_resetn;
logic clk_buf;

IBUF IBUF_i (.O(clk_buf), .I(clk));

clk_wiz_0 clk_wiz_0_i
(
    .clk_in1(clk_buf),
    .reset(~external_resetn),
    .locked(clk_wiz0_locked),
    .sys_clk_o(sys_clk),

    // ddr3 memory and subsystem clocks
    .ddr3_clk_o(ddr3_clk),
    // .ddr3_ref_clk_o(ddr3_ref_clk),
    .ddr3_clk_90p_o(ddr3_clk_90)
);

clk_wiz_1 clk_wiz_1_i
(
    .clk_in1(clk_buf),
    .reset(~external_resetn),
    .locked(clk_wiz1_locked),

    .ddr3_ref_clk_o(ddr3_ref_clk)
);

clk_wiz_2 clk_wiz_2_i
(
    .clk_in1(clk_buf),
    .reset(~external_resetn),
    .locked(clk_wiz2_locked),

    // hdmi clocks
    .pixel_clk_o(pixel_clk),
    .pixel_clk_5x_o(pixel_clk_5x)
);

// create the reset signal from btnc
logic rstn;
logic [2:0] ff_sync_clk;
// async assert, synchronous deassert
always_ff@(posedge sys_clk or negedge external_resetn)
begin
    if (!external_resetn) begin
        ff_sync_clk <= '0;
    end else begin
        ff_sync_clk <= {ff_sync_clk[1:0], clk_locked};
    end
end

// reset from button or when clk is not locked
assign rstn = ff_sync_clk[2];

logic [2:0] ff_sync_pixel_clk;
always_ff@(posedge pixel_clk or negedge external_resetn)
begin
    if (!external_resetn) begin
        ff_sync_pixel_clk <= '0;
    end else begin
        ff_sync_pixel_clk <= {ff_sync_pixel_clk[1:0], clk_locked};
    end
end

assign pixel_rstn = ff_sync_pixel_clk[2];

// Instruction Memory
wishbone_if #(.ADDRESS_WIDTH(MAIN_WB_AW), .DATA_WIDTH(MAIN_WB_DW)) imem_wb_if();
wishbone_if #(.ADDRESS_WIDTH(MAIN_WB_AW), .DATA_WIDTH(MAIN_WB_DW)) imem_rw_wb_if();

// Instruction Memory
dp_mem_wb #(.MEMFILE(IMEMFILE), .SIZE_POT_WORDS(IMEM_SIZE_WORDS_POT), .DATA_WIDTH(MAIN_WB_DW)) imem
(
    .clk_i(sys_clk),
    .rstn_i(rstn),

    .wb_if1(imem_wb_if),

    .wb_if2(imem_rw_wb_if)
);

wishbone_if #(.ADDRESS_WIDTH(MAIN_WB_AW), .DATA_WIDTH(MAIN_WB_DW)) dmem_wb_if();

// Data Memory
sp_mem_wb #(.MEMFILE(DMEMFILE), .SIZE_POT_WORDS(DMEM_SIZE_WORDS_POT), .DATA_WIDTH(MAIN_WB_DW)) dmem
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
wishbone_if #(.ADDRESS_WIDTH(SEC_WB_AW), .DATA_WIDTH(SEC_WB_DW)) ddr3_wb_if();

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
    .wb_if(ddr3_wb_if),

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
    .imem_wb_if(imem_wb_if),
    .imem_rw_wb_if(imem_rw_wb_if),

    // Platform <-> DDR3
    .fb_wb_if(ddr3_wb_if),

    // Platform <-> Peripherals
    .led_status_o(led),

    // Platform <-> UART
    .uart_rx_i(uart_tx_in),
    .uart_tx_o(uart_rx_out),

    // Platform <-> HDMI
    .pixel_clk_i(pixel_clk),
    .pixel_rstn_i(pixel_rstn),
    .pixel_clk_5x_i(pixel_clk_5x),
    .hdmi_channel_o(hdmi_channel)
);

// create differential outputs for hdmi
OBUFDS obufds_clk (.I(hdmi_channel[3]),    .O(hdmi_clk_p_o),       .OB(hdmi_clk_n_o));
OBUFDS obufds_c0  (.I(hdmi_channel[0]),    .O(hdmi_data_p_o[0]),   .OB(hdmi_data_n_o[0]));
OBUFDS obufds_c1  (.I(hdmi_channel[1]),    .O(hdmi_data_p_o[1]),   .OB(hdmi_data_n_o[1]));
OBUFDS obufds_c2  (.I(hdmi_channel[2]),    .O(hdmi_data_p_o[2]),   .OB(hdmi_data_n_o[2]));

endmodule: nexys_fpga_top
