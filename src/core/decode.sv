// decode module
// takes instructions in, splits them into control signals

module decode
import riscv_pkg::*;
(
    input clk_i,
    input rstn_i,

    // register file <-> decode module
    // read port
    output [4:0] regf_rs1_addr_o,
    output [4:0] regf_rs2_addr_o,
    input [31:0] rs1_data_i,
    input [31:0] rs2_data_i,

    // csr unit <-> decode module
    // read port
    output csr_re_o, // read enable
    output [11:0] csr_raddr_o,
    input [31:0] csr_rdata_i,

    // from IF stage
    input [31:0] instr_i, // instruction
    input [31:0] pc_i, // pc of the instruction

    // ID/EX pipeline registers

    // feedback into the pipeline register
    input stall_i, // keep the same content in the registers
    input flush_i, // zero the register contents

    // for direct use by the EX stage
    output logic [31:0] pc_o, // forwarded from IF/ID
    output logic [31:0] rs1_data_o,
    output logic [31:0] rs2_data_o,
    output logic [31:0] imm_o,
    output logic [31:0] csr_rdata_o,
    output alu_oper1_src_t alu_oper1_src_o,
    output alu_oper2_src_t alu_oper2_src_o,
    output bnj_oper_t bnj_oper_o,
    output alu_oper_t alu_oper_o,
    output logic is_csr_o,

    // for the MEM stage
    output mem_oper_t mem_oper_o,
    output logic [11:0] csr_waddr_o,
    output logic csr_we_o,

    // for the WB stage
    output logic wb_use_mem_o,
    output logic write_rd_o,
    output logic [4:0] rd_addr_o,

    // used by the hazard/forwarding logic
    output logic [4:0] rs1_addr_o,
    output logic [4:0] rs2_addr_o,
    output logic id_is_csr_o, // driven combinationally

    output exc_t trap_o
);

// extract the common fields from the instruction format
opcode_t opcode;
logic [4:0] rs1, rs2, rd;
logic [2:0] func3;
logic [6:0] func7;
logic [11:0] csr_addr;

assign opcode = opcode_t'(instr_i[6:0]);
assign rd = instr_i[11:7];
assign rs1 = instr_i[19:15];
assign rs2 = instr_i[24:20];
assign func3 = instr_i[14:12];
assign func7 = instr_i[31:25];
assign csr_addr = instr_i[31:20];

// immediates
logic [31:0] imm_i, imm_s, imm_b, imm_u, imm_j;

assign imm_i = 32'(signed'(instr_i[31:20]));
assign imm_s = 32'(signed'({instr_i[31:25], instr_i[11:7]}));
assign imm_b = 32'(signed'({instr_i[31], instr_i[7], instr_i[30:25], instr_i[11:8], 1'b0}));
assign imm_u = {instr_i[31:12], 12'b0};
assign imm_j = 32'(signed'({instr_i[31], instr_i[19:12], instr_i[20], instr_i[30:21], 1'b0}));
assign imm_csr = 32'({instr_i[19:15]}); // used for immediate csr instructions

alu_oper_t alu_oper;
logic [31:0] curr_imm;
logic write_rd; // write back

alu_oper1_src_t alu_oper1_src;
alu_oper2_src_t alu_oper2_src;

bnj_oper_t bnj_oper;
logic wb_use_mem; // use memory data out to write back to the register file
mem_oper_t mem_oper; // memory operation if any

exc_t trap;
logic csr_re;
logic csr_we;
logic is_csr;

// decode
always_comb
begin : main_decode

    alu_oper1_src = OPER1_RS1;
    alu_oper2_src = OPER2_RS2;

    write_rd = '0;
    curr_imm = '0;
    bnj_oper = BNJ_NO; // no branch
    wb_use_mem = '0;
    mem_oper = MEM_NOP;

    trap = NO_TRAP;
    csr_re = '0;
    csr_we = '0;
    is_csr = '0;

    case (opcode)
        LUI:
        begin
            alu_oper1_src = OPER1_ZERO;
            alu_oper2_src = OPER2_IMM;

            curr_imm = imm_u;
            write_rd = 1;
        end

        AUIPC:
        begin
            alu_oper1_src = OPER1_PC;
            alu_oper2_src = OPER2_IMM;

            curr_imm = imm_u;
            write_rd = 1;
        end

        JAL:
        begin
            alu_oper1_src = OPER1_PC;
            alu_oper2_src = OPER2_PC_INC;

            curr_imm = imm_j;
            write_rd = 1;
            bnj_oper = BNJ_JAL;
        end

        JALR:
        begin
            alu_oper1_src = OPER1_PC;
            alu_oper2_src = OPER2_PC_INC;
            
            curr_imm = imm_i;
            write_rd = 1;
            bnj_oper = BNJ_JALR;
        end

        BRANCH:
        begin
            curr_imm = imm_b;
            bnj_oper = BNJ_BRANCH;
        end

        LOAD:
        begin
            alu_oper2_src = OPER2_IMM;
            curr_imm = imm_i;

            write_rd = 1;
            wb_use_mem = 1;

            mem_oper = mem_oper_t'({1'b0, func3});
        end

        STORE:
        begin
            alu_oper2_src = OPER2_IMM;
            curr_imm = imm_s;

            mem_oper = mem_oper_t'({1'b1, func3});
        end

        ARITH:
        begin
            write_rd = 1;
        end

        ARITH_IMM:
        begin
            alu_oper2_src = OPER2_IMM;
            curr_imm = imm_i;
            write_rd = 1;
        end

        FENCE:
        begin

        end

        SYSTEM:
        begin
            if (func3 == '0 && rd == '0) // ecall, ebreak or mret
            begin
                if (func7 == 7'b0011000) // mret
                    trap = MRET;
                else
                begin
                    trap = (instr_i[31:20] == 12'd1) ? EBREAK : ECALL;
                end
            end
            else  // CSR instruction
            begin
                write_rd = 1'b1;
                is_csr = 1'b1;
                // determine if csr will be read
                // In CSRRW*: if rd = Zero, the csr is not read and any read side-effects will not be triggered
                csr_re = ((system_opc_t'(func3) == CSRRW ||
                    system_opc_t'(func3) == CSRRWI) && rd == '0) ? 1'b0 : 1'b1;

                // determine is csr will be written
                // In CSRRS/C: If rs1 = Zero, the csr is not written and any write side-effect will not be triggered
                // In CSRRSI/CI: If uimm = Zero, the csr is not written any write side-effects will not be triggered
                csr_we = (rs1 == '0 && (system_opc_t'(func3) == CSRRS || system_opc_t'(func3) == CSRRS)) ||
                    (imm_csr == '0 && (system_opc_t'(func3) == CSRRSI || system_opc_t'(func3) == CSRRCI)) ? 1'b0 : 1'b1;

                // handle CSR* instructions
                if (func3[2]) // indicates the immediate variant
                begin
                    alu_oper1_src = OPER1_CSR_IMM;
                    curr_imm = imm_csr;
                end
                else
                    alu_oper1_src = OPER1_RS1;

                if (func3[1:0] == 2'b01) // CSRRW*
                    alu_oper2_src = OPER2_ZERO;
                else
                    alu_oper2_src = OPER2_CSR;
            end
        end

        // TODO: handle illegal opcode
        default:
        begin

        end
    endcase
end

// decoding the alu operations separately

always_comb
begin : alu_decode
    alu_oper = ALU_ADD;

    case(opcode)
        JAL, JALR, LOAD, STORE, AUIPC:
        begin
            alu_oper = ALU_ADD;
        end

        BRANCH:
        begin
            if (opcode_branch_t'(func3) == BNE)
                alu_oper = ALU_SNEQ;
            else if (opcode_branch_t'(func3) == BEQ)
                alu_oper = ALU_SEQ;
            else
            begin
                alu_oper = alu_oper_t'({func3[0], 1'b0, func3[2:1]});
            end
        end

        ARITH:
        begin
            alu_oper = alu_oper_t'({instr_i[30],func3});
        end

        ARITH_IMM:
        begin
            if (opcode_alu_t'(func3) == SRA_L)
                alu_oper = alu_oper_t'({instr_i[30],func3});
            else
                alu_oper = alu_oper_t'({1'b0,func3});
        end

        SYSTEM:
        begin
            if (system_opc_t'(func3) == CSRRW || system_opc_t'(func3) == CSRRWI)
                alu_oper = ALU_ADD;
            else if (system_opc_t'(func3) == CSRRS || system_opc_t'(func3) == CSRRSI)
                alu_oper = ALU_OR;
            else if (system_opc_t'(func3) == CSRRC || system_opc_t'(func3) == CSRRCI)
                alu_oper = ALU_XOR;
        end

        default: // no need to handle anything here, already handled illegal opcodes above
        begin end
    endcase
end

// pipeline registers and outputs

assign regf_rs1_addr_o = rs1;
assign regf_rs2_addr_o = rs2;
assign csr_raddr_o = csr_addr;
assign csr_re_o = csr_re;
assign id_is_csr_o = is_csr;

always_ff @(posedge clk_i, negedge rstn_i)
begin : id_ex_pip
    if (!rstn_i || flush_i)
    begin
        pc_o <= 0;
        rs1_data_o <= 0;
        rs2_data_o <= 0;
        imm_o <= 0;
        csr_rdata_o <= 0;
        alu_oper1_src_o <= OPER1_RS1;
        alu_oper2_src_o <= OPER2_RS2;
        bnj_oper_o <= BNJ_NO;
        alu_oper_o <= ALU_ADD;
        is_csr_o <= '0;

        mem_oper_o <= MEM_NOP;
        csr_waddr_o <= 0;
        csr_we_o <= 0;

        wb_use_mem_o <= 0;
        write_rd_o <= 0;
        rd_addr_o <= 0;

        rs1_addr_o <= 0;
        rs2_addr_o <= 0;

        trap_o <= NO_TRAP;
    end
    else if (!stall_i)
    begin
        pc_o <= pc_i;
        rs1_data_o <= rs1_data_i;
        rs2_data_o <= rs2_data_i;
        imm_o <= curr_imm;
        csr_rdata_o <= csr_rdata_i;
        alu_oper1_src_o <= alu_oper1_src;
        alu_oper2_src_o <= alu_oper2_src;
        bnj_oper_o <= bnj_oper;
        alu_oper_o <= alu_oper;
        is_csr_o <= is_csr;

        mem_oper_o <= mem_oper;
        csr_waddr_o <= csr_addr;
        csr_we_o <= csr_we;

        wb_use_mem_o <= wb_use_mem;
        write_rd_o <= write_rd;
        rd_addr_o <= rd;

        rs1_addr_o <= rs1;
        rs2_addr_o <= rs2;

        trap_o <= trap;
    end
end

endmodule: decode