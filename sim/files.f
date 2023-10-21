// include directories
+incdir+${PRJ_DIR}/core/
+incdir+${PRJ_DIR}/core/includes/

// packages
${PRJ_DIR}/core/includes/riscv_pkg.svh
${PRJ_DIR}/core/includes/csr_pkg.sv

//  core
${PRJ_DIR}/core/core_top.sv
${PRJ_DIR}/core/decode.sv
${PRJ_DIR}/core/dep_hzrd_detection.sv
${PRJ_DIR}/core/execute.sv
${PRJ_DIR}/core/mem_rw.sv
${PRJ_DIR}/core/reg_file.sv
${PRJ_DIR}/core/simple_fetch.sv
${PRJ_DIR}/core/write_back.sv
${PRJ_DIR}/core/cs_registers.sv
${PRJ_DIR}/core/csr.sv

// memories
${PRJ_DIR}/memories/*

// testbenches
${PRJ_DIR}/testbenches/*
