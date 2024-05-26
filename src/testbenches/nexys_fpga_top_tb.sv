
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

logic ddr3_clk_n;
logic ddr3_clk_p;

logic [14:0] ddr3_addr;
logic [2:0] ddr3_ba;
logic ddr3_cas;
logic ddr3_cke;
logic [1:0] ddr3_dm;
wire [15:0] ddr3_dq;
wire [1:0] ddr3_dqs_n;
wire [1:0] ddr3_dqs_p;
logic ddr3_odt;
logic ddr3_ras;
logic ddr3_reset;
logic ddr3_we;

nexys_fpga_top dut
(
    .clk(clk),
    .cpu_resetn(rstn),
    .led(led),
    
    .uart_rx_out(uart_rx_out),
    .uart_tx_in(uart_tx_in),

    .ddr3_clk_n_o(ddr3_clk_n),
    .ddr3_clk_p_o(ddr3_clk_p),

    .ddr3_addr_o(ddr3_addr),
    .ddr3_ba_o(ddr3_ba),
    .ddr3_cas_o(ddr3_cas),
    .ddr3_cke_o(ddr3_cke),
    .ddr3_dm_o(ddr3_dm),

    .ddr3_dq_io(ddr3_dq),
    .ddr3_dqs_n_io(ddr3_dqs_n),
    .ddr3_dqs_p_io(ddr3_dqs_p),

    .ddr3_odt_o(ddr3_odt),
    .ddr3_ras_o(ddr3_ras),
    .ddr3_reset_o(ddr3_reset),
    .ddr3_we_o(ddr3_we)
);

// DDR3 simulation model
ddr3_sim_model ddr3_sim_model_i(
    .rst_n(ddr3_reset),
    .ck(ddr3_clk_p),
    .ck_n(ddr3_clk_n),
    .cke(ddr3_cke),
    .cs_n('0),
    .ras_n(ddr3_ras),
    .cas_n(ddr3_cas),
    .we_n(ddr3_we),
    .dm_tdqs(ddr3_dm),
    .ba(ddr3_ba),
    .addr(ddr3_addr),
    .dq(ddr3_dq),
    .dqs(ddr3_dqs_p),
    .dqs_n(ddr3_dqs_n),
    .tdqs_n(),
    .odt(ddr3_odt)
);

initial
begin
    rstn = 1'b0;
    repeat(30000) @(posedge clk);
    rstn = 1'b1;

    // repeat(100000) @(posedge clk);
    // $finish;
end

endmodule: nexys_fpga_top_tb
