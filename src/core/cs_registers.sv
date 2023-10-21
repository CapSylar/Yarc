// contains all CS registers

module cs_registers
(
    input clk_i,
    input rstn_i,

    // read port
    input csr_re_i,
    input cs_raddr_i,
    output csr_rdata_o,

    // write port
    input csr_we_i,
    input csr_waddr_i,
    input csr_wdata_i
);

logic [31:0] misa_q;
logic [31:0] mvendorid_q;
logic [31:0] marchid_q;
logic [31:0] mimpid_q;

// CS Registers
// MISA: Machine ISA Register
localparam bit [31:0] MISA_VALUE = 
    (1 << 8) | // I - RV32I
    (1 << 30); // M-XLEN = 1 => 32-bit

csr #(.Width(32), .ResetValue(MISA_VALUE)) csr_misa
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .wr_en_i('0), // Read Only
    .wr_data_i('0),
    .rd_data_o(misa_q)
);

// MVENDORID: Machine Vendor ID Register
localparam bit [31:0] MVENDORID = '0; // Non-commercial implementation

csr #(.Width(32), .ResetValue(MVENDORID)) csr_mvendorid
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .wr_en_i('0), // Read Only
    .wr_data_i('0),
    .rd_data_o(mvendorid_q)
);

// MARCHID: Machine Architecture ID Register
localparam bit [31:0] ARCH_ID = 32'd0; // Microarchiture ID

csr #(.Width(32), .ResetValue(ARCH_ID)) csr_marchid
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .wr_en_i('0), // Read Only
    .wr_data_i('0),
    .rd_data_o(marchid_q)
);

// MIMPID: Machine Implementation ID Register
localparam bit [31:0] MIMP_ID = 32'd1;

csr #(.Width(32), .ResetValue(MIMP_ID)) csr_mimpid
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .wr_en_i('0), // Read Only
    .wr_data_i('0),
    .rd_data_o(mimpid_q)
);

// MHARTID: Hart ID Register
csr #(.Width(32), .ResetValue('0)) csr_mhartid
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .wr_en_i(mhartid_wen),
    .wr_data_i(mhartid_d),
    .rd_data_o(mhartid_q)
);

// MSTATUS: Machine Status Register
csr #(.Width(32), .ResetValue('0)) csr_mstatus
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .wr_en_i(mstatus_wen),
    .wr_data_i(mstatus_d),
    .rd_data_o(mstatus_q)
);

// MSTATUSH: Machine Status Register
csr #(.Width(32), .ResetValue('0)) csr_mstatush
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .wr_en_i('0),
    .wr_data_i('0),
    .rd_data_o(mstatush_q)
);

// MTVEC: Machine Trap-Vector Base-Address Register
csr #(.Width(32), .ResetValue('0)) csr_mtvec
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .wr_en_i(mtvec_wen),
    .wr_data_i(mtvec_d),
    .rd_data_o(mtvec_q)
);

// MIP: Machine Interrupt Pending Register
csr #(.Width(32), .ResetValue('0)) csr_mip
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .wr_en_i(mip_wen),
    .wr_data_i(mip_d),
    .rd_data_o(mip_q)
);

// MIE: Machine Interrupt Enable Register
csr #(.Width(32), .ResetValue('0)) csr_mie
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .wr_en_i(mie_wen),
    .wr_data_i(mie_d),
    .rd_data_o(mie_q)
);

// MCYCLE: Machine Cycle Register
csr #(.Width(64), .ResetValue('0)) csr_mcycle
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .wr_en_i(mcycle_wen),
    .wr_data_i(mcycle_d),
    .rd_data_o(mcycle_q)
);

// MINSTRET: Machine Instruction Retired Register
csr #(.Width(64), .ResetValue('0)) csr_minstret
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .wr_en_i(minstret_wen),
    .wr_data_i(minstret_d),
    .rd_data_o(minstret_q)
);

// MCOUNTEREN: Machine Counter-Enable Register
csr #(.Width(32), .ResetValue('0)) csr_mcounteren
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .wr_en_i(mcounteren_wen),
    .wr_data_i(mcounteren_d),
    .rd_data_o(mcounteren_q)
);

// MCOUNTINHIBIT: Machine Counter-Inhibit CSR
csr #(.Width(32), .ResetValue('0)) csr_mcountinhibit
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .wr_en_i(mcountinhibit_wen),
    .wr_data_i(mcountinhibit_d),
    .rd_data_o(mcountinhibit_q)
);

// MSCRATCH: Machine Scratch Register
csr #(.Width(32), .ResetValue('0)) csr_mscratch
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .wr_en_i(mscratch_wen),
    .wr_data_i(mscratch_d),
    .rd_data_o(mscratch_q)
);

// MEPC: Machine Exception Program Counter
csr #(.Width(32), .ResetValue('0)) csr_mepc
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .wr_en_i(mepc_wen),
    .wr_data_i(mepc_d),
    .rd_data_o(mepc_q)
);

// MCAUSE: Machine Cause Register
csr #(.Width(32), .ResetValue('0)) csr_mcause
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .wr_en_i(mcause_wen),
    .wr_data_i(mcause_d),
    .rd_data_o(mcause_q)
);

// MTVAL: Machine Trap Value Register
csr #(.Width(32), .ResetValue('0)) csr_mtval
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .wr_en_i(mtval_wen),
    .wr_data_i(mtval_d),
    .rd_data_o(mtval_q)
);

endmodule: cs_registers