// True dual port memory with byte-wide write enable

module tdp_mem
#(parameter int WIDTH = 0, parameter int DEPTH = 0)
(
    // port 1 A R/W
    input clk_a_i,
    input en_a_i,
    input we_a_i,
    input [WIDTH/8 -1:0] wsel_byte_a_i,
    input [DEPTH-1:0] addr_a_i,
    input [WIDTH-1:0] wdata_a_i,
    output logic [WIDTH-1:0] rdata_a_o,

    // port 2 B R
    input clk_b_i,
    input en_b_i,
    input [DEPTH-1:0] addr_b_i,
    output logic [WIDTH-1:0] rdata_b_o
);

// memory
logic [WIDTH-1:0] mem [2**DEPTH];

// port a operations
always_ff@ (posedge clk_a_i)
begin
    if (en_a_i)
    begin
        // write
        if (we_a_i)
        begin
            // for each byte, if the corresponding bit in wsel_byte is 1, write it
            for (int i = 0; i < WIDTH/8; ++i)
                if (wsel_byte_a_i[i])
                    mem[addr_b_i][(i+1)*8 -1 -:8] <= wdata_a_i[(i+1)*8 -1 -:8];
        end
        // read
        rdata_a_o <= mem[addr_a_i];
    end
end

// port b operations
always_ff @(posedge clk_b_i)
begin
    if (en_b_i)
    begin
        rdata_b_o <= mem[addr_b_i];
    end
end

endmodule: tdp_mem