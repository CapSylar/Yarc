// simple skidbuffer, nothing fancy
`default_nettype none

module skid_buffer
#(parameter type T = logic)
(
    input wire clk_i,
    input wire rstn_i,

    // input side
    input wire valid_i,
    input T data_i,
    output logic ready_o,

    // output side
    output logic valid_o,
    output T data_o,
    input wire ready_i
);

logic internal_valid_d, internal_valid_q;
T buffer_d, buffer_q;

assign buffer_d = internal_valid_q ? buffer_q : data_i;

always_comb begin
    internal_valid_d = internal_valid_q;

    // data coming but the output port is not ready to receive it
    if (valid_i && ready_o && !ready_i) begin
        internal_valid_d = 1'b1; // save it
    end else if (ready_i) begin
        internal_valid_d = 1'b0;
    end
end

always_ff @(posedge clk_i) begin
    if (!rstn_i) begin
        buffer_q <= '0;
        internal_valid_q <= '0;
    end else begin 
        buffer_q <= buffer_d;
        internal_valid_q <= internal_valid_d;
    end
end

assign valid_o = internal_valid_q | valid_i;
assign data_o = internal_valid_q ? buffer_q : data_i ;

// the only time we don't accept more data is when the internal buffer is filled
assign ready_o = ~internal_valid_q;

endmodule: skid_buffer
