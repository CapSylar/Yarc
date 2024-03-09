// simulation memory with 2 read ports and 1 write port
module dp_mem
#(parameter int WIDTH = 32, parameter int DEPTH = 10, parameter string MEMFILE = "")
(
    input clk_i,

    // port 1
    input en_a_i,
    input [DEPTH-1:0] addr_a_i,
    output logic [WIDTH-1:0] rdata_a_o,

    // port 2
    input en_b_i,
    input [DEPTH-1:0] addr_b_i,
    output logic [WIDTH-1:0] rdata_b_o,
    input [WIDTH/8 -1:0] wsel_byte_b_i,
    input [WIDTH-1:0] wdata_b_i
);

logic [WIDTH-1:0] mem [2**DEPTH];

// load memory image
initial
begin
    $readmemh(MEMFILE, mem);
end

// handle read for both ports
always_comb
begin
    rdata_a_o = 32'b0;
    rdata_b_o = 32'b0;

    if (en_a_i)
        rdata_a_o = mem[addr_a_i];
    
    if (en_b_i)
        rdata_b_o = mem[addr_b_i];
end

// handle write for port b
always_ff @(posedge clk_i)
begin
    if (en_b_i)
    begin
        // for each byte, if the corresponding bit in wsel_byte is 1, write it
        for (int i = 0; i < WIDTH/8 ; ++i)
            if (wsel_byte_b_i[i])
                mem[addr_b_i][(i+1)*8 -1 -:8] <= wdata_b_i[(i+1)*8 -1 -:8];
    end
end

endmodule: dp_mem