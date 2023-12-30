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

module core_top
import riscv_pkg::*;
import csr_pkg::*;
(
    input clk_i,
    input rstn_i,

    // Core WB LSU interface
    wishbone_if.MASTER lsu_wb_if,
    // Core WB Instruction fetch interface
    wishbone_if.MASTER instr_fetch_wb_if,

    // interrupts
    input irq_timer_i,
    input irq_external_i
);

// Signal definitions

// Driven by the Fetch stage
logic if_id_instr_valid;
logic [31:0] if_id_instr;
logic [31:0] if_id_pc;

// Driven by the Register file
logic [31:0] rs1_data, rs2_data;

// Driven by the CS Register file
logic [31:0] csr_rdata;
logic [31:0] csr_mepc;
priv_lvl_e current_plvl;
mtvec_t csr_mtvec;
mstatus_t csr_mstatus;
irqs_t irq_pending;

// Driven by the Decode stage
logic [4:0] rs1_addr, rs2_addr;
logic csr_re;
logic [11:0] csr_raddr;
logic [31:0] id_ex_pc, id_ex_rs1_data, id_ex_rs2_data, id_ex_imm;
alu_oper1_src_t id_ex_alu_oper1_src;
alu_oper2_src_t id_ex_alu_oper2_src;
bnj_oper_t id_ex_bnj_oper;
logic id_ex_is_csr;
logic id_ex_instr_valid;
alu_oper_t id_ex_alu_oper;
mem_oper_t id_ex_mem_oper;
logic [11:0] id_ex_csr_waddr;
logic id_ex_csr_we;
logic id_ex_write_rd;
logic [4:0] id_ex_rd_addr;
logic [4:0] id_ex_rs1_addr;
logic [4:0] id_ex_rs2_addr;
logic id_is_csr;
exc_t id_ex_trap;
logic [31:0] id_ex_csr_rdata;

// Driven by the Ex stage
logic [31:0] ex_mem1_alu_result;
logic [31:0] ex_mem1_alu_oper2;
mem_oper_t ex_mem1_mem_oper;
logic [31:0] ex_mem1_csr_wdata;
logic [11:0] ex_mem1_csr_waddr;
logic ex_mem1_csr_we;
logic ex_mem1_is_csr;
logic ex_mem1_write_rd;
logic [4:0] ex_mem1_rd_addr;
logic [31:0] branch_target;
logic ex_new_pc_en;
exc_t ex_mem1_trap;
logic [31:0] ex_mem1_pc;
logic ex_mem1_instr_valid;

// Driven by the Mem1 stage
logic lsu_req;
logic lsu_we;
logic [31:0] lsu_addr;
logic [31:0] lsu_rdata;
logic [3:0] lsu_wsel_byte;
logic [31:0] lsu_wdata;
logic mem1_mem2_write_rd;
logic [4:0] mem1_mem2_rd_addr;
mem_oper_t mem1_mem2_mem_oper;
logic [31:0] mem1_mem2_alu_result;
logic [31:0] mem_wb_dmem_rdata;
exc_t mem1_mem2_trap;
logic mem1_mem2_is_csr;
logic mem1_mem2_csr_we;
logic [31:0] mem1_mem2_csr_wdata;
logic [11:0] mem1_mem2_csr_waddr;

// Driven by the Mem2 stage
logic mem2_wb_write_rd;
logic [4:0] mem2_wb_rd_addr;
logic [31:0] mem2_wb_alu_result;
logic [31:0] mem2_wb_lsu_rdata;
logic mem2_stall_needed;
mem_oper_t mem2_wb_mem_oper;
logic [31:0] csr_wdata;
logic [11:0] csr_waddr;
logic csr_we;
exc_t mem2_trap;

// Driven by the WB Data Interface
logic lsu_req_stall;

// Driven by the Wb stage
logic regf_write;
logic [4:0] regf_waddr;
logic [31:0] regf_wdata;

// Driven by the Core Controller
logic forward_ex_mem1_rs1;
logic forward_ex_mem1_rs2;
logic forward_mem1_mem2_rs1;
logic forward_mem1_mem2_rs2;
logic forward_mem2_wb_rs1;
logic forward_mem2_wb_rs2;
logic [31:0] forward_ex_mem1_data;
logic [31:0] forward_mem1_mem2_data;
logic [31:0] forward_mem2_wb_data;
logic if_id_stall;
logic id_id_flush;
logic id_ex_flush;
logic id_ex_stall;
logic ex_mem1_flush;
logic ex_mem1_stall;
logic mem1_mem2_flush;
logic mem1_mem2_stall;
logic mem2_wb_stall;
logic mem2_wb_flush;
logic new_pc_en;
pc_sel_t pc_sel;
logic is_mret;
mcause_t mcause;
logic is_trap;
logic [31:0] exc_pc;

// Fetch Stage
simple_fetch simple_fetch_i
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),

    // IMEM Wishbone interface
    .wb_if(instr_fetch_wb_if),

    .valid_o(if_id_instr_valid),
    .instr_o(if_id_instr),
    .pc_o(if_id_pc),

    .stall_i(if_id_stall),
    .flush_i(if_id_flush),

    // target addresses
    .branch_target_i(branch_target),
    .csr_mepc_i(csr_mepc),
    .mcause_i(mcause),
    .mtvec_i(csr_mtvec),

    .new_pc_en_i(new_pc_en),
    .pc_sel_i(pc_sel)
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
    .write_i(regf_write),
    .waddr_i(regf_waddr),
    .wdata_i(regf_wdata)
);

// CS Register file
cs_registers cs_registers_i
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),

    // read port
    .csr_re_i(csr_re),
    .csr_raddr_i(csr_raddr),
    .csr_rdata_o(csr_rdata),

    // write port
    .csr_we_i(csr_we),
    .csr_waddr_i(csr_waddr),
    .csr_wdata_i(csr_wdata),

    // output some cs registers
    .csr_mepc_o(csr_mepc),
    .csr_mtvec_o(csr_mtvec),
    .csr_mstatus_o(csr_mstatus),
    .current_plvl_o(current_plvl),

    .irq_pending_o(irq_pending),

    // mret, traps...
    .csr_mret_i(is_mret),
    .is_trap_i(is_trap),
    .mcause_i(mcause),
    .exc_pc_i(exc_pc),
    // interrupts
    .irq_software_i('0),
    .irq_timer_i(irq_timer_i),
    .irq_external_i(irq_external_i),

    // used by the performance counters
    .instr_ret_i('0)
);

// Decode Stage
decode decode_i
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .instr_valid_i(if_id_instr_valid),

    // from csr unit
    .current_plvl_i(current_plvl),

    // register file <-> decode module
    // read port
    .regf_rs1_addr_o(rs1_addr),
    .regf_rs2_addr_o(rs2_addr),
    .rs1_data_i(rs1_data),
    .rs2_data_i(rs2_data),

    // csr unit <-> decode module
    // read port
    .csr_re_o(csr_re),
    .csr_raddr_o(csr_raddr),
    .csr_rdata_i(csr_rdata),

    // from IF stage
    .instr_i(if_id_instr), // instruction
    .pc_i(if_id_pc), // pc of the instruction

    // ID/EX pipeline registers ************************************************

    // feedback into the pipeline register
    .stall_i(id_ex_stall), // keep the same content in the registers
    .flush_i(id_ex_flush), // zero the register contents

    // for direct use by the EX stage
    .pc_o(id_ex_pc), // forwarded from IF/ID
    .rs1_data_o(id_ex_rs1_data),
    .rs2_data_o(id_ex_rs2_data),
    .imm_o(id_ex_imm),
    .csr_rdata_o(id_ex_csr_rdata),
    .alu_oper1_src_o(id_ex_alu_oper1_src),
    .alu_oper2_src_o(id_ex_alu_oper2_src),
    .bnj_oper_o(id_ex_bnj_oper),
    .alu_oper_o(id_ex_alu_oper),
    .is_csr_o(id_ex_is_csr),
    .instr_valid_o(id_ex_instr_valid),

    // for the MEM stage
    .mem_oper_o(id_ex_mem_oper),
    .csr_waddr_o(id_ex_csr_waddr),
    .csr_we_o(id_ex_csr_we),

    // for the WB stage
    .write_rd_o(id_ex_write_rd),
    .rd_addr_o(id_ex_rd_addr),

    // used by the hazard/forwarding logic
    .rs1_addr_o(id_ex_rs1_addr),
    .rs2_addr_o(id_ex_rs2_addr),
    .id_is_csr_o(id_is_csr),

    .trap_o(id_ex_trap)
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
    .csr_rdata_i(id_ex_csr_rdata),
    .alu_oper1_src_i(id_ex_alu_oper1_src),
    .alu_oper2_src_i(id_ex_alu_oper2_src),
    .alu_oper_i(id_ex_alu_oper),
    .bnj_oper_i(id_ex_bnj_oper),
    .is_csr_i(id_ex_is_csr),
    .instr_valid_i(id_ex_instr_valid),
    .mem_oper_i(id_ex_mem_oper),
    .csr_waddr_i(id_ex_csr_waddr),
    .csr_we_i(id_ex_csr_we),
    .trap_i(id_ex_trap),

    // forward to the WB stage
    .write_rd_i(id_ex_write_rd),
    .rd_addr_i(id_ex_rd_addr),

    // EX/MEM pipeline registers
    
    // feedback into the pipeline register
    .stall_i(ex_mem1_stall), // keep the same content in the registers
    .flush_i(ex_mem1_flush), // zero the register contents

    .alu_result_o(ex_mem1_alu_result),
    .alu_oper2_o(ex_mem1_alu_oper2),
    .mem_oper_o(ex_mem1_mem_oper),
    .csr_wdata_o(ex_mem1_csr_wdata),
    .csr_waddr_o(ex_mem1_csr_waddr),
    .csr_we_o(ex_mem1_csr_we),
    .is_csr_o(ex_mem1_is_csr),
    .trap_o(ex_mem1_trap),
    .pc_o(ex_mem1_pc),
    .instr_valid_o(ex_mem1_instr_valid),

    // for WB stage exclusively
    .write_rd_o(ex_mem1_write_rd),
    .rd_addr_o(ex_mem1_rd_addr),

    // branches and jumps
    .new_pc_en_o(ex_new_pc_en),
    .branch_target_o(branch_target),

    // from forwarding logic
    .forward_ex_mem1_rs1_i(forward_ex_mem1_rs1),
    .forward_ex_mem1_rs2_i(forward_ex_mem1_rs2),
    .forward_ex_mem1_data_i(forward_ex_mem1_data),

    .forward_mem1_mem2_rs1_i(forward_mem1_mem2_rs1),
    .forward_mem1_mem2_rs2_i(forward_mem1_mem2_rs2),
    .forward_mem1_mem2_data_i(forward_mem1_mem2_data),

    .forward_mem2_wb_rs1_i(forward_mem2_wb_rs1),
    .forward_mem2_wb_rs2_i(forward_mem2_wb_rs2),
    .forward_mem2_wb_data_i(forward_mem2_wb_data)
);

// MEM1 Stage (Setting up Memory request
stage_mem1 stage_mem1_i
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),

    // MEM1 <-> LSU
    // read port
    .lsu_req_o(lsu_req),
    .lsu_addr_o(lsu_addr),
    .lsu_we_o(lsu_we),
    .lsu_rdata_i(lsu_rdata),
    // write port
    .lsu_wsel_byte_o(lsu_wsel_byte),
    .lsu_wdata_o(lsu_wdata),
    .lsu_req_stall_i(lsu_req_stall),

    // from ID/EX combinational ins
    .ex_trap_i(id_ex_trap),
    .id_ex_mem_oper_i(id_ex_mem_oper),

    // from EX/MEM
    .alu_result_i(ex_mem1_alu_result),
    .alu_oper2_i(ex_mem1_alu_oper2),
    .mem_oper_i(ex_mem1_mem_oper),

    .csr_wdata_i(ex_mem1_csr_wdata),
    .csr_waddr_i(ex_mem1_csr_waddr),
    .is_csr_i(ex_mem1_is_csr),
    .csr_we_i(ex_mem1_csr_we),

    .trap_i(ex_mem1_trap),

    // for WB stage exclusively
    .write_rd_i(ex_mem1_write_rd),
    .rd_addr_i(ex_mem1_rd_addr),

    // MEM1/MEM2 pipeline registers
    .is_csr_o(mem1_mem2_is_csr),
    .csr_we_o(mem1_mem2_csr_we),
    .csr_wdata_o(mem1_mem2_csr_wdata),
    .csr_waddr_o(mem1_mem2_csr_waddr),
    .write_rd_o(mem1_mem2_write_rd),
    .rd_addr_o(mem1_mem2_rd_addr),
    .alu_result_o(mem1_mem2_alu_result),
    .mem_oper_o(mem1_mem2_mem_oper),
    .trap_o(mem1_mem2_trap),
    
    .stall_i(mem1_mem2_stall),
    .flush_i(mem1_mem2_flush)
);

// MEM2 Stage (Waiting for Memory Request to Finish)
stage_mem2 stage_mem2_i
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),

    // <-> CS Register File
    // write port
    .csr_wdata_o(csr_wdata),
    .csr_waddr_o(csr_waddr),
    .csr_we_o(csr_we),
    
    // from MEM1 stage
    .alu_result_i(mem1_mem2_alu_result),
    .mem_oper_i(mem1_mem2_mem_oper),
    .csr_wdata_i(mem1_mem2_csr_wdata),
    .csr_waddr_i(mem1_mem2_csr_waddr),
    .csr_we_i(mem1_mem2_csr_we),
    .trap_i(mem1_mem2_trap),

    // for WB stage exclusively
    .write_rd_i(mem1_mem2_write_rd),
    .rd_addr_i(mem1_mem2_rd_addr),

    // from LSU unit
    .lsu_req_done_i(lsu_req_done),
    .lsu_rdata_i(lsu_rdata),

    // pipeline registers
    .write_rd_o(mem2_wb_write_rd),
    .rd_addr_o(mem2_wb_rd_addr),
    .alu_result_o(mem2_wb_alu_result),
    .lsu_rdata_o(mem2_wb_lsu_rdata),
    .mem_oper_o(mem2_wb_mem_oper),

    .stall_o(mem2_stall_needed),
    .trap_o(mem2_trap),

    .stall_i(mem2_wb_stall),
    .flush_i(mem2_wb_flush)
);

// Load Store Unit
lsu lsu_i
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),

    // <-> Data Port
    .wb_if(lsu_wb_if),

    // <-> LSU unit
    .req_i(lsu_req),
    .we_i(lsu_we),
    .addr_i(lsu_addr),
    .wsel_byte_i(lsu_wsel_byte),
    .wdata_i(lsu_wdata),

    .req_done_o(lsu_req_done),
    .rdata_o(lsu_rdata),
    .req_stall_o(lsu_req_stall)
);

// Write-back Stage
write_back write_back_i
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),

    // from MEM/WB
    .mem_oper_i(mem2_wb_mem_oper),
    .write_rd_i(mem2_wb_write_rd),
    .rd_addr_i(mem2_wb_rd_addr),
    .alu_result_i(mem2_wb_alu_result),
    .lsu_rdata_i(mem2_wb_lsu_rdata),

    // WB -> Register file
    .regf_write_o(regf_write),
    .regf_waddr_o(regf_waddr),
    .regf_wdata_o(regf_wdata)
);

// Dependency detection unit
controller controller_i
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),

    // from ID stage
    .id_rs1_addr_i(rs1_addr),
    .id_rs2_addr_i(rs2_addr),

    // from ID/EX pipeline
    .id_ex_rs1_addr_i(id_ex_rs1_addr),
    .id_ex_rs2_addr_i(id_ex_rs2_addr),
    .id_ex_rd_addr_i(id_ex_rd_addr),
    .id_ex_write_rd_i(id_ex_write_rd),
    .id_ex_mem_oper_i(id_ex_mem_oper),

    // from EX stage
    .ex_new_pc_en_i(ex_new_pc_en),

    // from EX/MEM1
    .ex_mem1_rd_addr_i(ex_mem1_rd_addr),
    .ex_mem1_write_rd_i(ex_mem1_write_rd),
    .ex_mem1_mem_oper_i(ex_mem1_mem_oper),
    .ex_mem1_alu_result_i(ex_mem1_alu_result),

    // from MEM1/MEM2
    .mem1_mem2_rd_addr_i(mem1_mem2_rd_addr),
    .mem1_mem2_write_rd_i(mem1_mem2_write_rd),
    .mem1_mem2_mem_oper_i(mem1_mem2_mem_oper),
    .mem1_mem2_alu_result_i(mem1_mem2_alu_result),

    // from MEM2/WB
    .mem2_wb_rd_addr_i(mem2_wb_rd_addr),
    .mem2_wb_write_rd_i(mem2_wb_write_rd),
    .mem2_wb_mem_oper_i(mem2_wb_mem_oper),
    .mem2_wb_alu_result_i(mem2_wb_alu_result),
    .mem2_wb_lsu_rdata_i(mem2_wb_lsu_rdata),
    .mem2_stall_needed_i(mem2_stall_needed),
    .mem_trap_i(mem2_trap),

    // from LSU
    .lsu_req_stall_i(lsu_req_stall),

    // forward from EX/MEM1 stage
    .forward_ex_mem1_rs1_o(forward_ex_mem1_rs1),
    .forward_ex_mem1_rs2_o(forward_ex_mem1_rs2),
    .forward_ex_mem1_data_o(forward_ex_mem1_data),
    // forward from MEM1/MEM2 stage
    .forward_mem1_mem2_rs1_o(forward_mem1_mem2_rs1),
    .forward_mem1_mem2_rs2_o(forward_mem1_mem2_rs2),
    .forward_mem1_mem2_data_o(forward_mem1_mem2_data),
    // froward from MEM2/WB stage
    .forward_mem2_wb_rs1_o(forward_mem2_wb_rs1),
    .forward_mem2_wb_rs2_o(forward_mem2_wb_rs2),
    .forward_mem2_wb_data_o(forward_mem2_wb_data),

    // .if_pc_i(imem_raddr_o),
    // .if_id_instr_valid_i(if_id_instr_valid),
    // .if_id_pc_i(if_id_pc),
    // .id_ex_instr_valid_i(id_ex_instr_valid),
    // .id_ex_pc_i(id_ex_pc),
    // .ex_mem1_instr_valid_i(ex_mem1_instr_valid),
    // .ex_mem1_pc_i(ex_mem1_pc),

    // to cs registers
    .csr_mret_o(is_mret),
    .csr_mcause_o(mcause),
    .is_trap_o(is_trap),
    .exc_pc_o(exc_pc),

    // to handle CSR read/write side effects
    .id_is_csr_i(id_is_csr),
    .ex_is_csr_i(id_ex_is_csr),
    .mem1_is_csr_i(ex_mem1_is_csr),
    .mem2_is_csr_i(mem1_mem2_is_csr),

    // for interrupt handling
    .current_plvl_i(current_plvl),
    .csr_mstatus_i(csr_mstatus),
    .irq_pending_i(irq_pending),

    // to fetch stage, to steer the pc
    .new_pc_en_o(new_pc_en),
    .pc_sel_o(pc_sel),

    // hazard lines to ID/EX
    .id_ex_flush_o(id_ex_flush),
    .id_ex_stall_o(id_ex_stall),

    // hazard lines to IF/EX
    .if_id_stall_o(if_id_stall),
    .if_id_flush_o(if_id_flush),

    // flush/stall to EX/MEM1
    .ex_mem1_stall_o(ex_mem1_stall),
    .ex_mem1_flush_o(ex_mem1_flush),

    // flush/stall to MEM1/MEM2
    .mem1_mem2_stall_o(mem1_mem2_stall),
    .mem1_mem2_flush_o(mem1_mem2_flush),

    // flush/stall to MEM2/WB
    .mem2_wb_stall_o(mem2_wb_stall),
    .mem2_wb_flush_o(mem2_wb_flush)
);

endmodule : core_top