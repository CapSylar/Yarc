// contains the core with memories
// instantiated by testbenches

module core_with_mem
#(parameter string DMEMFILE = "", parameter string IMEMFILE = "") ();

// clk generation
logic clk;

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

    repeat(100000) @(posedge clk);
    $finish;
end

wishbone_if imem_wb_if();

// Instruction Memory
sp_mem_wb #(.MEMFILE(IMEMFILE), .SIZE_POT(15)) imem
(
    .clk_i(clk),

    .cyc_i(imem_wb_if.cyc),
    .stb_i(imem_wb_if.stb),
    .lock_i(imem_wb_if.lock),

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
    .lock_i(dmem_wb_if.lock),

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

yarc_platform yarc_platform_i
(
    .clk_i(clk),
    .rstn_i(rstn),

    // Core <-> DMEM
    .dmem_wb(dmem_wb_if.MASTER),

    // Core <-> IMEM
    .imem_wb(imem_wb_if.MASTER),

    // Platform <-> Peripherals
    .led_status_o()
);

endmodule: core_with_mem