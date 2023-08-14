module tb();

logic clk;
logic rstn;

logic [4:0] counter;

counter counter_i (.clk_i(clk), .rstn_i(rstn), .counter_o(counter));

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

    for (int i = 0; i < 100 ; ++i)
    begin
        $display("counter is %d", counter);
        @(posedge clk);
    end

    $finish;
end

// handles trace
initial begin
    // if ($test$plusargs("trace") != 0) begin
        $display("[%0t] Tracing to logs/vlt_dump.vcd...\n", $time);
        $dumpfile("logs/vlt_dump.vcd");
        $dumpvars();
    // end
    $display("[%0t] Model running...\n", $time);
end

endmodule : tb