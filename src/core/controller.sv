// dependancy and hazard detection unit
// TODO: document functionality

module controller
import riscv_pkg::*;
import csr_pkg::*;
(
    input clk_i,
    input rstn_i,

    // from IF
    input [31:0] if_pc_i,

    // ID stage
    input [4:0] id_rs1_addr_i,
    input [4:0] id_rs2_addr_i,

    // ID/EX pipeline
    input [4:0] id_ex_rs1_addr_i,
    input [4:0] id_ex_rs2_addr_i,
    input [4:0] id_ex_rd_addr_i,
    input id_ex_write_rd_i,
    input mem_oper_t id_ex_mem_oper_i,

    // EX stage
    input ex_new_pc_en_i,

    // from EX/MEM1
    input [31:0] ex_mem1_pc_i,
    input [4:0] ex_mem1_rd_addr_i,
    input ex_mem1_write_rd_i,
    input mem_oper_t ex_mem1_mem_oper_i,
    input [31:0] ex_mem1_alu_result_i,

    // from MEM1/MEM2
    input [4:0] mem1_mem2_rd_addr_i,
    input mem1_mem2_write_rd_i,
    input mem_oper_t mem1_mem2_mem_oper_i,
    input [31:0] mem1_mem2_alu_result_i,

    // from MEM2/WB
    input [4:0] mem2_wb_rd_addr_i,
    input mem2_wb_write_rd_i,
    input mem_oper_t mem2_wb_mem_oper_i,
    input [31:0] mem2_wb_alu_result_i,
    input [31:0] mem2_wb_lsu_rdata_i,
    input mem2_stall_needed_i,
    input exc_t mem_trap_i,

    // from LSU
    input lsu_req_stall_i,

    // forward from EX/MEM1 stage to EX stage
    output logic forward_ex_mem1_rs1_o,
    output logic forward_ex_mem1_rs2_o,
    output logic [31:0] forward_ex_mem1_data_o,
    // forward from MEM1/MEM2 stage to EX stage
    output logic forward_mem1_mem2_rs1_o,
    output logic forward_mem1_mem2_rs2_o,
    output logic [31:0] forward_mem1_mem2_data_o,
    // forward from MEM2/WB stage to EX stage
    output logic forward_mem2_wb_rs1_o,
    output logic forward_mem2_wb_rs2_o,
    output logic [31:0] forward_mem2_wb_data_o,

    input if_id_instr_valid_i,
    input id_ex_instr_valid_i,
    input ex_mem1_instr_valid_i,
    input mem1_mem2_instr_valid_i,
    input mem2_wb_instr_valid_i,

    // to handle CSR read/write side effects
    input id_is_csr_i,
    input ex_is_csr_i,
    input mem1_is_csr_i,
    input mem2_is_csr_i,

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
    output logic if_stall_o,
    output logic if_flush_o,

    // flush/stall to EX/MEM1
    output logic ex_mem1_stall_o,
    output logic ex_mem1_flush_o,

    // flush/stalll to MEM1/MEM2
    output logic mem1_mem2_stall_o,
    output logic mem1_mem2_flush_o,

    // flush/stall to MEM2/WB
    output logic mem2_wb_stall_o,
    output logic mem2_wb_flush_o
);

// forwarding to the EX stage happens when we are writing to a register that is sourced
// by the instruction currently decoded, it will read a stale value in the decode stage

// we can't forward from the EX stage if the instruction will load from memory
// since the alu result is not the written value but the address to memory
wire ex_mem1_forward_possible = (ex_mem1_rd_addr_i != '0) && ex_mem1_write_rd_i && !is_mem_oper_load(ex_mem1_mem_oper_i);
wire mem1_mem2_forward_possible = (mem1_mem2_rd_addr_i != '0) && mem1_mem2_write_rd_i;
wire mem2_wb_forward_possible = (mem2_wb_rd_addr_i != '0) && mem2_wb_write_rd_i;

logic forward_ex_mem1_rs1;
logic forward_ex_mem1_rs2;
logic forward_mem1_mem2_rs1;
logic forward_mem1_mem2_rs2;
logic forward_mem2_wb_rs1;
logic forward_mem2_wb_rs2;

// Note: forwarding from the most recent stage takes priority
// consider this example where we could forward from EX/MEM and from MEM/WB
// add x3,x3,x4
// add x3,x3,x5
// add x3,x3,x4
// in this case all Rd is the same for the 3 instructions
// we must forward from the most recent stage which is EX/MEM
// since it contains the most up-to-date version of Rd

// several forward_*_rs1 could be high at the same time, the ex module
// will take the most recent result

// rs1
assign forward_ex_mem1_rs1 = ex_mem1_forward_possible && (ex_mem1_rd_addr_i == id_ex_rs1_addr_i);
assign forward_mem1_mem2_rs1 = mem1_mem2_forward_possible && (mem1_mem2_rd_addr_i == id_ex_rs1_addr_i);
assign forward_mem2_wb_rs1 = mem2_wb_forward_possible && (mem2_wb_rd_addr_i == id_ex_rs1_addr_i);
// rs2
assign forward_ex_mem1_rs2 = ex_mem1_forward_possible && (ex_mem1_rd_addr_i == id_ex_rs2_addr_i);
assign forward_mem1_mem2_rs2 = mem1_mem2_forward_possible && (mem1_mem2_rd_addr_i == id_ex_rs2_addr_i);
assign forward_mem2_wb_rs2 = mem2_wb_forward_possible && (mem2_wb_rd_addr_i == id_ex_rs2_addr_i);

// outputs
assign forward_ex_mem1_rs1_o = forward_ex_mem1_rs1;
assign forward_ex_mem1_rs2_o = forward_ex_mem1_rs2;
assign forward_mem1_mem2_rs1_o = forward_mem1_mem2_rs1;
assign forward_mem1_mem2_rs2_o = forward_mem1_mem2_rs2;
assign forward_mem2_wb_rs1_o = forward_mem2_wb_rs1;
assign forward_mem2_wb_rs2_o = forward_mem2_wb_rs2;

// data to be forwarded from EX/MEM1
assign forward_ex_mem1_data_o = ex_mem1_alu_result_i; // through here just for cleanliness

// data to be forwarded from MEM1/MEM2
assign forward_mem1_mem2_data_o = mem1_mem2_alu_result_i; // through here just for cleanliness

// 1- if the MEM stage loaded a value, we need this value to be forwarded not the alu result
// the alu result has been used as the address to load from in this case
// 2- if the MEM stage hasn't loaded, forward the alu result
assign forward_mem2_wb_data_o = is_mem_oper_load(mem2_wb_mem_oper_i) ? mem2_wb_lsu_rdata_i : mem2_wb_alu_result_i;

// Hazard Section

// handle use after load hazard
// due to the fact that the memory stage is split into 2
// a use instruction that directly procedes a load instruction will need to stall for 2 cycles
// the stalled instruction will be held in the Decode stage for 2 cycles

// to detect this case, the use instruction will be stalled in the EX stage until the forwarding pass
// can satisfy its requirements

// a load in mem1 has the value we need
wire value_in_mem1 = is_mem_oper_load(ex_mem1_mem_oper_i) &&
    ((ex_mem1_rd_addr_i == id_ex_rs1_addr_i) || (ex_mem1_rd_addr_i == id_ex_rs2_addr_i));

// a load in mem2 has the value we need
wire value_in_mem2_rs1 = is_mem_oper_load(mem1_mem2_mem_oper_i) && (mem1_mem2_rd_addr_i == id_ex_rs1_addr_i);
wire value_in_mem2_rs2 = is_mem_oper_load(mem1_mem2_mem_oper_i) && (mem1_mem2_rd_addr_i == id_ex_rs2_addr_i);

// we will stall the use instruction in EX only if the value is produced by a load in MEM1
// or if the value is produced by a load in MEM2 but not when an instruction (non load) in MEM1 can produce the value
wire load_use_hzrd = value_in_mem1 || (value_in_mem2_rs1 && !forward_ex_mem1_rs1) || (value_in_mem2_rs2 && !forward_ex_mem1_rs2);

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

// any instruction still in the pipeline ?
wire pipeline_empty = !(id_ex_instr_valid_i ||
                        ex_mem1_instr_valid_i ||
                        mem1_mem2_instr_valid_i ||
                        mem2_wb_instr_valid_i);

wire trap_happened = (mem_trap_i != NO_TRAP);
logic take_irq, take_exception;

enum
{
    DECODE,
    IRQ_WAIT // waiting for pipeline to clear to goto interrupt
} state, next;

// next state logic
always_ff @(posedge clk_i)
    if (!rstn_i) state <= DECODE;
    else state <= next;

always_comb
begin: core_sm
    next = state;
    take_irq = '0;

    unique case (state)
    DECODE:
    begin
        if (handle_irq)
            next = IRQ_WAIT;
    end
    IRQ_WAIT:
    begin
        /* when the pipeline is empty, we have to recheck the interrupt pending status.
        It is possible that when we stalled if and waited for the in-flight instructions
        to retire, that an interrupt disabling instruction was among them, in this case, we wasted
        time and need to restart the pipeline as if nothing happened */

        /* an in-flight instruction disabled interrupts or a trap happened */
        if (!handle_irq || trap_happened)
            next = DECODE;
        else if (pipeline_empty)
        begin
            take_irq = 1'b1;
            next = DECODE;
        end
    end
    endcase
end

always_comb
begin: if_steering
    is_trap_o = '0;
    new_pc_en_o = '0;
    pc_sel_o = PC_JUMP;
    csr_mret_o = '0;

    // for exceptions
    exc_pc_o = ex_mem1_pc_i;
    csr_mcause_o = '{
        irq: 1'b0,
        trap_code: mem_trap_i[3:0]
    };

    if (take_exception)
    begin
        // MRET
        if (mem_trap_i == MRET)
        begin
            new_pc_en_o = 1'b1;
            pc_sel_o = PC_MEPC;
            csr_mret_o = 1'b1; // triggers needed changes in cs_registers
        end
        else // regular exception
        begin
            new_pc_en_o = 1'b1;
            pc_sel_o = PC_TRAP;
            is_trap_o = 1'b1;
        end
    end
    else if (take_irq)
    begin
        pc_sel_o = PC_TRAP;
        new_pc_en_o = 1'b1;
        is_trap_o = 1'b1;

        exc_pc_o = if_pc_i;
        csr_mcause_o = '{
            irq: 1'b1,
            trap_code: interrupt_code
        };
    end
    else if (ex_new_pc_en_i)
    begin
        new_pc_en_o = 1'b1;
    end
end


always_comb
begin: pipeline_stage_control
    // TODO: clean this shit up
    // if stage N needs to stall, then so does stage N-1 and so on
    // if a stall is caused by MEM1 or MEM2 we have to stall WB as well, to preserve any forwarding that is happending to EX from WB or MEM2 or MEM1
    mem2_wb_stall_o = mem2_stall_needed_i || lsu_req_stall_i;
    mem2_wb_flush_o = '0;

    mem1_mem2_stall_o = mem2_wb_stall_o;
    mem1_mem2_flush_o = lsu_req_stall_i & !mem1_mem2_stall_o;

    ex_mem1_stall_o = mem1_mem2_stall_o;

    // let stall take priority over flushes, this fixes the case where an instruction say X is stuck in ex needing an operand which is yet to become ready
    // normally we would stall if - id and flush ex but if a later stage like mem1 or mem2 needs to stall, we can't flush ex since that
    // would erase the instruction older than X

    ex_mem1_flush_o = load_use_hzrd & !ex_mem1_stall_o;

    id_ex_stall_o = load_use_hzrd || ex_mem1_stall_o;

    if_stall_o = ex_is_csr_i || mem1_is_csr_i || mem2_is_csr_i || id_ex_stall_o || (state == IRQ_WAIT);
    if_flush_o = '0;

    id_ex_flush_o = if_stall_o & !id_ex_stall_o; // need to flush id_ex if we are currently not accepting any instructions, but don't flush if a stall is requested
    // since this could mean a general pipeline stall is requested and the instruction in id_ex is to be kept

    take_exception = '0;

    // instruction in the MEM2 stage raised a trap
    if (trap_happened)
    begin
        id_ex_flush_o = 1'b1;
        ex_mem1_flush_o = 1'b1;
        mem1_mem2_flush_o = 1'b1;
        take_exception = 1'b1;
    end
    else if (ex_new_pc_en_i) // EX determined that the branch was taken
    begin
        // for now the branch is always predicted as not taken, hence if it's taken
        // we must flush the wrong instruction currently in id_ex
        id_ex_flush_o = 1'b1;
    end
end

endmodule: controller