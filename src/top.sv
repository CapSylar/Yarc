module top
(
    input clk_i,
    input rstn_i
);

logic read;
logic [31:0] raddr;
logic [31:0] rdata;

logic write;
logic [29:0] waddr;
logic [31:0] wdata;

logic [31:0] new_pc, new_pc_t;
logic is_new_pc, is_new_pc_t;

logic stall;
logic [31:0] pc;
logic [31:0] instr;
logic valid;

sp_mem #(.MEMFILE(`MEMFILE)) sp_mem_i
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),

    .read_i(read),
    .raddr_i(raddr[31:2]), // 4-byte addressable
    .rdata_o(rdata),

    .write_i(write),
    .waddr_i(waddr),
    .wdata_i(wdata)
);

simple_fetch simple_fetch_i
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),

    .valid_o(valid),
    .instr_o(instr),
    .pc_o(pc),

    .stall_i(stall),

    .pc_i(new_pc),
    .new_pc_i(is_new_pc),

    .read_o(read),
    .raddr_o(raddr),
    .rdata_i(rdata)
);

// temp variable driven directly

always_ff @(posedge clk_i)
begin
    is_new_pc <= is_new_pc_t;
    new_pc <= new_pc_t;
end

initial
begin
    write = 0;
    waddr = 0;
    wdata = 0;

    is_new_pc_t = 0;
    new_pc_t = 0;

    stall = 1;

    @(posedge valid);
    
    repeat(2) @(posedge clk_i);

    stall = 0;

    repeat(4) @(posedge clk_i);

    is_new_pc_t = 1;
    new_pc_t = 28;

    @(posedge clk_i);

    is_new_pc_t = 0;
    new_pc_t = 0;
end

endmodule
