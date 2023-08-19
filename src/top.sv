module top
(
    input clk_i
);

logic rstn, rstn_t;
logic imem_read;
logic [31:0] imem_raddr;
logic [31:0] imem_rdata;

// Instruction Memory
sp_mem #(.MEMFILE(`MEMFILE)) sp_mem_i
(
    .clk_i(clk_i),
    .rstn_i(rstn),

    .read_i(imem_read),
    .raddr_i(imem_raddr[31:2]), // 4-byte addressable
    .rdata_o(imem_rdata),

    .write_i(0),
    .waddr_i(0),
    .wdata_i(0)
);

// Core Top
core_top yarc_top
(
    .clk_i(clk_i),
    .rstn_i(rstn),

    // Core <-> Imem interface
    .imem_read_o(imem_read),
    .imem_raddr_o(imem_raddr),
    .imem_rdata_i(imem_rdata)
);

always_ff @(posedge clk_i)
begin
    rstn <= rstn_t;
end

initial
begin
    rstn_t = 1;
    repeat(2) @(posedge clk_i);

    rstn_t = 0;
    repeat(2) @(posedge clk_i);

    rstn_t = 1;
end

endmodule
