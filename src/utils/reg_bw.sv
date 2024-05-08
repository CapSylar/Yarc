// register with byte-wide byte write
// wsel_i[0] -> reg[7:0]
// wsel_i[1] -> reg[15:8]
// wsel_i[2] -> reg[16:20] // if bits 21 and up are not implemented

module reg_bw #(
    parameter int WIDTH = 32,
    parameter bit [WIDTH-1:0] RESET_VALUE = '0,
    
    parameter WSEL = $rtoi($ceil($itor(WIDTH)/8))
)
(
    input clk_i,
    input rstn_i,

    output [WIDTH-1:0] rdata_o,
    input we_i,
    input [WSEL-1:0] wsel_i,
    input [WIDTH-1:0] wdata_i
);

logic [WIDTH-1:0] data_q, data_d;
assign rdata_o = data_q;

`define SELECT_SLICE i*8 +: (i*8 + 8 < WIDTH) ? 8 : WIDTH - (i*8) // ugly ik

generate
    for (genvar i = 0; i < WSEL; ++i) begin
        assign data_d = (wsel_i[i] & we_i) ? wdata_i[`SELECT_SLICE]: data_q[`SELECT_SLICE];
    end
endgenerate

always_ff @(posedge clk_i) begin
    if (!rstn_i) begin
        data_q <= '0;
    end else begin
        data_q <= data_d;
    end
end

endmodule: reg_bw
