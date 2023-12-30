// top wrapper for the nexys video fpga board

module nexys_fpga_top
#(parameter string DMEMFILE = "/home/robin/workdir/yarc_os/build/yarc.dvmem",
 parameter string IMEMFILE = "/home/robin/workdir/yarc_os/build/yarc.ivmem")
(
    input clk,
    input cpu_resetn, // active low

    output logic [7:0] led
);

logic sys_clk;

// generate a 50Mhz clock
clk_wiz_0 clk_wiz_0_i
(
    .clk_in1(clk),
    .reset('0),
    .locked(),
    .clk_out1(sys_clk)
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
    .addr_i(imem_wb_if.addr[31:2]), // 4-byte addressable
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
    .addr_i(dmem_wb_if.addr[31:2]), // 4-byte addressable
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
    .dmem_wb(dmem_wb_if.MASTER),

    // Core <-> IMEM
    .imem_wb(imem_wb_if.MASTER),

    // Platform <-> Peripherals
    .led_status_o(led)
);

endmodule: nexys_fpga_top