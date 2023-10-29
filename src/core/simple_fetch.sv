// cpu fetch module, interfaces with the simple simulation memories

module simple_fetch
(
    input clk_i,
    input rstn_i,

    // CPU <-> fetch interface

    output logic valid_o, // a valid instruction is presented
    output logic [31:0] instr_o, // the instruction, only valid when valid_o = 1
    output [31:0] pc_o, // program counter of the instruction presented to the cpu

    input stall_i, // is the cpu stalled ?
    input flush_i,

    // used on a jump
    input [31:0] pc_i,
    input new_pc_i,

    // fetch <-> memory interface

    output logic read_o,
    output [31:0] raddr_o,
    input [31:0] rdata_i
);

logic [31:0] pc;
logic [31:0] pc_r;

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
            else if (new_pc_i)
            begin
                pc = pc_i;
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

            // if (!stall_i)
            //     pc = pc + 4;
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