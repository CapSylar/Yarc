
module clk_gen
#(parameter unsigned PERIOD)
(
    output logic clk_o
);

initial begin
    clk_o = '0;
    forever clk_o = #(PERIOD/2) ~clk_o;
end

endmodule: clk_gen
