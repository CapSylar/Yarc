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

logic [31:0] dmem_addr;
logic dmem_read;
logic [31:0] dmem_rdata;
logic [3:0] dmem_wsel_byte;
logic [31:0] dmem_wdata;
logic dmem_en;

// Data Memory
sp_mem #(.MEMFILE(DMEMFILE), .SIZE_POT(15)) dmem
(
    .clk_i(sys_clk),
    .en_i(dmem_en),

    .read_i(dmem_read),
    .addr_i(dmem_addr[31:2]), // 4-byte addressable
    .rdata_o(dmem_rdata),

    .wsel_byte_i(dmem_wsel_byte),
    .wdata_i(dmem_wdata)
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
    .dmem_en_o(dmem_en),
    .dmem_addr_o(dmem_addr),
    // read port
    .dmem_read_o(dmem_read),
    .dmem_rdata_i(dmem_rdata),
    // write port
    .dmem_wsel_byte_o(dmem_wsel_byte),
    .dmem_wdata_o(dmem_wdata),

    // Platform <-> Peripherals
    .led_status_o(led)
);

endmodule: nexys_fpga_top