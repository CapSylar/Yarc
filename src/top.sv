module top(
    input clk,
    input rstn,

    output logic [3:0] counter_o
);

always_ff @(posedge clk, negedge rstn)
begin
    if (!rstn)
        counter_o <= 0;
    else
    begin
        `ifdef DOUBLE_COUNTING
            counter_o <= counter_o + 2;
        `else // DOUBLE_COUNTING
            counter_o <= counter_o + 1;
        `endif // DOUBLE_COUNTING
    end
end

endmodule
