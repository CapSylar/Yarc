module tb();

logic clk;
logic rstn;

// dut
top top_i (.clk_i(clk), .rstn_i(rstn));

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
    rstn = 1;    
    repeat(2) @(posedge clk);
    rstn = 0;
    @(posedge clk);
    rstn = 1;

    repeat(1000) @(posedge clk);

    $finish;
end

// handles trace
initial begin
        $dumpfile("logs/vlt_dump.fst");
        $dumpvars();
end

endmodule : tb