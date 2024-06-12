
module text_mode_line_buffer
(
    input clk_i,
    input rstn_i,

    // fifo interface port
    input empty_i,
    output logic re_o, // CAUTION: assumes no delay read
    input [15:0] rdata_i,

    // read port
    input re_i,
    input pop_line_i, // fetches a new line thereafter
    output logic empty_o,
    input [7:0] char_idx_i,

    output logic [15:0] data_o
);

logic [15:0] buffer [80]; // holds 80 characters
logic [8:0] fill_idx_d, fill_idx_q;
logic write_buffer;

enum {FILLING_LINE, IDLE} state, next;
always_ff @(posedge clk_i)
    if (!rstn_i) state <= FILLING_LINE;
    else         state <= next;

always_comb begin: sm
    next = state;

    re_o = '0;
    write_buffer = '0;
    fill_idx_d = fill_idx_q;

    case(state)
        FILLING_LINE: begin
            if (fill_idx_q == 'd80) begin // check for full
                next = IDLE;
            end else if (~empty_i) begin
                re_o = 1'b1;
                write_buffer = 1'b1;
                fill_idx_d += 'd1;
            end
        end

        IDLE: begin
            fill_idx_d = '0; // reset counter
            if (pop_line_i) begin
                next = FILLING_LINE;
            end
        end
    endcase
end

always_ff @(posedge clk_i) begin: write_b
    if (write_buffer)
        buffer[fill_idx_q] <= rdata_i;
end

always_ff @(posedge clk_i, negedge rstn_i) begin
    if (!rstn_i) begin
        fill_idx_q <= '0;
    end else begin
        fill_idx_q <= fill_idx_d;
    end
end

// read side
always_ff @(posedge clk_i) begin
    if (re_i) begin
        data_o <= buffer[char_idx_i];
    end
end

endmodule: text_mode_line_buffer
