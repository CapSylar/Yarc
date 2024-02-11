// stage_mem1 module

module stage_mem1
import riscv_pkg::*;
(
    input clk_i,
    input rstn_i,

    // Load Store Unit
    output logic lsu_req_o,
    // read port
    output logic [31:0] lsu_addr_o,
    output logic lsu_we_o,
    input [31:0] lsu_rdata_i,
    // write port
    output logic [3:0] lsu_wsel_byte_o,
    output logic [31:0] lsu_wdata_o,
    input lsu_req_stall_i,

    // from ID/EX combinational ins
    input exc_t ex_trap_i,
    input mem_oper_t id_ex_mem_oper_i,

    // from EX/MEM1
    input [31:0] alu_result_i,
    input [31:0] alu_oper2_i,
    input mem_oper_t mem_oper_i,
    input [31:0] csr_wdata_i,
    input [11:0] csr_waddr_i,
    input instr_valid_i,
    input is_csr_i,
    input csr_we_i,
    input exc_t trap_i,

    // for WB stage exclusively
    input write_rd_i,
    input [4:0] rd_addr_i,

    // MEM1/MEM2 pipeline registers
    output logic instr_valid_o,
    output logic is_csr_o,
    output logic csr_we_o,
    output logic [11:0] csr_waddr_o,
    output logic [31:0] csr_wdata_o,
    output logic write_rd_o,
    output logic [4:0] rd_addr_o,
    output logic [31:0] alu_result_o,
    output mem_oper_t mem_oper_o,
    
    input ex_mem1_flush_i,
    input stall_i,
    input flush_i,

    output exc_t trap_o
);

// TODO: handle unaligned loads and stores, signal an error in this case
wire [31:0] addr = lsu_addr_o;
wire [31:0] to_write = alu_oper2_i;
logic [3:0] wsel_byte;
logic [31:0] wdata;
logic is_write;

// format the write data
always_comb
begin
    wsel_byte = '0;
    wdata = '0;
    is_write = '0;

    case(mem_oper_i)
        MEM_SB:
        begin
            is_write = 1'b1;
            wsel_byte = 4'b0001 << addr[1:0];
            wdata = to_write << (addr[1:0] * 8);
        end

        MEM_SH:
        begin
            is_write = 1'b1;
            wsel_byte = 4'b0011 << (addr[1] * 2);
            wdata = to_write << (addr[1] * 16);
        end

        MEM_SW:
        begin
            is_write = 1'b1;
            wsel_byte = 4'b1111;
            wdata = to_write;
        end

        default:
        begin end
    endcase
end

mem_oper_t mem_oper_q;
logic [31:0] lsu_addr_q;

// memory request to be issued in the current must be known 1 cycle in advance
// so we must determine if a memory instruction currently in EX will be in MEM in the next cycle

// when not to start a memory request
wire cannot_issue_req = (ex_trap_i != NO_TRAP) || (trap_i != NO_TRAP) || ex_mem1_flush_i || flush_i || stall_i;

always_comb
begin
    lsu_req_o = '0;

    if (id_ex_mem_oper_i != MEM_NOP && !cannot_issue_req)
        lsu_req_o = 1'b1;
end

// lsu outputs
assign lsu_addr_o = alu_result_i;
assign lsu_wdata_o = wdata;
assign lsu_wsel_byte_o = wsel_byte;
assign lsu_we_o = is_write;

// pipeline registers
always_ff @(posedge clk_i)
begin
    if (!rstn_i || flush_i)
    begin
        write_rd_o <= '0;
        is_csr_o <= '0;
        csr_we_o <= '0;
        mem_oper_o <= MEM_NOP;
        trap_o <= NO_TRAP;
        instr_valid_o <= '0;
    end
    else if (!stall_i)
    begin
        write_rd_o <= write_rd_i;
        rd_addr_o <= rd_addr_i;
        alu_result_o <= alu_result_i;
        mem_oper_o <= mem_oper_i;
        is_csr_o <= is_csr_i;
        csr_we_o <= csr_we_i;
        csr_waddr_o <= csr_waddr_i;
        csr_wdata_o <= csr_wdata_i;
        trap_o <= trap_i;
        instr_valid_o <= instr_valid_i;
    end
end

endmodule: stage_mem1