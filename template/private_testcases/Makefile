# --- BIT-TRIX FINAL SUBMISSION MAKEFILE ---
SIM = verilator
TOPLEVEL_LANG = verilog

# Point to your top module and python testbench name
TOPLEVEL = top
MODULE = test_latency

# This will automatically find your Verilog files whether they are in the 
# current template folder or a neighboring 'src' folder.
VERILOG_SOURCES = $(wildcard $(PWD)/*.v) $(wildcard $(PWD)/../src/*.v)

# Enable waveforms for the judges
EXTRA_ARGS += --trace

# Ignore minor linting warnings so the judges' compilation doesn't fail
VERILATOR_FLAGS += -Wall -Wno-fatal

# Import the Cocotb core build logic
include $(shell cocotb-config --makefiles)/Makefile.sim
