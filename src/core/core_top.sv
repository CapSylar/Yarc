/*
    2023 with love
 __     __               _____                 _______          
 \ \   / /              / ____|               |__   __|         
  \ \_/ /_ _ _ __ ___  | |     ___  _ __ ___     | | ___  _ __  
   \   / _` | '__/ __| | |    / _ \| '__/ _ \    | |/ _ \| '_ \ 
    | | (_| | | | (__  | |___| (_) | | |  __/    | | (_) | |_) |
    |_|\__,_|_|  \___|  \_____\___/|_|  \___|    |_|\___/| .__/ 
                                                         | |    
                                                         |_|    
*/

`include "defines.svh"

module core_top
(
    input clk_i,
    input rstn_i,

    // Core <-> Imem interface
    output imem_read_o,
    output [31:0] imem_raddr_o,
    input [31:0] imem_rdata_i
);

// Signal definitions

// Driven by the Fetch stage
logic valid;
logic [31:0] if_id_instr;
logic [31:0] if_id_pc;

// Driven by the Register file
logic [31:0] rs1_data, rs2_data;

// Driven by the Decode stage
logic [4:0] rs1_addr, rs2_addr;
logic [31:0] id_ex_pc, id_ex_rs1_data, id_ex_rs2_data, id_ex_imm;
alu_oper1_src_t id_ex_alu_oper1_src;
alu_oper2_src_t id_ex_alu_oper2_src;
bnj_oper_t id_ex_bnj_oper;
alu_oper_t id_ex_alu_oper;
mem_oper_t id_ex_mem_oper;
logic id_ex_wb_use_mem;
logic id_ex_write_rd;
logic [4:0] id_ex_rd_addr;

// Driven by the Ex stage
logic [31:0] ex_mem_alu_result;
logic [31:0] ex_mem_alu_oper2;
mem_oper_t ex_mem_mem_oper;
logic ex_mem_wb_use_mem;
logic ex_mem_write_rd;
logic [4:0] ex_mem_rd_addr;
logic [31:0] new_pc;
logic load_pc;

// Driven by the Mem stage
logic mem_wb_use_mem;
logic mem_wb_write_rd;
logic [4:0] mem_wb_rd_addr;
logic [31:0] mem_wb_alu_result;
logic [31:0] mem_wb_dmem_rdata;

// Driven by the Wb stage

// Misc.
logic if_id_stall;

// Fetch Stage

simple_fetch simple_fetch_i
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),

    .valid_o(valid),
    .instr_o(if_id_instr),
    .pc_o(if_id_pc),

    .stall_i(if_id_stall),

    .pc_i(new_pc),
    .new_pc_i(load_pc),

    // Imem interface
    .read_o(imem_read_o),
    .raddr_o(imem_raddr_o),
    .rdata_i(imem_rdata_i)
);

// Register file

reg_file reg_file_i
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),

    // read port
    .rs1_addr_i(rs1_addr),
    .rs2_addr_i(rs2_addr),

    .rs1_data_o(rs1_data),
    .rs2_data_o(rs2_data),

    // write port
    .write_i(),
    .rd_addr_i(),
    .rd_data_i()
);

// Decode Stage

decode decode_i
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),

    // register file <-> decode module
    // read port
    .rs1_addr_o(rs1_addr),
    .rs2_addr_o(rs2_addr),
    .rs1_data_i(rs1_data),
    .rs2_data_i(rs2_data),

    // from IF stage
    .instr_i(if_id_instr), // instruction
    .pc_i(if_id_pc), // pc of the instruction

    // ID/EX pipeline registers ************************************************

    // feedback into the pipeline register
    .stall_i(), // keep the same content in the registers
    .flush_i(), // zero the register contents

    // for direct use by the EX stage
    .pc_o(id_ex_pc), // forwarded from IF/ID
    .rs1_data_o(id_ex_rs1_data),
    .rs2_data_o(id_ex_rs2_data),
    .imm_o(id_ex_imm),
    .alu_oper1_src_o(id_ex_alu_oper1_src),
    .alu_oper2_src_o(id_ex_alu_oper2_src),
    .bnj_oper_o(id_ex_bnj_oper),
    .alu_oper_o(id_ex_alu_oper),

    // for the MEM stage
    .mem_oper_o(id_ex_mem_oper),

    // for the WB stage
    .wb_use_mem_o(id_ex_wb_use_mem),
    .write_rd_o(id_ex_write_rd),
    .rd_addr_o(id_ex_rd_addr)
);

// Execute Stage

execute execute_i
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),

    // from ID/EX
    .pc_i(id_ex_pc),
    .rs1_data_i(id_ex_rs1_data),
    .rs2_data_i(id_ex_rs2_data),
    .imm_i(id_ex_imm),
    .alu_oper1_src_i(id_ex_alu_oper1_src),
    .alu_oper2_src_i(id_ex_alu_oper2_src),
    .alu_oper_i(id_ex_alu_oper),
    .bnj_oper_i(id_ex_bnj_oper),

    // forward to MEM stage
    .mem_oper_i(id_ex_mem_oper),

    // forward to the WB stage
    .wb_use_mem_i(id_ex_wb_use_mem),
    .write_rd_i(id_ex_write_rd),
    .rd_addr_i(id_ex_rd_addr),

    // EX/MEM pipeline registers
    
    // feedback into the pipeline register
    .stall_i(), // keep the same content in the registers
    .flush_i(), // zero the register contents

    .alu_result_o(ex_mem_alu_result),
    .alu_oper2_o(ex_mem_alu_oper2),
    .mem_oper_o(ex_mem_mem_oper),
    // for WB stage exclusively
    .wb_use_mem_o(ex_mem_wb_use_mem),
    .write_rd_o(ex_mem_write_rd),
    .rd_addr_o(ex_mem_rd_addr),

    // branches and jumps
    .load_pc_o(load_pc),
    .new_pc_o(new_pc)
);

// Memory Stage

mem_rw mem_rw_i
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),

    // from EX/MEM
    .alu_result_i(ex_mem_alu_result),
    .alu_oper2_i(ex_mem_alu_oper2),
    .mem_oper_i(ex_mem_mem_oper),
    // for WB stage exclusively
    .wb_use_mem_i(ex_mem_wb_use_mem),
    .write_rd_i(ex_mem_write_rd),
    .rd_addr_i(ex_mem_rd_addr),

    // MEM/WB pipeline registers
    .wb_use_mem_o(mem_wb_use_mem),
    .write_rd_o(mem_wb_write_rd),
    .rd_addr_o(mem_wb_rd_addr),
    .alu_result_o(mem_wb_alu_result),
    .dmem_rdata_o(mem_wb_dmem_rdata)
);

endmodule : core_top