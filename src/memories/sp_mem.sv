// crude single port memory
// reading is asynchronous, data read out is assumed to be ready in less than a clock cycle

module sp_mem
#(parameter WIDTH = 32, parameter ADDR_WIDTH = 30, parameter SIZE_POT = 10, parameter string MEMFILE = "")
(
    input clk_i,
    input en_i,

    input read_i,
    input [ADDR_WIDTH-1:0] addr_i,
    output logic [WIDTH-1:0] rdata_o,

    input [WIDTH/8 -1:0] wsel_byte_i, // each byte has a bit in wsel_byte_i
    input [WIDTH-1:0] wdata_i
);

logic [WIDTH-1:0] mem [2**SIZE_POT];

// load memory image
initial
begin
    $readmemh(MEMFILE, mem);
end

always_comb
begin
    rdata_o = 32'b0;

    if (en_i & read_i)
        rdata_o = mem[addr_i[SIZE_POT-1:0]];
end

always_ff @(posedge clk_i)
begin : write_mem
    if (en_i)
    begin
        // for each byte, if the corresponding bit in wsel_byte in 1, write it
        for (int i = 0; i < WIDTH/8 ; ++i)
            if (wsel_byte_i[i])
                mem[addr_i[SIZE_POT-1:0]][(i+1)*8 -1 -:8] <= wdata_i[(i+1)*8 -1 -:8];
    end
end

endmodule: sp_mem