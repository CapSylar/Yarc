
// Simple dual port memory
// Read access through port A
// Write access is allowed through port B

module sdp_mem
#(parameter int DW = 32, parameter int AW = 10, parameter bit INIT_MEM = '0, parameter string MEMFILE = "")
(
    input clk_i,

    // port 1
    input en_a_i,
    input [AW-1:0] addr_a_i,
    output logic [DW-1:0] rdata_a_o,

    // port 2
    input en_b_i,
    input [AW-1:0] addr_b_i,
    input [DW-1:0] wdata_b_i,
    input [DW/8-1:0] wsel_b_i
);

logic [DW-1:0] mem [2**AW];

// load memory image
initial
begin
    if (INIT_MEM) begin
        $readmemh(MEMFILE, mem);
    end
end

// handle read port a
always_ff @(posedge clk_i) begin
    if (en_a_i) begin
        rdata_a_o <= mem[addr_a_i];
    end
end

// handle write for port b
always_ff @(posedge clk_i) begin
    if (en_b_i) begin
        for (int i = 0; i < DW/8; ++i) begin
            if (wsel_b_i[i]) begin
                mem[addr_b_i][i*8 +: 8] <= wdata_b_i[i*8 +: 8];
            end
        end
    end
end

endmodule: sdp_mem
