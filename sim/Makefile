# runs the simulations
.PHONY: clean all compile_sim run_sim questa_compile questa_run questa_clean

# simulation definitions
IMEMFILE := ""
DMEMFILE := ""
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
DEFINES := -gIMEMFILE=\"$(IMEMFILE)\" -gDMEMFILE=\"$(DMEMFILE)\"
TOP_PARAMS := -gMEMFILE=\"${MEMFILE}\" $(DEFINES)

PRJ_DIR := $(SRC_DIR)
export PRJ_DIR
export SIM_TOP = $(TOPMOD)

TRACING_OPTIONS := --trace --trace-max-array 2048
#verilator arguments
VERILATOR=verilator
VFLAGS= -cc --exe --timing $(TRACING_OPTIONS) $(DEFINES) $(MODULES_PATH) $(INCLUDE_PATH) $(TOP_PARAMS)

# signature start and end
begin_signature ?= 0
end_signature ?= 0
sig_filename_o ?= ""
IS_GUI ?= 1

compile_sim:
	$(VERILATOR) $(VFLAGS) $(TOPMOD_FILE) $(SIMFILE)
	$(MAKE) -j -C obj_dir -f V$(TOPMOD).mk

run_sim:
	obj_dir/V$(TOPMOD) +trace

# QUESTASIM ARGUMENTS
LIB_NAME ?= work
TOP_PARAMS += +begin_signature=${begin_signature} +end_signature=${end_signature} +sig_filename_o=${sig_filename_o}
DO_FILE := ""

ifeq ($(IS_GUI), 1)
	TOP_PARAMS += -gui=interactive 
	DO_FILE := run_gui.tcl
else
	DO_FILE := run.tcl
endif

questa:
	qrun -64 +acc -modelsimini modelsim.ini -f files.f -sv -sv12compat -timescale "1ns/1ps" -O5 -outdir questa_work -top $(TOPMOD) $(TOP_PARAMS) -do $(DO_FILE)

questa_clean:
	qrun -clean

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