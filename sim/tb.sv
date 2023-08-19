module tb();

logic clk;

// dut
top top_i (.clk_i(clk));

// drive clock
initial
begin
    clk = 0;

    forever
    begin
        #5;
        clk = ~clk;
    end
end

initial
begin
    repeat(1000) @(posedge clk);

    $finish;
end

// handles trace
initial begin
        $dumpfile("logs/vlt_dump.fst");
        $dumpvars();
end

endmodule : tb