// top wrapper for the nexys video fpga board

module nexys_fpga_top
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

    // hdmi lvds signal outputs
	output hdmi_clk_n_o,
	output hdmi_clk_p_o,
	output [2:0] hdmi_data_n_o,
	output [2:0] hdmi_data_p_o
);

logic sys_clk;
// hdmi lines
logic pixel_clk, pixel_clk_5x;
logic hdmi_clk;
logic [2:0] hdmi_data;

// generate a 50Mhz clock
clk_wiz_0 clk_wiz_0_i
(
    .clk_in1(clk),
    .reset('0),
    .locked(),
    .clk_out1(sys_clk),
    .clk_out2(pixel_clk),
    .clk_out3(pixel_clk_5x)
);

wire external_resetn = cpu_resetn;

// create the reset signal from btnc
logic rstn;
logic [2:0] ff_sync;
always_ff@(posedge sys_clk)
begin
    {rstn, ff_sync} <= {ff_sync, external_resetn};
end

// Instruction Memory
wishbone_if imem_wb_if();

// Instruction Memory
sp_mem_wb #(.MEMFILE(IMEMFILE), .SIZE_POT(15)) imem
(
    .clk_i(sys_clk),

    .cyc_i(imem_wb_if.cyc),
    .stb_i(imem_wb_if.stb),
    .lock_i(imem_wb_if.lock),

    .we_i(imem_wb_if.we),
    .addr_i(imem_wb_if.addr), // 4-byte addressable
    .sel_i(imem_wb_if.sel),
    .wdata_i(imem_wb_if.wdata),

    .rdata_o(imem_wb_if.rdata),
    .rty_o(imem_wb_if.rty),
    .ack_o(imem_wb_if.ack),
    .stall_o(imem_wb_if.stall),
    .err_o(imem_wb_if.err)
);

wishbone_if dmem_wb_if();

// Data Memory
sp_mem_wb #(.MEMFILE(DMEMFILE), .SIZE_POT(15)) dmem
(
    .clk_i(sys_clk),

    .cyc_i(dmem_wb_if.cyc),
    .stb_i(dmem_wb_if.stb),
    .lock_i(dmem_wb_if.lock),

    .we_i(dmem_wb_if.we),
    .addr_i(dmem_wb_if.addr), // 4-byte addressable
    .sel_i(dmem_wb_if.sel),
    .wdata_i(dmem_wb_if.wdata),

    .rdata_o(dmem_wb_if.rdata),
    .rty_o(dmem_wb_if.rty),
    .ack_o(dmem_wb_if.ack),
    .stall_o(dmem_wb_if.stall),
    .err_o(dmem_wb_if.err)
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

    // Platform <-> UART
    .uart_rx_i(uart_tx_in),
    .uart_tx_o(uart_rx_out),

    // Platform <-> HDMI
    .pixel_clk_i(pixel_clk),
    .pixel_clk_5x_i(pixel_clk_5x),
    .hdmi_clk_o(hdmi_clk),
    .hdmi_data_o(hdmi_data)
);

// create differential outputs for hdmi
OBUFDS obufds_clk (.I(hdmi_clk),        .O(hdmi_clk_p_o),       .OB(hdmi_clk_n_o));
OBUFDS obufds_c0  (.I(hdmi_data[0]),    .O(hdmi_data_p_o[0]),   .OB(hdmi_data_n_o[0]));
OBUFDS obufds_c1  (.I(hdmi_data[1]),    .O(hdmi_data_p_o[1]),   .OB(hdmi_data_n_o[1]));
OBUFDS obufds_c2  (.I(hdmi_data[2]),    .O(hdmi_data_p_o[2]),   .OB(hdmi_data_n_o[2]));

endmodule: nexys_fpga_top