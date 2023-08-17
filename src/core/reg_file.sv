// register file
// reads are asynchronous since they will pipelined anyway

module reg_file
#(parameter ADDR_WIDTH = 5, parameter REG_SIZE = 32)
(
    input clk_i,
    input rstn_i,

    // read port
    input [ADDR_WIDTH-1:0] rs1_addr_i,
    input [ADDR_WIDTH-1:0] rs2_addr_i,

    output [REG_SIZE-1:0] rs1_data_o,
    output [REG_SIZE-1:0] rs2_data_o,

    // write port
    input write_i,
    input [ADDR_WIDTH-1:0] waddr_i,
    input [REG_SIZE-1:0] wdata_i
);

// register file
logic [REG_SIZE-1:0] regf [2**ADDR_WIDTH];

// asynchronous read
assign rs1_data_o = regf[rs1_addr_i];
assign rs2_data_o = regf[rs2_addr_i];

// reset and write
always_ff@(posedge clk_i, negedge rstn_i)
begin
    if (!rstn_i)
    begin
        for (int i = 0; i < 2**ADDR_WIDTH; ++i)
            regf[i] <= 0;
    end
    else if (write_i)
        regf[waddr_i] <= wdata_i;
end

endmodule : reg_file