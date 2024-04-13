// contains the core with memories
// instantiated by testbenches

module verilator_top
#(parameter string DMEMFILE = "", parameter string IMEMFILE = "")
(
    input clk,
    input pixel_clk,
    input pixel_clk_5x
);

import platform_pkg::*;

// localparam MAIN_CLK_HALF_PERIOD = 12.5ns / 2;
// localparam PIXEL_CLK_HALF_PERIOD = 29.6825ns / 2;
// localparam PIXEL_CLK_5X_HALF_PERIOD = PIXEL_CLK_HALF_PERIOD / 5;

// clk generation
// logic clk, pixel_clk, pixel_clk_5x;

// drive clock
// initial
// begin
//     clk = 0;
//     forever clk = #MAIN_CLK_HALF_PERIOD ~clk;
// end

// initial
// begin
//     pixel_clk = 0;
//     forever pixel_clk = #PIXEL_CLK_HALF_PERIOD ~pixel_clk;
// end

// initial
// begin
//     pixel_clk_5x = 0;
//     forever pixel_clk_5x = #PIXEL_CLK_5X_HALF_PERIOD ~pixel_clk_5x;
// end


logic rstn = '0;
logic rstn_t = '0;
always @(posedge clk)
begin
    rstn <= rstn_t;    
end

initial
begin
    rstn_t = 1'b0;
    repeat(5) @(posedge clk);
    rstn_t = 1'b1;

    repeat(500000) @(posedge clk);
    $finish;
end

wishbone_if imem_wb_if();

// Instruction Memory
sp_mem_wb #(.MEMFILE(IMEMFILE), .SIZE_POT(15)) imem
(
    .clk_i(clk),

    .cyc_i(imem_wb_if.cyc),
    .stb_i(imem_wb_if.stb),

    .we_i(imem_wb_if.we),
    .addr_i(imem_wb_if.addr), // 4-byte addressable
    .sel_i(imem_wb_if.sel),
    .wdata_i(imem_wb_if.wdata),

    .rdata_o(imem_wb_if.rdata),
    .rty_o(imem_wb_if.rty),
    .ack_o(imem_wb_if.ack),
    .stall_o(imem_wb_if.stall),
    .err_o(imem_wb_if.err)
);

wishbone_if dmem_wb_if();

// Data Memory
sp_mem_wb #(.MEMFILE(DMEMFILE), .SIZE_POT(15)) dmem
(
    .clk_i(clk),

    .cyc_i(dmem_wb_if.cyc),
    .stb_i(dmem_wb_if.stb),

    .we_i(dmem_wb_if.we),
    .addr_i(dmem_wb_if.addr), // 4-byte addressable
    .sel_i(dmem_wb_if.sel),
    .wdata_i(dmem_wb_if.wdata),

    .rdata_o(dmem_wb_if.rdata),
    .rty_o(dmem_wb_if.rty),
    .ack_o(dmem_wb_if.ack),
    .stall_o(dmem_wb_if.stall),
    .err_o(dmem_wb_if.err)
);

logic uart_tx;

logic hdmi_clk;
logic [2:0] hdmi_data;

yarc_platform yarc_platform_i
(
    .clk_i(clk),
    .rstn_i(rstn),

    // Core <-> DMEM
    .dmem_wb_if(dmem_wb_if),

    // Core <-> IMEM
    .instr_fetch_wb_if(imem_wb_if),

    // Platform <-> Peripherals
    .led_status_o(),

    // Platform <-> UART
    .uart_rx_i(1'b1),
    .uart_tx_o(uart_tx),

    // Platform <-> HDMI
    .pixel_clk_i(pixel_clk),
    .pixel_clk_5x_i(pixel_clk_5x),
    .hdmi_clk_o(hdmi_clk),
    .hdmi_data_o(hdmi_data)
);

// simulation Uart Rx
rxuart_printer
#(.CLKS_PER_BAUD(CLKS_PER_BAUD))
rxuart_printer_i
(
    .clk_i(clk),
    .reset_i(~rstn),

    .uart_rx_i(uart_tx)
);

// Print some stuff as an example
initial begin
    if ($test$plusargs("trace") != 0) begin
        $display("[%0t] Tracing to logs/vlt_dump.fst...\n", $time);
        $dumpfile("logs/vlt_dump.fst");
        $dumpvars();
    end
    $display("[%0t] Model running...\n", $time);
end

endmodule: verilator_top
