// cpu fetch module, interfaces with the simple simulation memories
// assumes a memory with synchronous reading

module simple_fetch
import riscv_pkg::*;
import csr_pkg::*;
#(parameter bit [31:0] BOOT_PC = 'h8000_0000)
(
    input clk_i,
    input rstn_i,

    // CPU <-> fetch interface
    output logic valid_o, // a valid instruction is presented
    output logic [31:0] instr_o, // the instruction, only valid when valid_o = 1
    output [31:0] pc_o, // program counter of the instruction presented to the cpu

    input stall_i, // is the cpu stalled ?
    input flush_i,

    input new_pc_en_i, // load a new pc
    input pc_sel_t pc_sel_i, // which pc to load from the addresses below

    // target addresses
    input [31:0] branch_target_i,
    input [31:0] csr_mepc_i,
    input var mcause_t mcause_i, // comes from the controller, not csr module
    input var mtvec_t mtvec_i,

    // fetch <-> memory interface
    output logic read_o,
    output [31:0] raddr_o,
    input [31:0] rdata_i
);

logic [31:0] raddr_q, raddr_d;
logic [31:0] arch_pc_q, arch_pc_d;

logic [31:0] new_pc;
logic [31:0] instr_buffer_q, instr_buffer_d;
logic present_buffer;

// calculate the expection target address from mtvec and mcause
logic [31:0] exc_target_addr;
always_comb
begin
    exc_target_addr = '0;

    case (mtvec_i.mode)
        MTVEC_DIRECT: exc_target_addr = {mtvec_i.base, 2'b00};
        MTVEC_VECTORED: exc_target_addr = {mtvec_i.base + mcause_i.trap_code, 2'b00};
        default:;
    endcase
end

// determine the new pc
always_comb
begin
    new_pc = '0;
    unique case (pc_sel_i)
        PC_JUMP: new_pc = branch_target_i;
        PC_MEPC: new_pc = csr_mepc_i;
        PC_TRAP: new_pc = exc_target_addr;
        default:;
    endcase
end

// fetch state machine
enum {BOOT, ADDRESS_PHASE, CONT_PC, STALLED} current_state, next_state;

// next state logic
always_ff @(posedge clk_i)
    if (!rstn_i) current_state <= BOOT;
    else current_state <= next_state;

always_comb
begin : pfetch_sm
    next_state = current_state;
    read_o = '0;
    valid_o = '0;
    raddr_d = raddr_q;
    present_buffer = '0;
    instr_buffer_d = instr_buffer_q;

    unique case (current_state)
        BOOT:
        begin
            raddr_d = BOOT_PC;
            next_state = ADDRESS_PHASE;
        end

        ADDRESS_PHASE:
        begin
            read_o = 1'b1;
            valid_o = 1'b0;
            next_state = CONT_PC;

            raddr_d = raddr_q + 4;
        end

        CONT_PC:
        begin
            read_o = 1'b1;
            valid_o = 1'b1;

            if (flush_i)
            begin
                next_state = ADDRESS_PHASE;
            end
            else if (stall_i)
            begin
                next_state = STALLED;
                instr_buffer_d = rdata_i; // save it
            end
            else
                raddr_d = raddr_q + 4;
        end

        STALLED:
        begin
            valid_o = 1'b1;
            present_buffer = 1'b1;

            if (!stall_i)
            begin
                next_state = CONT_PC;
                raddr_d = raddr_q + 4;
            end
        end
    endcase

    // if (flush_i)
    // begin
    //     next_state = ADDRESS_PHASE;
    //     raddr_d = raddr_q;
    // end
    // else if (stall_i)
    // begin
    //     next_state = STALLED;
    //     raddr_d = raddr_q;
    //     instr_buffer_d = rdata_i; // save it
    // end
    if (new_pc_en_i)
    begin
        // logic that override the next_state logic
        // should respond to a new_pc_en request irrespective of the state we are currently in
        next_state = ADDRESS_PHASE;
        raddr_d = new_pc;
    end
end

always_ff @(posedge clk_i)
begin
    if (!rstn_i)
    begin
        raddr_q <= '0;
        arch_pc_q <= '0;
        instr_buffer_q <= '0;
    end
    else
    begin
        raddr_q <= raddr_d;
        instr_buffer_q <= instr_buffer_d;

        if (!stall_i)
            arch_pc_q <= arch_pc_d;
    end
end

assign arch_pc_d = raddr_q;

// assign outputs
assign raddr_o = raddr_q;
assign instr_o = present_buffer ? instr_buffer_q : rdata_i;
assign pc_o = arch_pc_q;

endmodule :simple_fetch