// dependancy and hazard detection unit
// TODO: document functionality

module controller
import riscv_pkg::*;
import csr_pkg::*;
(
    input clk_i,
    input rstn_i,

    // ID stage
    input [4:0] id_rs1_addr_i,
    input [4:0] id_rs2_addr_i,

    // ID/EX pipeline
    input [4:0] id_ex_rs1_addr_i,
    input [4:0] id_ex_rs2_addr_i,
    input [4:0] id_ex_rd_addr_i,
    input id_ex_write_rd_i,
    input id_ex_wb_use_mem_i,

    // EX stage
    input ex_new_pc_en_i,

    // from EX/MEM
    input [4:0] ex_mem_rd_addr_i,
    input ex_mem_write_rd_i,
    input ex_mem_wb_use_mem_i,
    input [31:0] ex_mem_alu_result_i,

    // from MEM/WB
    input [4:0] mem_wb_rd_addr_i,
    input mem_wb_write_rd_i,
    input mem_wb_use_mem_i,
    input [31:0] mem_wb_alu_result_i,
    input [31:0] mem_wb_dmem_rdata_i,
    input exc_t mem_trap_i,

    // forward from EX/MEM stage to EX stage
    output forward_ex_mem_rs1_o,
    output forward_ex_mem_rs2_o,
    output [31:0] forward_ex_mem_data_o,
    // forward from MEM/WB stage to EX stage
    output forward_mem_wb_rs1_o,
    output forward_mem_wb_rs2_o,
    output [31:0] forward_mem_wb_data_o,

    input [31:0] if_pc_i, // the IF PC

    input if_id_instr_valid_i,
    input [31:0] if_id_pc_i,

    input id_ex_instr_valid_i,
    input [31:0] id_ex_pc_i,

    input ex_mem_instr_valid_i,
    input [31:0] ex_mem_pc_i,

    // to handle CSR read/write side effects
    input id_is_csr_i,
    input ex_is_csr_i,
    input mem_is_csr_i,

    // for interrupt handling
    input priv_lvl_e current_plvl_i,
    input var mstatus_t csr_mstatus_i,
    input var irqs_t irq_pending_i,

    // to fetch stage, to steer the pc
    output logic new_pc_en_o,
    output pc_sel_t pc_sel_o,

    // to cs registers
    output logic csr_mret_o,
    output mcause_t csr_mcause_o,
    output logic is_trap_o,
    output logic [31:0] exc_pc_o, // this will be saved in mepc

    // flush/stall to ID/EX
    output logic id_ex_flush_o,
    output logic id_ex_stall_o,

    // flush/stall to IF/EX
    output logic if_id_stall_o,
    output logic if_id_flush_o,

    // flush/stall to EX/MEM
    output logic ex_mem_stall_o,
    output logic ex_mem_flush_o
);

// forwarding to the EX stage happens when we are writing to a register that is sourced
// by the instruction currently decoded, it will read a stale value in the decode stage

// we can't forward from the EX stage if the instruction will load from memory
// since the alu result is not the written value but the address to memory
wire ex_mem_forward_possible = (ex_mem_rd_addr_i != 0) && ex_mem_write_rd_i && !ex_mem_wb_use_mem_i;
wire mem_wb_forward_possible = (mem_wb_rd_addr_i != 0) && mem_wb_write_rd_i;

logic forward_ex_mem_rs1;
logic forward_ex_mem_rs2;
logic forward_mem_wb_rs1;
logic forward_mem_wb_rs2;

always_comb begin : forwarding
    forward_ex_mem_rs1 = 0;
    forward_mem_wb_rs1 = 0;
    forward_ex_mem_rs2 = 0;
    forward_mem_wb_rs2 = 0;

    // Note: forwarding from the most recent stage takes priority

    // consider this example where we could forward from EX/MEM and from MEM/WB
    // add x3,x3,x4
    // add x3,x3,x5
    // add x3,x3,x4
    // in this case all Rd is the same for the 3 instructions
    // we must forward from the most recent stage which is EX/MEM since it contains the most up-to-date version of Rd

    // forward rs1
    if (ex_mem_forward_possible && (ex_mem_rd_addr_i == id_ex_rs1_addr_i))
        forward_ex_mem_rs1 = 1;
    else if (mem_wb_forward_possible && (mem_wb_rd_addr_i == id_ex_rs1_addr_i))
        forward_mem_wb_rs1 = 1;

    // forward rs2
    if (ex_mem_forward_possible && (ex_mem_rd_addr_i == id_ex_rs2_addr_i))
        forward_ex_mem_rs2 = 1;
    else if (mem_wb_forward_possible && (mem_wb_rd_addr_i == id_ex_rs2_addr_i))
        forward_mem_wb_rs2 = 1;
end

// outputs
assign forward_ex_mem_rs1_o = forward_ex_mem_rs1;
assign forward_ex_mem_rs2_o = forward_ex_mem_rs2;
assign forward_mem_wb_rs1_o = forward_mem_wb_rs1;
assign forward_mem_wb_rs2_o = forward_mem_wb_rs2;

// data to be forwarded
assign forward_ex_mem_data_o = ex_mem_alu_result_i; // through here just for cleanliness

// 1- if the MEM stage loaded a value, we need this value to be forwarded not the alu result
// the alu result has been used as the address to load from in this case
// 2- if the MEM stage hasn't loaded, forward the alu result
assign forward_mem_wb_data_o = mem_wb_use_mem_i ? mem_wb_dmem_rdata_i : mem_wb_alu_result_i;

// Hazard Section

// handle use after load hazard
// In this case we will stall the instruction needing the loaded value for 1 cycle
// after that, forwarding from the MEM/WB will let it proceed

// A load instruction is currently in the ex_mem stage
wire id_ex_load = id_ex_write_rd_i && id_ex_wb_use_mem_i;
wire load_use_hzrd = id_ex_load && ((id_ex_rd_addr_i == id_rs1_addr_i) ||
    (id_ex_rd_addr_i == id_rs2_addr_i));

// For now, the cpu always predicts that the branch is not taken and continues
// On a mispredict, flush the 2 instruction after the branch and continue from the new PC

// Instruction fetch is stalled on:
// 1- Load use hazard
// 2- There is a CSR instruction in the pipeline

// handle interrupts

logic interrupt_en;
logic handle_irq;
// Global interrupt enable or In U mode since MIE is a don't care in U mode
assign interrupt_en = csr_mstatus_i.mie || current_plvl_i == PRIV_LVL_U;
assign handle_irq = interrupt_en & |irq_pending_i;

// determine the IRQ code with the highest priority
logic [3:0] interrupt_code;
always_comb
begin
    interrupt_code = '0;
    unique case (1'b1)
        irq_pending_i.m_software: interrupt_code = CSR_MSI_BIT;
        irq_pending_i.m_timer: interrupt_code = CSR_MTI_BIT;
        irq_pending_i.m_external: interrupt_code = CSR_MEI_BIT;
        default:;
    endcase
end

typedef enum logic [1:0] 
{
    DECODE,
    IRQ_TAKEN
} state_t;

state_t current_state, next_state;

// next state logic
always_ff @(posedge clk_i, negedge rstn_i)
    if (!rstn_i) current_state <= DECODE;
    else current_state <= next_state;

always_comb
begin
    next_state = current_state;

    is_trap_o = '0;
    new_pc_en_o = '0;
    pc_sel_o = PC_JUMP;
    csr_mret_o = '0;

    // for exceptions
    exc_pc_o = ex_mem_pc_i;
    csr_mcause_o = '{
        irq: 1'b0,
        trap_code: mem_trap_i[3:0]
    };

    id_ex_flush_o = load_use_hzrd;
    id_ex_stall_o = '0;

    if_id_stall_o = load_use_hzrd || ex_is_csr_i || mem_is_csr_i;
    if_id_flush_o = id_is_csr_i || ex_is_csr_i || mem_is_csr_i;

    ex_mem_stall_o = '0;
    ex_mem_flush_o = '0;

    unique case (current_state)
        DECODE:
        begin
            // instruction in the MEM stage raised a trap
            if (mem_trap_i != NO_TRAP)
            begin
                id_ex_flush_o = 1'b1;
                ex_mem_flush_o = 1'b1;

                // MRET
                if (mem_trap_i == MRET)
                begin
                    new_pc_en_o = 1'b1;
                    pc_sel_o = PC_MEPC;
                    csr_mret_o = 1'b1; // triggers needed changes in cs_registers
                end
                else // regular exception
                begin
                    is_trap_o = 1'b1;
                    new_pc_en_o = 1'b1;
                    pc_sel_o = PC_TRAP;
                end
            end
            else if (handle_irq)
            begin
                // the instruction currently commiting in the MEM stage will be allowed to finish
                // but the EX_MEM and ID_EX pipeline registers must be flushed

                id_ex_flush_o = 1'b1;
                ex_mem_flush_o = 1'b1;
                pc_sel_o = PC_TRAP;
                new_pc_en_o = 1'b1;
                is_trap_o = 1'b1;

                csr_mcause_o = '{
                    irq: 1'b1,
                    trap_code: interrupt_code
                };

                // we need the pipeline to restart from the first valid instruction that is younger
                // that the one that will retire in this cycle
                if (id_ex_instr_valid_i)
                    exc_pc_o = id_ex_pc_i;
                else if (if_id_instr_valid_i)
                    exc_pc_o = if_id_pc_i;
                else
                    exc_pc_o = if_pc_i;
            end
            else if (ex_new_pc_en_i) // EX determined that the branch was taken
            begin
                new_pc_en_o = 1'b1;

                // for now the branch is always predicted as not taken, hence if it's taken
                // we must flush the wrong instruction currently in id_ex
                id_ex_flush_o = 1'b1;
                // pc_sel_o is already set
            end
        end
        default:;
    endcase
end

endmodule: controller