// execute module

module execute
(
    input clk_i,
    input rstn_i,

    // from ID/EX
    input [31:0] pc_i,
    input [31:0] rs1_data_i,
    input [31:0] rs2_data_i,
    input [31:0] imm_i,
    input alu_oper1_src_t alu_oper1_src_i,
    input alu_oper2_src_t alu_oper2_src_i,
    input alu_oper_t alu_oper_i,
    input bnj_oper_t bnj_oper_i,

    // forward to MEM stage
    input mem_oper_t mem_oper_i,
    
    // forward to the WB stage
    input wb_use_mem_i,
    input write_rd_i,
    input [4:0] rd_addr_i,

    // EX/MEM pipeline registers

    // feedback into the pipeline registers
    input stall_i,
    input flush_i,

    output [31:0] alu_result_o,
    output [31:0] alu_oper2_o,
    output mem_oper_t mem_oper_o,
    // for WB stage exclusively
    output logic wb_use_mem_o,
    output logic write_rd_o,
    output logic [4:0] rd_addr_o,

    // branches and jumps
    output load_pc_o,
    output [31:0] new_pc_o
);

logic [31:0] operand1, operand2;

// determine operand1
always_comb
begin
    case (alu_oper1_src_i)
        OPER1_RS1:
            operand1 = rs1_data_i;
        OPER1_PC:
            operand1 = pc_i;
        OPER1_ZERO:
            operand1 = 0;
        default:
            operand1 = rs1_data_i;
    endcase
end

// determine operand2
always_comb
begin
    case (alu_oper2_src_i)
        OPER2_RS2:
            operand2 = rs2_data_i;
        OPER2_IMM:
            operand2 = imm_i;
        OPER2_PC_INC:
            operand2 = 4; // no support for compressed instructions extension, yet
        default:
            operand2 = rs2_data_i;
    endcase
end

logic [31:0] alu_result;
wire [4:0] shift_amount = operand2[4:0];

// alu result
always_comb
begin
    case (alu_oper_i)
        ALU_ADD: alu_result = operand1 + operand2;
        ALU_SUB: alu_result = operand1 - operand2;

        ALU_SEQ: alu_result = {31'd0, operand1 == operand2};

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
    case (bnj_oper_i)
        BNJ_JAL:
        begin
            load_pc_o = 1;
            new_pc_o = pc_i + imm_i;
        end

        BNJ_JALR:
        begin
            load_pc_o = 1;
            new_pc_o = rs1_data_i + imm_i;
        end

        BNJ_BRANCH:
        begin
            load_pc_o = alu_result[0];
            new_pc_o = pc_i + imm_i;
        end
        default:
        begin
            load_pc_o = 0;
            new_pc_o = 0;
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
        
        wb_use_mem_o <= 0;
        write_rd_o <= 0;
        rd_addr_o <= 0;
    end
    else if (!stall_i)
    begin
        alu_result_o <= alu_result;
        alu_oper2_o <= operand2;
        mem_oper_o <= mem_oper_i;

        wb_use_mem_o <= wb_use_mem_i;
        write_rd_o <= write_rd_i;
        rd_addr_o <= rd_addr_i;
    end
end

endmodule: execute