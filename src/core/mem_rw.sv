// mem_rw module

module mem_rw
(
    input clk_i,
    input rstn_i,

    // from EX/MEM
    input [31:0] alu_result_i,
    input [31:0] alu_oper2_i,
    input mem_oper_t mem_oper_i,
    // for WB stage exclusively
    input wb_use_mem_i,
    input write_rd_i,
    input [4:0] rd_addr_i,

    // MEM/WB pipeline registers
    output logic wb_use_mem_o,
    output logic write_rd_o,
    output logic [4:0] rd_addr_o,
    output logic [31:0] alu_result_o,
    output logic [31:0] dmem_rdata_o
);

// TODO: implement

wire [31:0] dmem_rdata = 0;

// pipeline registers and outputs
always_ff @(posedge clk_i, negedge rstn_i)
begin
    if (!rstn_i)
    begin
        wb_use_mem_o <= 0;
        write_rd_o <= 0;
        rd_addr_o <= 0;
        alu_result_o <= 0;
        dmem_rdata_o <= 0;
    end
    else
    begin
        wb_use_mem_o <= wb_use_mem_i;
        write_rd_o <= write_rd_i;
        rd_addr_o <= rd_addr_i;
        alu_result_o <= alu_result_i;
        dmem_rdata_o <= dmem_rdata;
    end
end

endmodule: mem_rw