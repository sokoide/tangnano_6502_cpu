.DEFAULT_GOAL := all
PROJECT = day08
BOARD ?= 9k
BUILD_TCL = $(PROJECT)_build.tcl
SIM_TOP ?= tb_cpu_core
VERILATOR ?= verilator

BASE := $(if \
  $(wildcard /Applications/GowinIDE.app/Contents/Resources/Gowin_EDA/IDE/bin/gw_sh),/Applications/GowinIDE.app/Contents/Resources/Gowin_EDA,$(HOME)/Gowin)
GWSH := $(BASE)/IDE/bin/gw_sh
PRG  := $(BASE)/Programmer/bin/programmer_cli
$(info BASE='$(BASE)')
$(info GWSH='$(GWSH)')

ifeq ($(BOARD),20k)
  DEVICE = GW2AR-18C
  GPRJ = hw_20k.gprj
else
  DEVICE = GW1NR-9C
  GPRJ = hw_9k.gprj
endif

.PHONY: all clean download help tools-check sim sim-build test tools-check-sim
all: $(PROJECT).fs

$(PROJECT).fs: $(GPRJ) tools-check
	@echo "Building for Tang Nano $(BOARD)..."
	@printf '%s\n' \
		"open_project $(GPRJ)" \
		"set_option -verilog_std sysv2017" \
		"set_option -top_module top" \
		"run all" \
		"exit" > $(BUILD_TCL)
	$(GWSH) $(BUILD_TCL)
	@fs=$$(ls -1 impl/pnr/*.fs 2>/dev/null | head -n 1); \
	if [ -n "$$fs" ]; then cp -f "$$fs" "$(PROJECT).fs"; else \
	  echo "[ERROR] Bitstream not found under impl/pnr/." >&2; exit 1; fi

download: $(PROJECT).fs
	@echo "Programming Tang Nano $(BOARD)..."
	@fs="$(abspath $(PROJECT).fs)"; \
	tmp="$$(mktemp -t gowin_programmer.XXXXXX)"; \
	"$(PRG)" --device "$(DEVICE)" --fsFile "$$fs" --operation_index 2 >"$$tmp" 2>&1; \
	rc="$$?"; \
	cat "$$tmp"; \
	if grep -q "Error:" "$$tmp"; then rm -f "$$tmp"; exit "$$rc"; fi; \
	if grep -q "Finished\\." "$$tmp"; then rm -f "$$tmp"; exit 0; fi; \
	rm -f "$$tmp"; \
	if [ "$$rc" -eq 0 ] || [ "$$rc" -eq 50 ] || [ "$$rc" -eq 17 ]; then exit 0; fi; \
	exit "$$rc"

tools-check:
	@if [ -x "$(GWSH)" ] || command -v "$$(basename "$(GWSH)")" >/dev/null 2>&1; then : ; \
	else echo "[ERROR] gw_sh not found. Set GWSH=/path/to/gw_sh" >&2; exit 1; fi
	@if [ -x "$(PRG)" ] || command -v "$$(basename "$(PRG)")" >/dev/null 2>&1; then : ; \
	else echo "[ERROR] programmer_cli not found. Set PRG=/path/to/programmer_cli" >&2; exit 1; fi

tools-check-sim:
	@if command -v "$(VERILATOR)" >/dev/null 2>&1; then : ; \
	else echo "[ERROR] verilator not found. Install Verilator and re-run (e.g. macOS: brew install verilator)." >&2; exit 1; fi

sim-build: tools-check-sim
	@echo "[sim] Building with Verilator..."
	@$(VERILATOR) -Wall -Wno-fatal --sv --timing --trace --binary --top-module $(SIM_TOP) \
		-o V$(SIM_TOP) \
		tb_cpu_core.sv \
		top.sv cpu_core.sv cpu_control_unit.sv cpu_datapath.sv cpu_registers.sv test_rom.sv \
		addressing_mode_calculator.sv \
		../day06_completed/cpu_alu.sv ../day06_completed/cpu_decoder.sv ../day06_completed/status_register.sv \
		../day07_completed/memory_controller.sv ../day07_completed/memory_interface.sv ../day07_completed/stack_pointer.sv \
		../day07_completed/simple_ram.sv

sim: sim-build
	@echo "[sim] Running..."
	@./obj_dir/V$(SIM_TOP)

test: sim

clean:
	rm -f *.fs *.rpt *.log *.vcd $(BUILD_TCL)
	rm -rf obj_dir/

help:
	@echo "Targets: make | make download | make clean"
	@echo "         make sim | make test"
	@echo "Vars: BOARD=9k|20k, GWSH=..., PRG=..."
