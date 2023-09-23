
set TOP riscv_tests
set CORE ${TOP}/core_i

add wave sim:${CORE}/clk_i;
add wave sim:${CORE}/rstn_i;

# ---------------------------------------------------------
add wave -divider {FETCH}
add wave -color Gold sim:${CORE}/simple_fetch_i/valid_o;
add wave -color Gold sim:${CORE}/simple_fetch_i/instr_o;
add wave -color Gold sim:${CORE}/simple_fetch_i/pc_o;
add wave sim:${CORE}/simple_fetch_i/stall_i;
add wave sim:${CORE}/simple_fetch_i/new_pc_i;
add wave sim:${CORE}/simple_fetch_i/pc_i;
add wave sim:${CORE}/simple_fetch_i/read_o;
add wave sim:${CORE}/simple_fetch_i/raddr_o;
add wave sim:${CORE}/simple_fetch_i/rdata_i;

# ---------------------------------------------------------
add wave -divider {REGISTER FILE}
add wave sim:${CORE}/reg_file_i/regf;
add wave sim:${CORE}/reg_file_i/rs1_addr_i;
add wave sim:${CORE}/reg_file_i/rs2_addr_i;
add wave sim:${CORE}/reg_file_i/write_i;
add wave sim:${CORE}/reg_file_i/waddr_i;
add wave sim:${CORE}/reg_file_i/wdata_i;
add wave -color Gold sim:${CORE}/reg_file_i/rs1_data_o;
add wave -color Gold sim:${CORE}/reg_file_i/rs2_data_o;

# ---------------------------------------------------------
add wave -divider {DECODE}
add wave sim:${CORE}/decode_i/pc_i;
add wave sim:${CORE}/decode_i/instr_i;
add wave sim:${CORE}/decode_i/stall_i;
add wave sim:${CORE}/decode_i/flush_i;
add wave sim:${CORE}/decode_i/regf_rs1_addr_o;
add wave sim:${CORE}/decode_i/regf_rs2_addr_o;
add wave sim:${CORE}/decode_i/rs1_data_i;
add wave sim:${CORE}/decode_i/rs2_data_i;

add wave -color Gold sim:${CORE}/decode_i/pc_o;
add wave -color Gold sim:${CORE}/decode_i/rs1_data_o;
add wave -color Gold sim:${CORE}/decode_i/rs2_data_o;
add wave -color Gold sim:${CORE}/decode_i/imm_o;
add wave -color Gold sim:${CORE}/decode_i/alu_oper1_src_o;
add wave -color Gold sim:${CORE}/decode_i/alu_oper2_src_o;
add wave -color Gold sim:${CORE}/decode_i/bnj_oper_o;
add wave -color Gold sim:${CORE}/decode_i/alu_oper_o;
add wave -color Gold sim:${CORE}/decode_i/mem_oper_o;
add wave -color Gold sim:${CORE}/decode_i/wb_use_mem_o;
add wave -color Gold sim:${CORE}/decode_i/write_rd_o;
add wave -color Gold sim:${CORE}/decode_i/rd_addr_o;
add wave -color Gold sim:${CORE}/decode_i/rs1_addr_o;
add wave -color Gold sim:${CORE}/decode_i/rs2_addr_o;
add wave -color Turquoise sim:${CORE}/decode_i/trap_o;

# ---------------------------------------------------------
add wave -divider {EXECUTE}
add wave sim:${CORE}/execute_i/pc_i;
add wave sim:${CORE}/execute_i/rs1_data_i;
add wave sim:${CORE}/execute_i/rs2_data_i;
add wave sim:${CORE}/execute_i/imm_i;
add wave sim:${CORE}/execute_i/alu_oper1_src_i;
add wave sim:${CORE}/execute_i/alu_oper2_src_i;
add wave sim:${CORE}/execute_i/alu_oper_i;
add wave sim:${CORE}/execute_i/bnj_oper_i;
add wave sim:${CORE}/execute_i/mem_oper_i;
add wave -color Turquoise sim:${CORE}/execute_i/trap_i;
add wave sim:${CORE}/execute_i/wb_use_mem_i;
add wave sim:${CORE}/execute_i/write_rd_i;
add wave sim:${CORE}/execute_i/rd_addr_i;
add wave -color Turquoise sim:${CORE}/execute_i/stall_i;
add wave -color Turquoise sim:${CORE}/execute_i/flush_i;

add wave -color Turquoise sim:${CORE}/execute_i/forward_ex_mem_rs1_i;
add wave -color Turquoise sim:${CORE}/execute_i/forward_ex_mem_rs2_i;
add wave -color Turquoise sim:${CORE}/execute_i/forward_ex_mem_data_i;
add wave -color Turquoise sim:${CORE}/execute_i/forward_mem_wb_rs1_i;
add wave -color Turquoise sim:${CORE}/execute_i/forward_mem_wb_rs2_i;
add wave -color Turquoise sim:${CORE}/execute_i/forward_mem_wb_data_i;

add wave -color Gold sim:${CORE}/execute_i/alu_result_o;
add wave -color Gold sim:${CORE}/execute_i/alu_oper2_o;
add wave -color Gold sim:${CORE}/execute_i/mem_oper_o;
add wave -color Turquoise sim:${CORE}/execute_i/trap_o;
add wave -color Gold sim:${CORE}/execute_i/wb_use_mem_o;
add wave -color Gold sim:${CORE}/execute_i/write_rd_o;
add wave -color Gold sim:${CORE}/execute_i/rd_addr_o;
add wave -color Gold sim:${CORE}/execute_i/load_pc_o;
add wave -color Gold sim:${CORE}/execute_i/new_pc_o;

# ---------------------------------------------------------
add wave -divider {MEM_RW}
add wave sim:${CORE}/mem_rw_i/alu_result_i;
add wave sim:${CORE}/mem_rw_i/alu_oper2_i;
add wave sim:${CORE}/mem_rw_i/mem_oper_i;
add wave sim:${CORE}/mem_rw_i/trap_i;
add wave sim:${CORE}/mem_rw_i/wb_use_mem_i;
add wave sim:${CORE}/mem_rw_i/write_rd_i;
add wave sim:${CORE}/mem_rw_i/rd_addr_i;

add wave sim:${CORE}/mem_rw_i/rw_addr_o;
add wave sim:${CORE}/mem_rw_i/read_o;
add wave sim:${CORE}/mem_rw_i/rdata_i;
add wave sim:${CORE}/mem_rw_i/wsel_byte_o;
add wave sim:${CORE}/mem_rw_i/wdata_o;

add wave -color Gold sim:${CORE}/mem_rw_i/wb_use_mem_o;
add wave -color Gold sim:${CORE}/mem_rw_i/write_rd_o;
add wave -color Gold sim:${CORE}/mem_rw_i/rd_addr_o;
add wave -color Gold sim:${CORE}/mem_rw_i/alu_result_o;
add wave -color Gold sim:${CORE}/mem_rw_i/dmem_rdata_o;
add wave -color Turquoise sim:${CORE}/mem_rw_i/trap_o;

# ---------------------------------------------------------
add wave -divider {WRITE BACK}
add wave sim:${CORE}/write_back_i/use_mem_i;
add wave sim:${CORE}/write_back_i/write_rd_i;
add wave sim:${CORE}/write_back_i/rd_addr_i;
add wave sim:${CORE}/write_back_i/alu_result_i;
add wave sim:${CORE}/write_back_i/dmem_rdata_i;

add wave -color Gold sim:${CORE}/write_back_i/regf_write_o;
add wave -color Gold sim:${CORE}/write_back_i/regf_waddr_o;
add wave -color Gold sim:${CORE}/write_back_i/regf_wdata_o;

---------------------------------------------------------
add wave -divider {DEP DETECTION}
add wave -color Turquoise sim:${CORE}/dep_detection_i/forward_ex_mem_rs1_o;
add wave -color Turquoise sim:${CORE}/dep_detection_i/forward_ex_mem_rs2_o;
add wave -color Turquoise sim:${CORE}/dep_detection_i/forward_ex_mem_data_o;
add wave -color Turquoise sim:${CORE}/dep_detection_i/forward_mem_wb_rs1_o;
add wave -color Turquoise sim:${CORE}/dep_detection_i/forward_mem_wb_rs2_o;
add wave -color Turquoise sim:${CORE}/dep_detection_i/forward_mem_wb_data_o;
add wave -color Turquoise sim:${CORE}/dep_detection_i/id_ex_flush_o;
add wave -color Turquoise sim:${CORE}/dep_detection_i/id_ex_stall_o;
add wave -color Turquoise sim:${CORE}/dep_detection_i/if_id_stall_o;

run -all