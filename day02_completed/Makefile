.DEFAULT_GOAL := all
PROJECT = day02
BOARD ?= 9k
BUILD_TCL = $(PROJECT)_build.tcl
SIM_DIR = build/$(BOARD)/$(SIM_TOP)
SIM_TOP = tb_alu_4bit
VERILATOR ?= verilator

BASE := $(if \
  $(wildcard /Applications/GowinIDE.app/Contents/Resources/Gowin_EDA/IDE/bin/gw_sh),/Applications/GowinIDE.app/Contents/Resources/Gowin_EDA,$(HOME)/Gowin)
GWSH := $(BASE)/IDE/bin/gw_sh
PRG  := $(BASE)/Programmer/bin/programmer_cli
$(info BASE='$(BASE)')
$(info GWSH='$(GWSH)')

SRCS = alu_4bit.sv

ifeq ($(BOARD),20k)
  DEVICE = GW2AR-18C
  GPRJ = day02_20k.gprj
  TOP_SRCS = top_20k.sv $(SRCS)
else
  DEVICE = GW1NR-9C
  GPRJ = day02_9k.gprj
  TOP_SRCS = top_9k.sv $(SRCS)
endif

.PHONY: all clean download help tools-check sim sim-build test tools-check-sim
all: $(PROJECT)_$(BOARD).fs

$(PROJECT)_$(BOARD).fs: $(GPRJ) $(TOP_SRCS) $(wildcard *.cst src/*.cst)
	@$(MAKE) tools-check
	@echo "Building for Tang Nano $(BOARD)..."
	@rm -rf impl/gwsynthesis impl/pnr
	@printf '%s\n' \
		"open_project $(GPRJ)" \
		"set_option -verilog_std sysv2017" \
		"set_option -top_module top" \
		"run all" \
		"exit" > $(BUILD_TCL)
	$(GWSH) $(BUILD_TCL)
	@rm -f $(BUILD_TCL)
	@fs=$$(ls -1 impl/pnr/*.fs 2>/dev/null | head -n 1); \
	if [ -n "$$fs" ]; then cp -f "$$fs" "$(PROJECT)_$(BOARD).fs"; else \
	  echo "[ERROR] Bitstream not found under impl/pnr/." >&2; exit 1; fi

download: $(PROJECT)_$(BOARD).fs
	@../scripts/program_fpga.sh "$(PRG)" "$(DEVICE)" "$(abspath $(PROJECT)_$(BOARD).fs)"

tools-check:
	@if [ -x "$(GWSH)" ] || command -v "$$(basename "$(GWSH)")" >/dev/null 2>&1; then : ; \
	else echo "[ERROR] gw_sh not found. Set GWSH=/path/to/gw_sh" >&2; exit 1; fi
	@if [ -x "$(PRG)" ] || command -v "$$(basename "$(PRG)")" >/dev/null 2>&1; then : ; \
	else echo "[ERROR] programmer_cli not found. Set PRG=/path/to/programmer_cli" >&2; exit 1; fi

tools-check-sim:
	@if command -v "$(VERILATOR)" >/dev/null 2>&1; then : ; \
	else echo "[ERROR] verilator not found. Install Verilator and re-run (e.g. macOS: brew install verilator)." >&2; exit 1; fi

sim-build: tools-check-sim
	@mkdir -p $(SIM_DIR)
	@echo "[sim] Building with Verilator..."
	@$(VERILATOR) -Wall -Wno-fatal --assert --sv --timing --trace --binary --Mdir $(SIM_DIR) \
		-o V$(SIM_TOP) \
		tb_alu_4bit.sv alu_4bit.sv

sim: sim-build
	@echo "[sim] Running..."
	@./$(SIM_DIR)/V$(SIM_TOP)

# README compatibility
test: sim

clean:
	rm -rf impl/gwsynthesis impl/pnr
	rm -f *.fs *.rpt *.log *.vcd $(BUILD_TCL)
	rm -rf build/ obj_dir/


help:
	@echo "Targets: make | make download | make clean"
	@echo "         make sim | make test"
	@echo "Vars: BOARD=9k|20k, GWSH=..., PRG=..."
