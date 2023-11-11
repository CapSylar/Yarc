// execute module

module execute
import riscv_pkg::*;
(
    input clk_i,
    input rstn_i,

    // from ID/EX
    input [31:0] pc_i,
    input [31:0] rs1_data_i,
    input [31:0] rs2_data_i,
    input [31:0] imm_i,
    input [31:0] csr_rdata_i,
    input alu_oper1_src_t alu_oper1_src_i,
    input alu_oper2_src_t alu_oper2_src_i,
    input alu_oper_t alu_oper_i,
    input bnj_oper_t bnj_oper_i,
    input is_csr_i,

    // forward to MEM stage
    input mem_oper_t mem_oper_i,
    input [11:0] csr_waddr_i,
    input csr_we_i,
    input exc_t trap_i,
    
    // forward to the WB stage
    input wb_use_mem_i,
    input write_rd_i,
    input [4:0] rd_addr_i,

    // EX/MEM pipeline registers

    // feedback into the pipeline registers
    input stall_i,
    input flush_i,

    output logic [31:0] alu_result_o, // always contains a mem address or the rd value
    output logic [31:0] alu_oper2_o,
    output mem_oper_t mem_oper_o,
    output logic [31:0] csr_wdata_o,
    output logic [11:0] csr_waddr_o,
    output logic csr_we_o,
    output logic is_csr_o,
    output exc_t trap_o,
    output logic [31:0] pc_o,

    // for WB stage exclusively
    output logic wb_use_mem_o,
    output logic write_rd_o,
    output logic [4:0] rd_addr_o,

    // branches and jumps
    output logic new_pc_en_o,
    output logic [31:0] branch_target_o,

    // from forwarding logic
    input forward_ex_mem_rs1_i,
    input forward_ex_mem_rs2_i,
    input [31:0] forward_ex_mem_data_i,

    input forward_mem_wb_rs1_i,
    input forward_mem_wb_rs2_i,
    input [31:0] forward_mem_wb_data_i
);

logic [31:0] rs1_data, rs2_data; // contain the most up to date values of the registers needed

always_comb
begin : solve_forwarding
    rs1_data = rs1_data_i;
    rs2_data = rs2_data_i;

    // any forwarding active for rs1 ?
    if (forward_ex_mem_rs1_i)
        rs1_data = forward_ex_mem_data_i;
    else if (forward_mem_wb_rs1_i)
        rs1_data = forward_mem_wb_data_i;

    // any forwarding active for rs2 ?
    if (forward_ex_mem_rs2_i)
        rs2_data = forward_ex_mem_data_i;
    else if (forward_mem_wb_rs2_i)
        rs2_data = forward_mem_wb_data_i;
end

logic [31:0] operand1, operand2; // arithmetic operations are done on these

// determine operand1
always_comb
begin
    unique case (alu_oper1_src_i)
        OPER1_RS1:
            operand1 = rs1_data;
        OPER1_PC:
            operand1 = pc_i;
        OPER1_ZERO:
            operand1 = '0;
        OPER1_CSR_IMM:
            operand1 = imm_i;
        default:
            operand1 = rs1_data;
    endcase
end

// determine operand2
always_comb
begin
    unique case (alu_oper2_src_i)
        OPER2_RS2:
            operand2 = rs2_data;
        OPER2_IMM:
            operand2 = imm_i;
        OPER2_PC_INC:
            operand2 = 4; // no support for compressed instructions extension, yet
        OPER2_CSR:
            operand2 = csr_rdata_i;
        OPER2_ZERO:
            operand2 = '0;
        default:
            operand2 = rs2_data;
    endcase
end

logic [31:0] alu_result;
wire [4:0] shift_amount = operand2[4:0];

// alu result
always_comb
begin
    unique case (alu_oper_i)
        ALU_ADD: alu_result = operand1 + operand2;
        ALU_SUB: alu_result = operand1 - operand2;

        ALU_SEQ: alu_result = {31'd0, operand1 == operand2};
        ALU_SNEQ: alu_result = {31'd0, operand1 != operand2};

        ALU_SLT: alu_result = {31'd0, $signed(operand1) < $signed(operand2)};
        ALU_SGE: alu_result = {31'd0, $signed(operand1) >= $signed(operand2)};

        ALU_SLTU: alu_result = {31'd0, operand1 < operand2};
        ALU_SGEU: alu_result = {31'd0, operand1 >= operand2};

        ALU_XOR: alu_result = operand1 ^ operand2;
        ALU_OR: alu_result = operand1 | operand2;
        ALU_AND: alu_result = operand1 & operand2;

        ALU_SLL: alu_result = operand1 << shift_amount;

        ALU_SRL: alu_result = operand1 >> shift_amount;
        ALU_SRA: alu_result = $signed(operand1) >>> shift_amount;

        default:
            alu_result = operand1 + operand2;
    endcase
end

// handle branches and jumps
always_comb
begin
    unique case (bnj_oper_i)
        BNJ_JAL:
        begin
            new_pc_en_o = 1;
            branch_target_o = pc_i + imm_i;
        end

        BNJ_JALR:
        begin
            new_pc_en_o = 1;
            branch_target_o = rs1_data + imm_i;
        end

        BNJ_BRANCH:
        begin
            new_pc_en_o = alu_result[0];
            branch_target_o = pc_i + imm_i;
        end
        default:
        begin
            new_pc_en_o = 0;
            branch_target_o = 0;
        end
    endcase
end

// pipeline registers and outputs

always_ff @(posedge clk_i, negedge rstn_i)
begin : ex_mem_pip
    if (!rstn_i || flush_i)
    begin
        alu_result_o <= 0;
        alu_oper2_o <= 0;
        mem_oper_o <= MEM_NOP;
        csr_wdata_o <= '0;
        csr_waddr_o <= '0;
        csr_we_o <= '0;
        is_csr_o <= '0;
        trap_o <= NO_TRAP;
        pc_o <= '0;
        
        wb_use_mem_o <= 0;
        write_rd_o <= 0;
        rd_addr_o <= 0;
    end
    else if (!stall_i)
    begin
        // TODO: rename alu_result_o
        // since it doesn't really reflect alu_result
        // it is really the value to write to rd if any
        alu_result_o <= is_csr_i ? csr_rdata_i : alu_result;
        alu_oper2_o <= rs2_data;
        mem_oper_o <= mem_oper_i;
        csr_wdata_o <= alu_result;
        csr_waddr_o <= csr_waddr_i;
        csr_we_o <= csr_we_i;
        is_csr_o <= is_csr_i;
        trap_o <= trap_i;
        pc_o <= pc_i;

        wb_use_mem_o <= wb_use_mem_i;
        write_rd_o <= write_rd_i;
        rd_addr_o <= rd_addr_i;
    end
end

endmodule: execute