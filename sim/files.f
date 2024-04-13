// include directories
+incdir+${PRJ_DIR}/core/
+incdir+${PRJ_DIR}/core/includes/

// packages
${PRJ_DIR}/core/includes/riscv_pkg.sv
${PRJ_DIR}/core/includes/csr_pkg.sv
${PRJ_DIR}/platform/includes/platform_pkg.sv

// peripherals
${PRJ_DIR}/peripherals/wbuart32/rtl/ufifo.v
${PRJ_DIR}/peripherals/wbuart32/rtl/rxuart.v
${PRJ_DIR}/peripherals/wbuart32/rtl/txuart.v
${PRJ_DIR}/peripherals/wbuart32/rtl/wbuart.v

${PRJ_DIR}/peripherals/hdmi/tmds_encoder.sv
${PRJ_DIR}/peripherals/hdmi/serializer.sv
${PRJ_DIR}/peripherals/hdmi/hdmi_core.sv

// interfaces
${PRJ_DIR}/interfaces/wishbone_if.sv

// utils
${PRJ_DIR}/utils/sync_fifo.sv

// fetch modules
// ${PRJ_DIR}/core/simple_fetch.sv
${PRJ_DIR}/core/fetch_modules/wb_prefetch.sv

// core
${PRJ_DIR}/core/core_top.sv
${PRJ_DIR}/core/decode.sv
${PRJ_DIR}/core/controller.sv
${PRJ_DIR}/core/execute.sv
${PRJ_DIR}/core/reg_file.sv
${PRJ_DIR}/core/write_back.sv
${PRJ_DIR}/core/perf_counter.sv
${PRJ_DIR}/core/cs_registers.sv
${PRJ_DIR}/core/csr.sv
${PRJ_DIR}/core/stage_mem1.sv
${PRJ_DIR}/core/stage_mem2.sv
${PRJ_DIR}/core/lsu.sv

// platform
${PRJ_DIR}/interconnects/addrdecode.v
${PRJ_DIR}/interconnects/skidbuffer.v
${PRJ_DIR}/interconnects/wbxbar.v
${PRJ_DIR}/interconnects/wb_interconnect.sv
${PRJ_DIR}/platform/mtimer.sv
${PRJ_DIR}/platform/led_driver.sv
${PRJ_DIR}/platform/yarc_platform.sv

// memories
// ${PRJ_DIR}/memories/dp_mem_wb.sv
${PRJ_DIR}/memories/sp_mem_wb.sv
${PRJ_DIR}/memories/tdp_mem.sv

// testbenches
${PRJ_DIR}/peripherals/wbuart32/rtl/rxuartlite.v
${PRJ_DIR}/testbenches/rxuart_printer.sv
${PRJ_DIR}/testbenches/core_with_mem.sv
${PRJ_DIR}/testbenches/verilator_top.sv
