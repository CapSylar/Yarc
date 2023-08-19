// mem_rw module

module mem_rw
(
    input clk_i,
    input rstn_i,

    // Mem-rw <-> Data Memory
    // read port
    output [31:0] rw_addr_o,
    input [31:0] rdata_i,
    // write port
    output [3:0] sel_byte_o,
    output [31:0] wdata_o,

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

// TODO: handle unaligned loads and stores, signal an error in this case

wire [31:0] addr = rw_addr_o;
wire [31:0] to_write = alu_oper2_i;
logic [31:0] rdata;
logic [3:0] sel_byte;
logic [31:0] wdata;

// handle loads and stores
always_comb
begin
    rdata = 0;
    sel_byte = 0;
    wdata = 0;

    case(mem_oper_i)
        // LOADS
        MEM_LB:
        begin
            // for (int i = 0 ; i < 4; ++i) Good, but ugly, keep it
            //     if (i[1:0] == addr[1:0])
            //         rdata = 32'(signed'(rdata_i[8*(i+1)-1 -:8]));
            case (addr[1:0])
                2'b00: rdata = 32'(signed'(rdata_i[(8*1)-1 -:8]));
                2'b01: rdata = 32'(signed'(rdata_i[(8*2)-1 -:8]));
                2'b10: rdata = 32'(signed'(rdata_i[(8*3)-1 -:8]));
                2'b11: rdata = 32'(signed'(rdata_i[(8*4)-1 -:8]));
            endcase
        end
        MEM_LBU:
        begin
            case (addr[1:0])
                2'b00: rdata = 32'(rdata_i[(8*1)-1 -:8]);
                2'b01: rdata = 32'(rdata_i[(8*2)-1 -:8]);
                2'b10: rdata = 32'(rdata_i[(8*3)-1 -:8]);
                2'b11: rdata = 32'(rdata_i[(8*4)-1 -:8]);
            endcase 
        end
        MEM_LH:
        begin
            case (addr[1])
                1'b0: rdata = 32'(signed'(rdata_i[(16*1)-1 -:16]));
                1'b1: rdata = 32'(signed'(rdata_i[(16*2)-1 -:16]));
            endcase
        end

        MEM_LHU:
        begin
            case (addr[1])
                1'b0: rdata = 32'(rdata_i[(16*1)-1 -:16]);
                1'b1: rdata = 32'(rdata_i[(16*2)-1 -:16]);
            endcase
        end
        MEM_LW:
        begin
            rdata = rdata_i;
        end

        // STORES
        MEM_SB:
        begin
            sel_byte = 4'b0001 << addr[1:0];
            wdata = to_write << (addr[1:0] * 8);
        end

        MEM_SH:
        begin
            sel_byte = 4'b0011 << (addr[1] * 2);
            wdata = to_write << (addr[1] * 16);
        end

        MEM_SW:
        begin
            sel_byte = 4'b1111;
            wdata = to_write;
        end

        default:
        begin end
    endcase
end

// pipeline registers and outputs

assign rw_addr_o = (mem_oper_i != MEM_NOP) ? alu_result_i : 0;
assign wdata_o = wdata;
assign sel_byte_o = sel_byte;

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
        dmem_rdata_o <= rdata;
    end
end

endmodule: mem_rw