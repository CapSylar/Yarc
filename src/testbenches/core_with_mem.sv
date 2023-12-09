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

    repeat(10000) @(posedge clk);
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

logic [31:0] dmem_addr;
logic dmem_read;
logic [31:0] dmem_rdata;
logic [3:0] dmem_wsel_byte;
logic [31:0] dmem_wdata;
logic dmem_en;

// Data Memory
sp_mem #(.MEMFILE(DMEMFILE), .SIZE_POT(15)) dmem
(
    .clk_i(clk),
    .en_i(dmem_en),

    .read_i(dmem_read),
    .addr_i(dmem_addr[31:2]), // 4-byte addressable
    .rdata_o(dmem_rdata),

    .wsel_byte_i(dmem_wsel_byte),
    .wdata_i(dmem_wdata)
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
    .dmem_en_o(dmem_en),
    .dmem_addr_o(dmem_addr),
    // read port
    .dmem_read_o(dmem_read),
    .dmem_rdata_i(dmem_rdata),
    // write port
    .dmem_wsel_byte_o(dmem_wsel_byte),
    .dmem_wdata_o(dmem_wdata)
);

endmodule: core_with_mem