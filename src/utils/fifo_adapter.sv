// acts as a frontend for a fifo
// usefull in the case where we need to read variable size data from the fifo

// TODO: paramterize this module
module fifo_adapter
(
    input clk_i,
    input rstn_i,

    // connection to fif
    input empty_i,
    output logic re_o,
    input [127:0] rdata_i,

    // read interface
    input re_i, // CAUTION: no delay read, because lines are not BRAM
    input rsize_i, // 0 -> 16bit, 1 -> 32bit
    output logic [31:0] rdata_o,
    output logic empty_o
);

logic [127:0] lines_q [1:0];
logic [127:0] lines_d [1:0];

logic [1:0] active_index_q, active_index_d; 
logic [1:0] fill_index_q, fill_index_d; 
logic fill_index, active_index; // actual indices to use
logic fill_line;

assign fill_index = fill_index_q[0];
assign active_index = active_index_q[0];

logic empty, full;
assign empty = (active_index_q == fill_index_q);
assign full = (active_index_q[0] == fill_index_q[0]) & ~empty;

enum {REQ, SAVE} state, next;
always_ff @(posedge clk_i)
    if (!rstn_i) state <= REQ;
    else         state <= next;

always_comb begin: sm
    next = state;

    fill_index_d = fill_index_q;
    fill_line = '0;
    re_o = '0;

    case (state)

        REQ: begin
            if (~empty_i & ~full) begin
                re_o = 1'b1;
                next = SAVE;
            end
        end

        SAVE: begin
            fill_line = 1'b1;
            fill_index_d = fill_index_q + 1'b1;
            next = REQ;
        end

    endcase
end

logic [2:0] shift_amount;
assign shift_amount = rsize_i ? 'd4 : 'd2; // in bytes

// reading side
assign rdata_o = lines_q[active_index];

logic [4:0] bytes_left_d, bytes_left_q;

always_comb begin: read_size
    lines_d = lines_q;
    bytes_left_d = bytes_left_q;
    active_index_d = active_index_q;

    if (fill_line) begin
        lines_d[fill_index] = rdata_i;
    end

    if (re_i & ~empty) begin
        lines_d[active_index] >>= (shift_amount * 8);

        if (bytes_left_q == shift_amount) begin // this line is now empty
            active_index_d += 'd1;
            bytes_left_d = 'd16;
        end else begin
            bytes_left_d -= shift_amount;
        end
    end
end

always_ff @(posedge clk_i, negedge rstn_i) begin
    if (!rstn_i) begin
        active_index_q <= '0;
        fill_index_q <= '0;
        bytes_left_q <= 'd16; // 16 bytes left
    end else begin
        active_index_q <= active_index_d;
        fill_index_q <= fill_index_d;
        lines_q <= lines_d;
        bytes_left_q <= bytes_left_d;
    end
end

assign empty_o = empty;

endmodule: fifo_adapter
