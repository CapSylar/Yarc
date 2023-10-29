// contains all CS registers

module cs_registers
(
    input clk_i,
    input rstn_i,

    // read port
    input csr_re_i,
    input [11:0] csr_raddr_i,
    output [31:0] csr_rdata_o,

    // write port
    input csr_we_i,
    input [11:0] csr_waddr_i,
    input [31:0] csr_wdata_i
);

import csr_pkg::*;

csr_t csr_raddr, csr_waddr;
assign csr_raddr = csr_t'(csr_raddr_i);
assign csr_waddr = csr_t'(csr_waddr_i);

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

mstatus_t mstatus_d, mstatus_q;
logic mstatus_wen;
parameter mstatus_t MSTATUS_RST_VALUE = '{
    mie: 1'b0,
    mpie: 1'b1,
    mpp: PRIV_LVL_U,
    mprv: 1'b0
};

// MSTATUS: Machine Status Register
csr #(.Width($bits(mstatus_t)), .ResetValue(MSTATUS_RST_VALUE)) csr_mstatus
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .wr_en_i(mstatus_wen),
    .wr_data_i(mstatus_d),
    .rd_data_o(mstatus_q)
);

logic [31:0] mtvec_d, mtvec_q;
logic mtvec_wen;

// MTVEC: Machine Trap-Vector Base-Address Register
csr #(.Width(32), .ResetValue('0)) csr_mtvec
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .wr_en_i(mtvec_wen),
    .wr_data_i(mtvec_d),
    .rd_data_o(mtvec_q)
);

logic [31:0] mip_d, mip_q;
logic mip_wen;

// MIP: Machine Interrupt Pending Register
csr #(.Width(32), .ResetValue('0)) csr_mip
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .wr_en_i(mip_wen),
    .wr_data_i(mip_d),
    .rd_data_o(mip_q)
);

logic [31:0] mie_d, mie_q;
logic mie_wen;

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

logic mscratch_wen;
logic [31:0] mscratch_d, mscratch_q;

// MSCRATCH: Machine Scratch Register
csr #(.Width(32), .ResetValue('0)) csr_mscratch
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .wr_en_i(mscratch_wen),
    .wr_data_i(mscratch_d),
    .rd_data_o(mscratch_q)
);

logic [31:0] mepc_d, mepc_q;
logic mepc_wen;

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

logic [31:0] csr_rdata;

// read logic
always_comb begin: csr_read
    csr_rdata = '0;

    if (csr_re_i)
    begin
        unique case (csr_raddr)
            CSR_MSCRATCH: csr_rdata = mscratch_q;
            CSR_MSTATUS:
            begin
                csr_rdata[CSR_MSTATUS_MIE_BIT] = mstatus_q.mie;
                csr_rdata[CSR_MSTATUS_MPIE_BIT] = mstatus_q.mpie;
                csr_rdata[CSR_MSTATUS_MPP_BIT_HIGH:CSR_MSTATUS_MPP_BIT_LOW] = mstatus_q.mpp;
                csr_rdata[CSR_MSTATUS_MPRV_BIT] = mstatus_q.mprv;
            end
            CSR_MSTATUSH: csr_rdata = '0;
            CSR_MTVEC: csr_rdata = mtvec_q;
            CSR_MEPC: csr_rdata = mepc_q;
            CSR_MIE: csr_rdata = mie_q;
            CSR_MIP: csr_rdata = mie_q;
            CSR_MEPC: csr_rdata = mepc_q;

        endcase
    end
end

// write logic
always_comb begin: csr_write

    mscratch_wen = 1'b0;
    mscratch_d = csr_wdata_i;

    mstatus_wen = 1'b0;
    mstatus_d = mstatus_q;

    mtvec_wen = 1'b0;
    mtvec_d = mtvec_q;

    mie_wen = 1'b0;
    mie_d = mie_q;

    mepc_wen = 1'b0;
    mepc_d = mepc_q;

    if (csr_we_i)
    begin
        unique case (csr_waddr)
            CSR_MSCRATCH: mscratch_wen = 1'b1;
            CSR_MSTATUS:
            begin
                mstatus_wen = 1'b1;
                mstatus_d = '{
                    mie: csr_wdata_i[CSR_MSTATUS_MIE_BIT],
                    mpie: csr_wdata_i[CSR_MSTATUS_MPIE_BIT],
                    mpp: priv_lvl_e'(csr_wdata_i[CSR_MSTATUS_MPP_BIT_HIGH:CSR_MSTATUS_MPP_BIT_LOW]),
                    mprv: csr_wdata_i[CSR_MSTATUS_MPRV_BIT]
                };

                // TODO: illegal values ?
            end
            CSR_MTVEC:
            begin
                mtvec_wen = 1'b1;
                mtvec_d = csr_wdata_i;
            end
            CSR_MIE:
            begin
                mie_wen = 1'b1;
                mie_d = csr_wdata_i;
            end
            CSR_MEPC:
            begin
                mepc_wen = 1'b1;
                mepc_d = {csr_wdata_i[31:2], 2'b00}; // IALIGN=32
            end

        endcase
    end
end

// assign outputs
assign csr_rdata_o = csr_rdata;

endmodule: cs_registers