# runs the simulations
.PHONY: clean all

MEMFILE := ""
CURRENT_DIR=$(shell pwd)

TOPMOD  := riscv_tests
TOPMOD_FILE := $(TOPMOD).sv
VERILATOR_ARGS = -cc --build -j 0 --timing
VINC = /usr/share/verilator/include
SRC_DIR = $(CURRENT_DIR)/../src
$(info SRC_DIR is $(SRC_DIR))
MODULES_PATH := -y ../src -y ../src/core -y ../src/memories -y ../src/testbenches
INCLUDE_PATH := -I../src/core/includes
SIMPROG := tb
SIMFILE := $(SIMPROG).cpp
VDIRFB  := ./obj_dir
TOP_PARAMS := -GMEMFILE=\"${MEMFILE}\"

PRJ_DIR := $(SRC_DIR)
export PRJ_DIR
# # simulation definitions
# IMEMFILE := ""
# DMEMFILE := ""

DEFINES := +define+IMEMFILE=\"$(IMEMFILE)\" +define+DMEMFILE=\"$(DMEMFILE)\"
TRACING_OPTIONS := --trace --trace-max-array 2048
#verilator arguments
VERILATOR=verilator
VFLAGS= -cc --exe --timing $(TRACING_OPTIONS) $(DEFINES) $(MODULES_PATH) $(INCLUDE_PATH) $(TOP_PARAMS)

compile_sim:
	$(VERILATOR) $(VFLAGS) $(TOPMOD_FILE) $(SIMFILE)
	$(MAKE) -j -C obj_dir -f V$(TOPMOD).mk

run_sim:
	obj_dir/V$(TOPMOD) +trace

LIB_NAME ?= work

questa_compile:
	vlib $(LIB_NAME)
	vmap work ./work
	vlog -work $(LIB_NAME) -modelsimini modelsim.ini -f files.f -sv -sv12compat -timescale "1ns/1ps" -O5
	vopt +acc riscv_tests -o riscv_test_opt

questa_run:
	vsim -do vsim.do riscv_tests_opt

questa_clean:
	vdel -all -lib $(LIB_NAME)

clean:
	rm -rf $(VDIRFB)/

##
## Find all of the Verilog dependencies and submodules
##
DEPS := $(wildcard $(VDIRFB)/*.d)

## Include any of these submodules in the Makefile
## ... but only if we are not building the "clean" target
## which would (oops) try to build those dependencies again
##
ifneq ($(MAKECMDGOALS),clean)
ifneq ($(DEPS),)
include $(DEPS)
endif
endif