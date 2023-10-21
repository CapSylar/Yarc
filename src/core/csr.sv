// csr register

module csr #(
    parameter int Width = 32,
    parameter bit [Width-1:0] ResetValue = '0
)
(
    input clk_i,
    input rstn_i,

    output [Width-1:0] rd_data_o,
    input wr_en_i,
    input [Width-1:0] wr_data_i
);

logic [Width-1:0] data_q;
assign rd_data_o = data_q; // read data

// write data
always @(posedge clk_i, negedge rstn_i)
begin
    if (!rstn_i)
        data_q <= ResetValue;
    else if (wr_en_i)
        data_q <= wr_data_i;
end

endmodule: csr