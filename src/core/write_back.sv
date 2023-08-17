// write_back module

module write_back
(
    input clk_i,
    input rstn_i,

    // from MEM/WB
    input use_mem_i,
    input write_rd_i,
    input [4:0] rd_addr_i,
    input [31:0] alu_result_i,
    input [31:0] dmem_rdata_i,

    // WB -> Register file
    output logic regf_write_o,
    output logic [4:0] regf_waddr_o,
    output logic [31:0] regf_wdata_o
);

always_comb
begin
    regf_write_o = write_rd_i;
    regf_waddr_o = rd_addr_i;
    regf_wdata_o = use_mem_i ? dmem_rdata_i : alu_result_i;
end

endmodule: write_back