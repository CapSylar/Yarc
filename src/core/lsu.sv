// lsu module

module lsu
import riscv_pkg::*;
(
    input clk_i,
    input rstn_i,

    // Load Store Unit <-> Data Memory
    output lsu_en_o,
    // read port
    output [31:0] lsu_addr_o,
    output lsu_read_o,
    input [31:0] lsu_rdata_i,
    // write port
    output [3:0] lsu_wsel_byte_o,
    output [31:0] lsu_wdata_o,

    // Load Store Unit <-> CS Register File
    // write port
    output [31:0] csr_wdata_o,
    output [11:0] csr_waddr_o,
    output csr_we_o,

    output exc_t trap_o,

    // from EX/MEM
    input [31:0] alu_result_i,
    input [31:0] alu_oper2_i,
    input mem_oper_t mem_oper_i,
    input [31:0] csr_wdata_i,
    input [11:0] csr_waddr_i,
    input csr_we_i,
    input exc_t trap_i,

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

assign csr_we_o = csr_we_i;
assign csr_waddr_o = csr_waddr_i;
assign csr_wdata_o = csr_wdata_i;
assign trap_o = trap_i; // rerouted here just for cleanliness

// TODO: handle unaligned loads and stores, signal an error in this case
wire [31:0] addr = lsu_addr_o;
wire [31:0] to_write = alu_oper2_i;
logic [31:0] rdata;
logic [3:0] wsel_byte;
logic [31:0] wdata;
logic read;

// handle loads and stores
always_comb
begin
    // rdata = 0;
    wsel_byte = 0;
    wdata = 0;
    read = 0;

    case(mem_oper_i)
        // LOADS
        MEM_LB:
        begin
            read = 1;
            // for (int i = 0 ; i < 4; ++i) Good, but ugly, keep it
            //     if (i[1:0] == addr[1:0])
            //         rdata = 32'(signed'(lsu_rdata_i[8*(i+1)-1 -:8]));
            // case (addr[1:0])
            //     2'b00: rdata = 32'(signed'(lsu_rdata_i[(8*1)-1 -:8]));
            //     2'b01: rdata = 32'(signed'(lsu_rdata_i[(8*2)-1 -:8]));
            //     2'b10: rdata = 32'(signed'(lsu_rdata_i[(8*3)-1 -:8]));
            //     2'b11: rdata = 32'(signed'(lsu_rdata_i[(8*4)-1 -:8]));
            // endcase
        end
        MEM_LBU:
        begin
            read = 1;
            // case (addr[1:0])
            //     2'b00: rdata = 32'(lsu_rdata_i[(8*1)-1 -:8]);
            //     2'b01: rdata = 32'(lsu_rdata_i[(8*2)-1 -:8]);
            //     2'b10: rdata = 32'(lsu_rdata_i[(8*3)-1 -:8]);
            //     2'b11: rdata = 32'(lsu_rdata_i[(8*4)-1 -:8]);
            // endcase 
        end
        MEM_LH:
        begin
            read = 1;
            // case (addr[1])
            //     1'b0: rdata = 32'(signed'(lsu_rdata_i[(16*1)-1 -:16]));
            //     1'b1: rdata = 32'(signed'(lsu_rdata_i[(16*2)-1 -:16]));
            // endcase
        end

        MEM_LHU:
        begin
            read = 1;
            // case (addr[1])
            //     1'b0: rdata = 32'(lsu_rdata_i[(16*1)-1 -:16]);
            //     1'b1: rdata = 32'(lsu_rdata_i[(16*2)-1 -:16]);
            // endcase
        end
        MEM_LW:
        begin
            read = 1;
            // rdata = lsu_rdata_i;
        end

        // STORES
        MEM_SB:
        begin
            wsel_byte = 4'b0001 << addr[1:0];
            wdata = to_write << (addr[1:0] * 8);
        end

        MEM_SH:
        begin
            wsel_byte = 4'b0011 << (addr[1] * 2);
            wdata = to_write << (addr[1] * 16);
        end

        MEM_SW:
        begin
            wsel_byte = 4'b1111;
            wdata = to_write;
        end

        default:
        begin end
    endcase
end

mem_oper_t mem_oper_q;
logic [31:0] lsu_addr_q;

// format the read data correctly
always_comb
begin : format_rdata
    rdata = '0;

    case(mem_oper_q)
        MEM_LB:
        begin
            case (lsu_addr_q[1:0])
                2'b00: rdata = 32'(signed'(lsu_rdata_i[(8*1)-1 -:8]));
                2'b01: rdata = 32'(signed'(lsu_rdata_i[(8*2)-1 -:8]));
                2'b10: rdata = 32'(signed'(lsu_rdata_i[(8*3)-1 -:8]));
                2'b11: rdata = 32'(signed'(lsu_rdata_i[(8*4)-1 -:8]));
            endcase
        end
        MEM_LBU:
        begin
            case (lsu_addr_q[1:0])
                2'b00: rdata = 32'(lsu_rdata_i[(8*1)-1 -:8]);
                2'b01: rdata = 32'(lsu_rdata_i[(8*2)-1 -:8]);
                2'b10: rdata = 32'(lsu_rdata_i[(8*3)-1 -:8]);
                2'b11: rdata = 32'(lsu_rdata_i[(8*4)-1 -:8]);
            endcase 
        end
        MEM_LH:
        begin
            case (lsu_addr_q[1])
                1'b0: rdata = 32'(signed'(lsu_rdata_i[(16*1)-1 -:16]));
                1'b1: rdata = 32'(signed'(lsu_rdata_i[(16*2)-1 -:16]));
            endcase
        end

        MEM_LHU:
        begin
            case (lsu_addr_q[1])
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

// pipeline registers and outputs

assign lsu_en_o = (mem_oper_i != MEM_NOP);
assign lsu_addr_o = lsu_en_o ? alu_result_i : 0;
assign lsu_wdata_o = wdata;
assign lsu_wsel_byte_o = wsel_byte;
assign lsu_read_o = read;

always_ff @(posedge clk_i, negedge rstn_i)
begin
    if (!rstn_i)
    begin
        wb_use_mem_o <= 0;
        write_rd_o <= 0;
        rd_addr_o <= 0;
        alu_result_o <= 0;
        // dmem_rdata_o <= 0;
    end
    else
    begin
        wb_use_mem_o <= wb_use_mem_i;
        write_rd_o <= write_rd_i;
        rd_addr_o <= rd_addr_i;
        alu_result_o <= alu_result_i;
        // dmem_rdata_o <= rdata;
    end
end

assign dmem_rdata_o = rdata;

// pipe 
always_ff @(posedge clk_i, negedge rstn_i)
begin
    if (!rstn_i)
    begin
        mem_oper_q <= MEM_NOP;
        lsu_addr_q <= '0;
    end
    else
    begin
        mem_oper_q <= mem_oper_i;
        lsu_addr_q <= lsu_addr_o;
    end
end

endmodule: lsu