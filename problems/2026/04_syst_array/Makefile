SIM ?= verilator

TOPLEVEL_LANG = verilog

VERILOG_SOURCES += \
	src/syst_arr/pe.sv			\
	src/syst_arr/sr.sv			\
	src/syst_arr/sa_core.sv		\
	src/syst_arr/sa_top.sv		\
	src/syst_arr/delay_line.sv  \
	src/credit_cnt.sv           \
	src/fifo.sv                 \
	src/sa_credited.sv

TOPLEVEL = sa_credited
MODULE   = sa_credited_tb

ifeq ($(SIM), verilator)
    EXTRA_ARGS += --trace --trace-fst --trace-structs
endif

include $(shell cocotb-config --makefiles)/Makefile.sim

