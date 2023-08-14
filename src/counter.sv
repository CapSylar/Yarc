module counter
(
    input clk_i,
    input rstn_i,

    output [4:0] counter_o
);

logic [4:0] counter;
assign counter_o = counter;

always_ff @(posedge clk_i, negedge rstn_i)
begin
    if (!rstn_i)
        counter <= 0;
    else
        counter <= counter + 1;
end

endmodule: counter