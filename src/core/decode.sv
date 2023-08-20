// decode module
// takes instructions in, splits them into control signals

`include "riscv_defines.svh"

module decode
(
    input clk_i,
    input rstn_i,

    // register file <-> decode module
    // read port
    output [4:0] regf_rs1_addr_o,
    output [4:0] regf_rs2_addr_o,
    input [31:0] rs1_data_i,
    input [31:0] rs2_data_i,

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
    output alu_oper1_src_t alu_oper1_src_o,
    output alu_oper2_src_t alu_oper2_src_o,
    output bnj_oper_t bnj_oper_o,
    output alu_oper_t alu_oper_o,

    // for the MEM stage
    output mem_oper_t mem_oper_o,

    // for the WB stage
    output logic wb_use_mem_o,
    output logic write_rd_o,
    output logic [4:0] rd_addr_o,

    // used by the hazard/forwarding logic
    output logic [4:0] rs1_addr_o,
    output logic [4:0] rs2_addr_o
);

// extract the common fields from the instruction format
opcode_t opcode;
logic [4:0] rs1, rs2, rd;
logic [2:0] func3;
logic [6:0] func7;

assign opcode = opcode_t'(instr_i[6:0]);
assign rd = instr_i[11:7];
assign rs1 = instr_i[19:15];
assign rs2 = instr_i[24:20];
assign func3 = instr_i[14:12];
assign func7 = instr_i[31:25];

// immediates
logic [31:0] imm_i, imm_s, imm_b, imm_u, imm_j;

assign imm_i = 32'(signed'(instr_i[31:20]));
assign imm_s = 32'(signed'({instr_i[31:25], instr_i[11:7]}));
assign imm_b = 32'(signed'({instr_i[31], instr_i[7], instr_i[30:25], instr_i[11:8], 1'b0}));
assign imm_u = {instr_i[31:12], 12'b0};
assign imm_j = 32'(signed'({instr_i[31], instr_i[19:12], instr_i[20], instr_i[30:21], 1'b0}));

alu_oper_t alu_oper;
logic [31:0] curr_imm;
logic write_rd; // write back

alu_oper1_src_t alu_oper1_src;
alu_oper2_src_t alu_oper2_src;

bnj_oper_t bnj_oper;
logic wb_use_mem; // use memory data out to write back to the register file
mem_oper_t mem_oper; // memory operation if any

// decode
always_comb
begin : main_decode

    alu_oper1_src = OPER1_RS1;
    alu_oper2_src = OPER2_RS2;

    write_rd = 0;
    curr_imm = 0;
    bnj_oper = BNJ_NO; // no branch
    wb_use_mem = 0;
    mem_oper = MEM_NOP;

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
                alu_oper = ALU_SUB;
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

        default: // no need to handle anything here, already handled illegal opcodes above
        begin end
    endcase
end

// pipeline registers and outputs

assign regf_rs1_addr_o = rs1;
assign regf_rs2_addr_o = rs2;

always_ff @(posedge clk_i, negedge rstn_i)
begin : id_ex_pip
    if (!rstn_i || flush_i)
    begin
        pc_o <= 0;
        rs1_data_o <= 0;
        rs2_data_o <= 0;
        imm_o <= 0;
        alu_oper1_src_o <= OPER1_RS1;
        alu_oper2_src_o <= OPER2_RS2;
        bnj_oper_o <= BNJ_NO;
        alu_oper_o <= ALU_ADD;

        mem_oper_o <= MEM_NOP;

        wb_use_mem_o <= 0;
        write_rd_o <= 0;
        rd_addr_o <= 0;

        rs1_addr_o <= 0;
        rs2_addr_o <= 0;
    end
    else if (!stall_i)
    begin
        pc_o <= pc_i;
        rs1_data_o <= rs1_data_i;
        rs2_data_o <= rs2_data_i;
        imm_o <= curr_imm;
        alu_oper1_src_o <= alu_oper1_src;
        alu_oper2_src_o <= alu_oper2_src;
        bnj_oper_o <= bnj_oper;
        alu_oper_o <= alu_oper;

        mem_oper_o <= mem_oper;

        wb_use_mem_o <= wb_use_mem;
        write_rd_o <= write_rd;
        rd_addr_o <= rd;

        rs1_addr_o <= rs1;
        rs1_addr_o <= rs2;
    end
end

endmodule: decode