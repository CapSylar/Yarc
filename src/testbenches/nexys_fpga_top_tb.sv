
module nexys_fpga_top_tb();

localparam CLK_HALF_PERIOD = 5ns;

// clk generation
logic clk;

// drive clock
initial
begin
    clk = 0;
    forever
    begin
        #CLK_HALF_PERIOD;
        clk = ~clk;
    end
end

logic rstn;
logic [7:0] led;

nexys_fpga_top dut
(
    .clk(clk),
    .cpu_resetn(rstn),
    .led(led)
);

initial
begin
    repeat(50) @(posedge clk);
    #2ns;
    rstn = 1'b0;
    #50ns;
    rstn = 1'b1;

    repeat(10000) @(posedge clk);
    $finish;
end

endmodule: nexys_fpga_top_tb