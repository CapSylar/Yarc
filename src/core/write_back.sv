// write_back module

module write_back
import riscv_pkg::*;
(
    input clk_i,
    input rstn_i,
 
    // from MEM/WB
    input mem_oper_t mem_oper_i,
    input write_rd_i,
    input [4:0] rd_addr_i,
    input [31:0] alu_result_i,
    input [31:0] lsu_rdata_i,

    // WB -> Register file
    output logic regf_write_o,
    output logic [4:0] regf_waddr_o,
    output logic [31:0] regf_wdata_o
);

wire is_load = !mem_oper_i[3];

// assign outputs
assign regf_write_o = write_rd_i;
assign regf_waddr_o = rd_addr_i;
assign regf_wdata_o = is_load ? lsu_rdata_i : alu_result_i;

endmodule: write_back