# runs the simulations

.PHONY: clean all

TOPMOD  := tb
TOPMOD_FILE := $(TOPMOD).sv
VERILATOR_ARGS = -cc --build -j 0 --timing
VINC = /usr/share/verilator/include
SRC_PATH := ../src
SIMPROG := tb
SIMFILE := $(SIMPROG).cpp
VDIRFB  := ./obj_dir

DEFINES := +define+DOUBLE_COUNTING

#verilator arguments
VERILATOR=verilator
VFLAGS= -cc --exe --timing --trace $(DEFINES) -y $(SRC_PATH)

sim:
	$(VERILATOR) $(VFLAGS) $(TOPMOD_FILE) $(SIMFILE)
	$(MAKE) -j -C obj_dir -f V$(TOPMOD).mk
	obj_dir/V$(TOPMOD) +trace

clean:
	rm -rf $(VDIRFB)/ $(SIMPROG)

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