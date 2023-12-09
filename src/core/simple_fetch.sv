// cpu fetch module, interfaces with the simple simulation memories

module simple_fetch
import riscv_pkg::*;
import csr_pkg::*;
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

logic [31:0] pc;
logic [31:0] pc_r;
logic [31:0] new_pc;

// calculate the expection target address from mtvec and mcause
logic [31:0] exc_target_addr;
always_comb
begin
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
        PC_TRAP:  new_pc = exc_target_addr;
        default:;
    endcase
end

assign raddr_o = pc;
assign pc_o = pc_r;

always @(posedge clk_i, negedge rstn_i)
begin
    if (!rstn_i)
        instr_o <= '0;
    // else if (flush_i)
    //     instr_o <= '0;
    else
        instr_o <= rdata_i;
end

// prefetch state machine

enum {IDLE, NEW_PC, CONT_PC, STALLED} current_state, next_state;

// next state logic
always_ff @(posedge clk_i, negedge rstn_i)
    if (!rstn_i) current_state <= IDLE;
    else current_state <= next_state;

always_comb
begin : pfetch_sm
    next_state = current_state;
    read_o = 0;
    valid_o = 0;
    pc = pc_r;
    
    unique case (current_state)
        IDLE:
        begin
            next_state = NEW_PC;
        end

        CONT_PC:
        begin
            read_o = 1'b1;
            valid_o = 1'b1;

            if (stall_i)
            begin
                next_state = STALLED;
                valid_o = 1'b0;
            end
            else if (new_pc_en_i)
            begin
                pc = new_pc;
                next_state = NEW_PC;
            end
            else
                pc = pc + 4;
        end

        NEW_PC:
        begin
            read_o = 1'b1;
            valid_o = 1'b0;
            next_state = CONT_PC;

            if (new_pc_en_i)
            begin
                pc = new_pc;
                next_state = NEW_PC;
            end
        end

        STALLED:
        begin
            valid_o = 1'b0;

            if (!stall_i)
                next_state = NEW_PC;
        end
    endcase
end

always_ff @(posedge clk_i, negedge rstn_i)
begin
    if (!rstn_i)
    begin
        pc_r <= 'h8000_0000;
    end
    else
    begin
        pc_r <= pc;
    end
end

endmodule :simple_fetch