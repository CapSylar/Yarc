
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
logic uart_rx_out;
logic uart_tx_in;

assign uart_tx_in = 1'b1;

nexys_fpga_top dut
(
    .clk(clk),
    .cpu_resetn(rstn),
    .led(led),
    
    .uart_rx_out(uart_rx_out),
    .uart_tx_in(uart_tx_in)
);

initial
begin
    rstn = 1'b0;
    repeat(300) @(posedge clk);
    rstn = 1'b1;

    repeat(100000) @(posedge clk);
    $finish;
end

endmodule: nexys_fpga_top_tb