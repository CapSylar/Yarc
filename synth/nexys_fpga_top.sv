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

logic imem_en;
logic [31:0] imem_raddr;
logic [31:0] imem_rdata;

// Instruction Memory
sp_mem #(.MEMFILE(IMEMFILE), .SIZE_POT(15)) imem
(
    .clk_i(sys_clk),
    .en_i(imem_en),

    .read_i(1'b1),
    .addr_i(imem_raddr[31:2]), // 4-byte addressable
    .rdata_o(imem_rdata),

    .wsel_byte_i('0),
    .wdata_i('0)
);

wishbone_if wb_if();

// Data Memory
sp_mem_wb #(.MEMFILE(DMEMFILE), .SIZE_POT(15)) dmem
(
    .clk_i(sys_clk),

    .cyc_i(wb_if.cyc),
    .stb_i(wb_if.stb),
    .lock_i(wb_if.lock),

    .we_i(wb_if.we),
    .addr_i(wb_if.addr[31:2]), // 4-byte addressable
    .sel_i(wb_if.sel),
    .wdata_i(wb_if.wdata),

    .rdata_o(wb_if.rdata),
    .rty_o(wb_if.rty),
    .ack_o(wb_if.ack),
    .stall_o(wb_if.stall),
    .err_o(wb_if.err)
);

// yarc platform
yarc_platform yarc_platform_i
(
    .clk_i(sys_clk),
    .rstn_i(rstn),

    // Core <-> Imem interface
    .imem_en_o(imem_en),
    .imem_raddr_o(imem_raddr),
    .imem_rdata_i(imem_rdata),

    // Core <-> Dmem interface
    .dmem_wb(wb_if.MASTER),

    // Platform <-> Peripherals
    .led_status_o(led)
);

endmodule: nexys_fpga_top