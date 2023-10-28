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
    else if (flush_i)
        instr_o <= '0;
    else
        instr_o <= rdata_i;
end

// prefetch state machine

enum logic [1:0] {INIT, NEW_PC, CONT_PC} state = INIT, state_r = INIT;

always_comb
begin : pfetch_sm
    state = state_r;
    read_o = 0;
    valid_o = 0;
    pc = pc_r;
    
    unique case (state)
        INIT:
        begin
            state = NEW_PC;
        end

        CONT_PC:
        begin
            read_o = 1;
            valid_o = 1;

            if (new_pc_i)
            begin
                pc = pc_i;
                state = NEW_PC;
            end
            else if (!stall_i)
                pc = pc + 4;
        end

        NEW_PC:
        begin
            read_o = 1;
            valid_o = 0;
            state = CONT_PC;

            // if (!stall_i)
            //     pc = pc + 4;
        end
    endcase
end

always_ff @(posedge clk_i, negedge rstn_i)
begin
    if (!rstn_i)
    begin
        state_r <= INIT;
        pc_r <= 'h8000_0000;
    end
    else
    begin
        state_r <= state;
        pc_r <= pc;
    end
end

endmodule :simple_fetch