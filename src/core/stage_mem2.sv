// stage_mem2 module

module stage_mem2
import riscv_pkg::*;
(
    input clk_i,
    input rstn_i,

    // <-> CS Register File
    // write port
    output [31:0] csr_wdata_o,
    output [11:0] csr_waddr_o,
    output csr_we_o,

    // from MEM1 stage
    input [31:0] alu_result_i,
    input mem_oper_t mem_oper_i,
    input [31:0] csr_wdata_i,
    input [11:0] csr_waddr_i,
    input csr_we_i,
    input exc_t trap_i,

    // for WB stage exclusively
    input write_rd_i,
    input [4:0] rd_addr_i,

    // from LSU
    input lsu_req_done_i,
    input [31:0] lsu_rdata_i,

    // MEM/WB pipeline registers
    output logic write_rd_o,
    output logic [4:0] rd_addr_o,
    output logic [31:0] alu_result_o,
    output logic [31:0] lsu_rdata_o,
    output mem_oper_t mem_oper_o,

    output stall_o
);

logic mem2_stalled;

// if the operation is a load or a store, we need to acknowledgment to proceed with the pipeline
always_comb
begin
    mem2_stalled = '0;

    if (mem_oper_i != MEM_NOP && !lsu_req_done_i)
        mem2_stalled = 1'b1;
end

logic [31:0] rdata;
// format the read data correctly
always_comb
begin : format_rdata
    rdata = '0;

    case(mem_oper_i)
        MEM_LB:
        begin
            case (alu_result_i[1:0])
                2'b00: rdata = 32'(signed'(lsu_rdata_i[(8*1)-1 -:8]));
                2'b01: rdata = 32'(signed'(lsu_rdata_i[(8*2)-1 -:8]));
                2'b10: rdata = 32'(signed'(lsu_rdata_i[(8*3)-1 -:8]));
                2'b11: rdata = 32'(signed'(lsu_rdata_i[(8*4)-1 -:8]));
            endcase
        end
        MEM_LBU:
        begin
            case (alu_result_i[1:0])
                2'b00: rdata = 32'(lsu_rdata_i[(8*1)-1 -:8]);
                2'b01: rdata = 32'(lsu_rdata_i[(8*2)-1 -:8]);
                2'b10: rdata = 32'(lsu_rdata_i[(8*3)-1 -:8]);
                2'b11: rdata = 32'(lsu_rdata_i[(8*4)-1 -:8]);
            endcase 
        end
        MEM_LH:
        begin
            case (alu_result_i[1])
                1'b0: rdata = 32'(signed'(lsu_rdata_i[(16*1)-1 -:16]));
                1'b1: rdata = 32'(signed'(lsu_rdata_i[(16*2)-1 -:16]));
            endcase
        end

        MEM_LHU:
        begin
            case (alu_result_i[1])
                1'b0: rdata = 32'(lsu_rdata_i[(16*1)-1 -:16]);
                1'b1: rdata = 32'(lsu_rdata_i[(16*2)-1 -:16]);
            endcase
        end
        MEM_LW:
        begin
            rdata = lsu_rdata_i;
        end
    endcase
end

always_ff @(posedge clk_i)
begin
    if (!rstn_i || mem2_stalled)
    begin
        write_rd_o <= '0;
        mem_oper_o <= MEM_NOP;
    end
    else
    begin
        write_rd_o <= write_rd_i;
        mem_oper_o <= mem_oper_i;
        rd_addr_o <= rd_addr_i;
        alu_result_o <= alu_result_i;
        lsu_rdata_o <= rdata;
    end
end

wire no_csr_commit = mem2_stalled | trap_i != NO_TRAP; // in this don't touch the csrs
// assign outputs
assign csr_we_o = no_csr_commit ? '0 : csr_we_i;
assign csr_waddr_o = csr_waddr_i;
assign csr_wdata_o = csr_wdata_i;

assign stall_o = mem2_stalled;

endmodule: stage_mem2