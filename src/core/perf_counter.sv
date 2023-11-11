module perf_counter
(
    input clk_i,
    input rstn_i,

    input inc_en_i, // enable incrementing

    // write port
    input we_i, // write enable [31:0]
    input weh_i, // write enable [63:31]
    input [31:0] w_value_i, // write value

    output [63:0] value_o
);

logic [63:0] counter_d, counter_q;

always_comb
begin: next_value
    // in a cycle where a write is happening, the counter will not increment
    counter_d = counter_q;

    if (we_i)
        counter_d[31:0] = w_value_i;
    else if (weh_i)
        counter_d[63:32] = w_value_i;
    else if (inc_en_i)
        counter_d = counter_d + 1'b1;
end

always_ff @(posedge clk_i, negedge rstn_i)
begin
    if (!rstn_i)
        counter_q <= '0;
    else 
        counter_q <= counter_d;
end

// assign outputs
assign value_o = counter_q;

endmodule: perf_counter