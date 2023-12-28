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

logic rstn, rstn_t;
always @(posedge clk)
begin
    rstn <= rstn_t;    
end

initial
begin
    rstn_t = 1'b1;
    @(posedge clk);
    rstn_t = 1'b0;
    repeat(2) @(posedge clk);
    rstn_t = 1'b1;

    repeat(100000) @(posedge clk);
    $finish;
end

logic imem_en;
logic [31:0] imem_raddr;
logic [31:0] imem_rdata;

// Instruction Memory
sp_mem #(.MEMFILE(IMEMFILE), .SIZE_POT(15)) imem
(
    .clk_i(clk),
    .en_i(imem_en),

    .read_i(1'b1),
    .addr_i(imem_raddr[31:2]), // 4-byte addressable
    .rdata_o(imem_rdata),

    .wsel_byte_i('0),
    .wdata_i('0)
);

wishbone_if wb_if();

// Data Memory
sp_mem_wb #(.MEMFILE(DMEMFILE), .SIZE_POT(15)) dmem
(
    .clk_i(clk),

    .cyc_i(wb_if.cyc),
    .stb_i(wb_if.stb),
    .lock_i(wb_if.lock),

    .we_i(wb_if.we),
    .addr_i(wb_if.addr[31:2]), // 4-byte addressable
    .sel_i(wb_if.sel),
    .wdata_i(wb_if.wdata),

    .rdata_o(wb_if.rdata),
    .rty_o(wb_if.rty),
    .ack_o(wb_if.ack),
    .stall_o(wb_if.stall),
    .err_o(wb_if.err)
);

yarc_platform yarc_platform_i
(
    .clk_i(clk),
    .rstn_i(rstn),

    // Core <-> Imem interface
    .imem_en_o(imem_en),
    .imem_raddr_o(imem_raddr),
    .imem_rdata_i(imem_rdata),

    // Core <-> Dmem interface
    .dmem_wb(wb_if.MASTER),

    // Platform <-> Peripherals
    .led_status_o()
);

endmodule: core_with_mem