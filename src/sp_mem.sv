// crude single port memory

module sp_mem
#(parameter WIDTH = 32, parameter ADDR_WIDTH = 30, parameter SIZE = 1000, parameter string MEMFILE = "")
(
    input clk_i,
    input rstn_i,

    input read_i,
    input [ADDR_WIDTH-1:0] raddr_i,
    output logic [WIDTH-1:0] rdata_o,

    input write_i,
    input [ADDR_WIDTH-1:0] waddr_i,
    input [WIDTH-1:0] wdata_i
);

logic [WIDTH-1:0] mem [1000];

// load memory image

initial
begin
    $readmemh(MEMFILE, mem);
end

always_ff @(posedge clk_i, negedge rstn_i)
begin : read_mem
    if (!rstn_i)
        rdata_o <= 0;
    else if (read_i)
        rdata_o <= mem[raddr_i[9:0]];
end

always_ff @(posedge clk_i)
begin : write_mem
    if (write_i)
        mem[waddr_i[9:0]] <= wdata_i;
end


endmodule: sp_mem