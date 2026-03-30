TOPLEVEL_LANG = verilog
SIM = verilator

TOPLEVEL = top
MODULE = test_latency   # your cocotb file name (without .py)

# Fixed the double variable assignment here:
VERILOG_SOURCES = $(wildcard $(PWD)/../src/*.v)

# 👇 THIS ENABLES WAVES
EXTRA_ARGS += --trace

# Optional but useful
VERILATOR_FLAGS += -Wall -Wno-fatal

include $(shell cocotb-config --makefiles)/Makefile.sim
