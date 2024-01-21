
global env
set TOP sim:$env(SIM_TOP)
set PLATFORM ${TOP}/yarc_platform_i
set CORE ${PLATFORM}/core_i

add wave ${CORE}/clk_i;
add wave ${CORE}/rstn_i;

# ---------------------------------------------------------
add wave -divider {FETCH}
add wave -color Gold ${CORE}/wb_prefetch_i/valid_o;
add wave -color Gold ${CORE}/wb_prefetch_i/instr_o;
add wave -color Gold ${CORE}/wb_prefetch_i/pc_o;
add wave ${CORE}/wb_prefetch_i/stall_i;
add wave ${CORE}/wb_prefetch_i/flush_cache_i;
add wave ${CORE}/wb_prefetch_i/new_pc_en_i;
add wave ${CORE}/wb_prefetch_i/pc_sel_i;
add wave ${CORE}/wb_prefetch_i/branch_target_i;
add wave ${CORE}/wb_prefetch_i/csr_mepc_i;
add wave ${CORE}/wb_prefetch_i/mcause_i;
add wave ${CORE}/wb_prefetch_i/mtvec_i;

add wave -group {FETCH WISHBONE} -color Gold ${CORE}/wb_prefetch_i/wb_if/*;

add wave ${CORE}/wb_prefetch_i/state;
add wave ${CORE}/wb_prefetch_i/next;
add wave ${CORE}/wb_prefetch_i/fetch_pc_d;
add wave ${CORE}/wb_prefetch_i/fetch_pc_q;
add wave ${CORE}/wb_prefetch_i/arch_pc_d;
add wave ${CORE}/wb_prefetch_i/arch_pc_q;
add wave ${CORE}/wb_prefetch_i/exc_target_addr;

add wave ${CORE}/wb_prefetch_i/*;
add wave ${CORE}/wb_prefetch_i/sync_fifo_i/*;

# ---------------------------------------------------------
add wave -divider {REGISTER FILE}
add wave ${CORE}/reg_file_i/regf;
add wave ${CORE}/reg_file_i/rs1_addr_i;
add wave ${CORE}/reg_file_i/rs2_addr_i;
add wave ${CORE}/reg_file_i/write_i;
add wave ${CORE}/reg_file_i/waddr_i;
add wave ${CORE}/reg_file_i/wdata_i;
add wave -color Gold ${CORE}/reg_file_i/rs1_data_o;
add wave -color Gold ${CORE}/reg_file_i/rs2_data_o;

# ---------------------------------------------------------
add wave -divider {CS REGISTERS}
add wave ${CORE}/cs_registers_i/csr_re_i;
add wave ${CORE}/cs_registers_i/csr_raddr;
add wave ${CORE}/cs_registers_i/csr_rdata_o;

add wave ${CORE}/cs_registers_i/csr_we_i;
add wave ${CORE}/cs_registers_i/csr_waddr;
add wave ${CORE}/cs_registers_i/csr_wdata_i;

add wave ${CORE}/cs_registers_i/csr_mepc_o;
add wave ${CORE}/cs_registers_i/csr_mtvec_o;
add wave ${CORE}/cs_registers_i/csr_mstatus_o;
add wave ${CORE}/cs_registers_i/irq_pending_o;

# ret, traps...
add wave ${CORE}/cs_registers_i/csr_mret_i;
add wave ${CORE}/cs_registers_i/is_trap_i;
add wave ${CORE}/cs_registers_i/mcause_i;
add wave ${CORE}/cs_registers_i/exc_pc_i;

# interrupts
add wave ${CORE}/cs_registers_i/irq_software_i;
add wave ${CORE}/cs_registers_i/irq_timer_i;
add wave ${CORE}/cs_registers_i/irq_external_i;

add wave ${CORE}/cs_registers_i/current_plvl_q;
add wave ${CORE}/cs_registers_i/current_plvl_d;

add wave -group {CSRs} ${CORE}/cs_registers_i/mstatus_wen;
add wave -group {CSRs} ${CORE}/cs_registers_i/mstatus_d;
add wave -group {CSRs} ${CORE}/cs_registers_i/mstatus_q;

add wave -group {CSRs} ${CORE}/cs_registers_i/mscratch_wen;
add wave -group {CSRs} ${CORE}/cs_registers_i/mscratch_d;
add wave -group {CSRs} ${CORE}/cs_registers_i/mscratch_q;

add wave -group {CSRs} ${CORE}/cs_registers_i/mepc_wen;
add wave -group {CSRs} ${CORE}/cs_registers_i/mepc_d;
add wave -group {CSRs} ${CORE}/cs_registers_i/mepc_q;

add wave -group {CSRs} ${CORE}/cs_registers_i/mie_wen;
add wave -group {CSRs} ${CORE}/cs_registers_i/mie_d;
add wave -group {CSRs} ${CORE}/cs_registers_i/mie_q;

add wave -group {CSRs} ${CORE}/cs_registers_i/mip_d;

add wave -group {CSRs} ${CORE}/cs_registers_i/mtvec_wen;
add wave -group {CSRs} ${CORE}/cs_registers_i/mtvec_d;
add wave -group {CSRs} ${CORE}/cs_registers_i/mtvec_q;

add wave -group {CSRs} ${CORE}/cs_registers_i/mcause_wen;
add wave -group {CSRs} ${CORE}/cs_registers_i/mcause_d;
add wave -group {CSRs} ${CORE}/cs_registers_i/mcause_q;

add wave -group {CSRs} ${CORE}/cs_registers_i/mcountinhibit_wen;
add wave -group {CSRs} ${CORE}/cs_registers_i/mcountinhibit_d;
add wave -group {CSRs} ${CORE}/cs_registers_i/mcountinhibit_q;

add wave -group {Perf Counters} ${CORE}/cs_registers_i/mhpmcounter;
add wave -group {Perf Counters} ${CORE}/cs_registers_i/mhpmcounter_we;
add wave -group {Perf Counters} ${CORE}/cs_registers_i/mhpmcounterh_we;
add wave -group {Perf Counters} ${CORE}/cs_registers_i/mhpmcounter_incr;

# ---------------------------------------------------------
add wave -divider {DECODE}
add wave ${CORE}/decode_i/current_plvl_i;
add wave ${CORE}/decode_i/pc_i;
add wave ${CORE}/decode_i/instr_i;
add wave ${CORE}/decode_i/stall_i;
add wave ${CORE}/decode_i/flush_i;
add wave ${CORE}/decode_i/regf_rs1_addr_o;
add wave ${CORE}/decode_i/regf_rs2_addr_o;
add wave ${CORE}/decode_i/rs1_data_i;
add wave ${CORE}/decode_i/rs2_data_i;

add wave -color Gold ${CORE}/decode_i/pc_o;
add wave -color Gold ${CORE}/decode_i/rs1_data_o;
add wave -color Gold ${CORE}/decode_i/rs2_data_o;
add wave -color Gold ${CORE}/decode_i/imm_o;
add wave -color Gold ${CORE}/decode_i/csr_rdata_o;
add wave -color Gold ${CORE}/decode_i/alu_oper1_src_o;
add wave -color Gold ${CORE}/decode_i/alu_oper2_src_o;
add wave -color Gold ${CORE}/decode_i/bnj_oper_o;
add wave -color Gold ${CORE}/decode_i/alu_oper_o;
add wave -color Gold ${CORE}/decode_i/mem_oper_o;
add wave -color Gold ${CORE}/decode_i/csr_waddr_o;
add wave -color Gold ${CORE}/decode_i/csr_we_o;
add wave -color Gold ${CORE}/decode_i/write_rd_o;
add wave -color Gold ${CORE}/decode_i/rd_addr_o;
add wave -color Gold ${CORE}/decode_i/rs1_addr_o;
add wave -color Gold ${CORE}/decode_i/rs2_addr_o;
add wave -color Turquoise ${CORE}/decode_i/trap_o;

# ---------------------------------------------------------
add wave -divider {EXECUTE}
add wave ${CORE}/execute_i/pc_i;
add wave ${CORE}/execute_i/rs1_data_i;
add wave ${CORE}/execute_i/rs2_data_i;
add wave ${CORE}/execute_i/imm_i;
add wave ${CORE}/execute_i/alu_oper1_src_i;
add wave ${CORE}/execute_i/alu_oper2_src_i;
add wave ${CORE}/execute_i/alu_oper_i;
add wave ${CORE}/execute_i/bnj_oper_i;
add wave ${CORE}/execute_i/is_csr_i;
add wave ${CORE}/execute_i/instr_valid_i;

add wave ${CORE}/execute_i/mem_oper_i;
add wave ${CORE}/execute_i/csr_waddr_i;
add wave ${CORE}/execute_i/csr_we_i;
add wave -color Turquoise ${CORE}/execute_i/trap_i;

add wave ${CORE}/execute_i/write_rd_i;
add wave ${CORE}/execute_i/rd_addr_i;

add wave ${CORE}/execute_i/new_pc_en_o;
add wave ${CORE}/execute_i/branch_target_o;

add wave -color Turquoise ${CORE}/execute_i/stall_i;
add wave -color Turquoise ${CORE}/execute_i/flush_i;

add wave -color Turquoise ${CORE}/execute_i/forward_ex_mem1_rs1_i;
add wave -color Turquoise ${CORE}/execute_i/forward_ex_mem1_rs2_i;
add wave -color Turquoise ${CORE}/execute_i/forward_ex_mem1_data_i;
add wave -color Turquoise ${CORE}/execute_i/forward_mem1_mem2_rs1_i;
add wave -color Turquoise ${CORE}/execute_i/forward_mem1_mem2_rs2_i;
add wave -color Turquoise ${CORE}/execute_i/forward_mem1_mem2_data_i;
add wave -color Turquoise ${CORE}/execute_i/forward_mem2_wb_rs1_i;
add wave -color Turquoise ${CORE}/execute_i/forward_mem2_wb_rs2_i;
add wave -color Turquoise ${CORE}/execute_i/forward_mem2_wb_data_i;

add wave -color Gold ${CORE}/execute_i/alu_result_o;
add wave -color Gold ${CORE}/execute_i/alu_oper2_o;
add wave -color Gold ${CORE}/execute_i/mem_oper_o;
add wave -color Gold ${CORE}/execute_i/csr_wdata_o;
add wave -color Gold ${CORE}/execute_i/csr_waddr_o;
add wave -color Gold ${CORE}/execute_i/csr_we_o;
add wave -color Gold ${CORE}/execute_i/is_csr_o;
add wave -color Turquoise ${CORE}/execute_i/trap_o;
add wave -color Gold ${CORE}/execute_i/pc_o;
add wave -color Gold ${CORE}/execute_i/instr_valid_o;

add wave -color Gold ${CORE}/execute_i/write_rd_o;
add wave -color Gold ${CORE}/execute_i/rd_addr_o;

add wave ${CORE}/execute_i/operand1;
add wave ${CORE}/execute_i/operand2;
# ---------------------------------------------------------
add wave -divider {MEM1}
add wave ${CORE}/stage_mem1_i/lsu_req_o;
add wave ${CORE}/stage_mem1_i/lsu_addr_o;
add wave ${CORE}/stage_mem1_i/lsu_we_o;
add wave ${CORE}/stage_mem1_i/lsu_rdata_i;
add wave ${CORE}/stage_mem1_i/lsu_wsel_byte_o;
add wave ${CORE}/stage_mem1_i/lsu_wdata_o;
add wave ${CORE}/stage_mem1_i/lsu_req_stall_i;

add wave ${CORE}/stage_mem1_i/ex_trap_i;
add wave ${CORE}/stage_mem1_i/id_ex_mem_oper_i;

add wave ${CORE}/stage_mem1_i/alu_result_i;
add wave ${CORE}/stage_mem1_i/alu_oper2_i;
add wave ${CORE}/stage_mem1_i/mem_oper_i;
add wave ${CORE}/stage_mem1_i/trap_i;
add wave ${CORE}/stage_mem1_i/write_rd_i;
add wave ${CORE}/stage_mem1_i/rd_addr_i;

add wave ${CORE}/stage_mem1_i/csr_wdata_i;
add wave ${CORE}/stage_mem1_i/csr_waddr_i;
add wave ${CORE}/stage_mem1_i/is_csr_i;
add wave ${CORE}/stage_mem1_i/csr_we_i;

add wave -color Turquoise ${CORE}/stage_mem1_i/stall_i;
add wave -color Turquoise ${CORE}/stage_mem1_i/flush_i;

add wave -color Gold ${CORE}/stage_mem1_i/is_csr_o;
add wave -color Gold ${CORE}/stage_mem1_i/csr_we_o;
add wave -color Gold ${CORE}/stage_mem1_i/csr_wdata_o;
add wave -color Gold ${CORE}/stage_mem1_i/csr_waddr_o;

add wave -color Gold ${CORE}/stage_mem1_i/write_rd_o;
add wave -color Gold ${CORE}/stage_mem1_i/rd_addr_o;
add wave -color Gold ${CORE}/stage_mem1_i/alu_result_o;
add wave -color Gold ${CORE}/stage_mem1_i/mem_oper_o;
add wave -color Turquoise ${CORE}/stage_mem1_i/trap_o;

# ---------------------------------------------------------
add wave -divider {MEM2}

add wave ${CORE}/stage_mem2_i/csr_we_o;
add wave ${CORE}/stage_mem2_i/csr_wdata_o;
add wave ${CORE}/stage_mem2_i/csr_waddr_o;

add wave ${CORE}/stage_mem2_i/alu_result_i;
add wave ${CORE}/stage_mem2_i/mem_oper_i;
add wave ${CORE}/stage_mem2_i/csr_wdata_i;
add wave ${CORE}/stage_mem2_i/csr_waddr_i;
add wave ${CORE}/stage_mem2_i/csr_we_i;

add wave ${CORE}/stage_mem2_i/trap_i;

add wave ${CORE}/stage_mem2_i/write_rd_i;
add wave ${CORE}/stage_mem2_i/rd_addr_i;

add wave ${CORE}/stage_mem2_i/lsu_req_done_i;
add wave ${CORE}/stage_mem2_i/lsu_rdata_i;

add wave ${CORE}/stage_mem2_i/stall_o;
add wave ${CORE}/stage_mem2_i/trap_o;

add wave -color Gold ${CORE}/stage_mem2_i/write_rd_o;
add wave -color Gold ${CORE}/stage_mem2_i/rd_addr_o;
add wave -color Gold ${CORE}/stage_mem2_i/alu_result_o;
add wave -color Gold ${CORE}/stage_mem2_i/lsu_rdata_o;
add wave -color Gold ${CORE}/stage_mem2_i/mem_oper_o;

# ---------------------------------------------------------
add wave -group {LSU WISHBONE} -color Gold ${CORE}/lsu_i/wb_if/*;

add wave -group {LSU} ${CORE}/lsu_i/req_i;
add wave -group {LSU} ${CORE}/lsu_i/we_i;
add wave -group {LSU} ${CORE}/lsu_i/addr_i;
add wave -group {LSU} ${CORE}/lsu_i/wsel_byte_i;
add wave -group {LSU} ${CORE}/lsu_i/wdata_i;
add wave -group {LSU} ${CORE}/lsu_i/req_done_o;
add wave -group {LSU} ${CORE}/lsu_i/rdata_o;
add wave -group {LSU} ${CORE}/lsu_i/req_stall_o;

# ---------------------------------------------------------
add wave -divider {WRITE BACK}
add wave ${CORE}/write_back_i/mem_oper_i;
add wave ${CORE}/write_back_i/write_rd_i;
add wave ${CORE}/write_back_i/rd_addr_i;
add wave ${CORE}/write_back_i/alu_result_i;
add wave ${CORE}/write_back_i/lsu_rdata_i;

add wave -color Gold ${CORE}/write_back_i/regf_write_o;
add wave -color Gold ${CORE}/write_back_i/regf_waddr_o;
add wave -color Gold ${CORE}/write_back_i/regf_wdata_o;

# ---------------------------------------------------------
add wave -divider {CONTROLLER}
add wave -color Turquoise ${CORE}/controller_i/forward_ex_mem1_rs1_o;
add wave -color Turquoise ${CORE}/controller_i/forward_ex_mem1_rs2_o;
add wave -color Turquoise ${CORE}/controller_i/forward_ex_mem1_data_o;
add wave -color Turquoise ${CORE}/controller_i/forward_mem1_mem2_rs1_o;
add wave -color Turquoise ${CORE}/controller_i/forward_mem1_mem2_rs2_o;
add wave -color Turquoise ${CORE}/controller_i/forward_mem1_mem2_data_o;
add wave -color Turquoise ${CORE}/controller_i/forward_mem2_wb_rs1_o;
add wave -color Turquoise ${CORE}/controller_i/forward_mem2_wb_rs2_o;
add wave -color Turquoise ${CORE}/controller_i/forward_mem2_wb_data_o;
add wave -color Turquoise ${CORE}/controller_i/id_ex_flush_o;
add wave -color Turquoise ${CORE}/controller_i/id_ex_stall_o;
add wave -color Turquoise ${CORE}/controller_i/if_stall_o;
add wave -color Turquoise ${CORE}/controller_i/if_flush_o;
add wave -color Turquoise ${CORE}/controller_i/ex_mem1_flush_o;
add wave -color Turquoise ${CORE}/controller_i/ex_mem1_stall_o;
add wave -color Turquoise ${CORE}/controller_i/mem1_mem2_flush_o;
add wave -color Turquoise ${CORE}/controller_i/mem1_mem2_stall_o;
add wave -color Turquoise ${CORE}/controller_i/mem2_wb_flush_o;
add wave -color Turquoise ${CORE}/controller_i/mem2_wb_stall_o;

add wave ${CORE}/controller_i/state;
add wave ${CORE}/controller_i/next;

# add wave ${CORE}/controller_i/if_pc_i;
# add wave ${CORE}/controller_i/if_id_instr_valid_i;
# add wave ${CORE}/controller_i/if_id_pc_i;
# add wave ${CORE}/controller_i/id_ex_instr_valid_i;
# add wave ${CORE}/controller_i/id_ex_pc_i;
# add wave ${CORE}/controller_i/ex_mem_instr_valid_i;
# add wave ${CORE}/controller_i/ex_mem_pc_i;

add wave ${CORE}/controller_i/id_is_csr_i;
add wave ${CORE}/controller_i/ex_is_csr_i;
add wave ${CORE}/controller_i/mem1_is_csr_i;
add wave ${CORE}/controller_i/mem2_is_csr_i;

add wave ${CORE}/controller_i/new_pc_en_o;
add wave ${CORE}/controller_i/pc_sel_o;
add wave ${CORE}/controller_i/csr_mret_o;
add wave ${CORE}/controller_i/csr_mcause_o;
add wave ${CORE}/controller_i/is_trap_o;
add wave ${CORE}/controller_i/exc_pc_o;
# ---------------------------------------------------------
add wave -divider {WB Interconnect}
add wave ${PLATFORM}/wb_interconnect_i/*;
# ---------------------------------------------------------
add wave -divider {Riscv Timer}
add wave ${PLATFORM}/mtimer_i/timer_int_o;
add wave ${PLATFORM}/mtimer_i/mtime_d;
add wave ${PLATFORM}/mtimer_i/mtime_q;
add wave ${PLATFORM}/mtimer_i/mtimecmp_d;
add wave ${PLATFORM}/mtimer_i/mtimecmp_q;

# ---------------------------------------------------------
add wave -divider {Platform}
add wave ${PLATFORM}/*;

# ---------------------------------------------------------
# disable creation of the transcript file
transcript off
run -all