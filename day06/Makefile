.DEFAULT_GOAL := all
PROJECT = day06
BOARD ?= 9k
BUILD_TCL = $(PROJECT)_build.tcl
SIM_TOP ?= tb_tft
LCD_SIM_DIR = build/$(BOARD)/$(SIM_TOP)
VERILATOR ?= verilator

BASE := $(if \
  $(wildcard /Applications/GowinIDE.app/Contents/Resources/Gowin_EDA/IDE/bin/gw_sh),/Applications/GowinIDE.app/Contents/Resources/Gowin_EDA,$(HOME)/Gowin)
GWSH := $(BASE)/IDE/bin/gw_sh
PRG  := $(BASE)/Programmer/bin/programmer_cli
$(info BASE='$(BASE)')
$(info GWSH='$(GWSH)')

COMMON_SRCS = top_core.sv lcd_demo.sv cpu.sv rom.sv \
	lcd/lcd.sv lcd/vram.sv lcd/font_rom.sv include/consts.svh

ifeq ($(BOARD),20k)
  DEVICE = GW2AR-18C
  GPRJ = day06_20k.gprj
  SRCS = top_20k.sv $(COMMON_SRCS)
else
  DEVICE = GW1NR-9C
  GPRJ = day06_9k.gprj
  SRCS = top_9k.sv $(COMMON_SRCS)
endif

.PHONY: all clean download help tools-check sim sim-build test test-cpu tools-check-sim sim-cpu sim-cpu-build
all: $(PROJECT)_$(BOARD).fs

$(PROJECT)_$(BOARD).fs: $(GPRJ) $(SRCS) $(wildcard *.cst src/*.cst)
	@$(MAKE) tools-check
	@echo "Building for Tang Nano $(BOARD)..."
	@rm -rf impl/gwsynthesis impl/pnr
	@printf '%s\n' \
		"open_project $(GPRJ)" \
		"set_option -verilog_std sysv2017" \
		"set_option -top_module top" \
		"set_option -use_sspi_as_gpio 1" \
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
	@rm -rf $(LCD_SIM_DIR)
	@mkdir -p $(LCD_SIM_DIR)
	@echo "[sim] Building TFT simulation with Verilator..."
	@$(VERILATOR) -Wall -Wno-fatal --sv --timing --trace --binary --top-module $(SIM_TOP) \
		-o V$(SIM_TOP) --Mdir $(LCD_SIM_DIR) --assert \
		$(if $(filter 20k,$(BOARD)),-DBOARD_20K,) \
		sim/Gowin_rPLL9_stub.sv \
		sim/gowin_rpll40_stub.sv \
	lcd/tb_tft.sv top_$(BOARD).sv lcd_demo.sv rom.sv \
	lcd/lcd.sv lcd/vram.sv lcd/font_rom.sv include/consts.svh include/opcodes.svh

# CPU logic simulation: separate per-board build directory
SIM_CPU_TOP ?= tb_cpu
CPU_SIM_DIR = build/$(BOARD)/$(SIM_CPU_TOP)

sim-cpu-build: tools-check-sim
	@echo "[sim] Building CPU logic simulation with Verilator..."
	@rm -rf $(CPU_SIM_DIR)
	@mkdir -p $(CPU_SIM_DIR)
	@$(VERILATOR) -Wall -Wno-fatal --sv --timing --trace --binary --top-module tb_cpu \
		-o Vtb_cpu --Mdir $(CPU_SIM_DIR) --assert \
		+define+TB_CPU_HAS_PC_ENABLE \
		sim/tb_cpu.sv cpu.sv

sim: sim-build sim-cpu-build
	@echo "[sim] Running TFT simulation..."
	@./$(LCD_SIM_DIR)/V$(SIM_TOP)
	@echo "[sim] Running CPU logic simulation..."
	@./$(CPU_SIM_DIR)/Vtb_cpu

# CPU logic test: alias for the existing sim-cpu build/run
test-cpu: sim-cpu-build
	@echo "[test] Running CPU logic simulation..."
	@./$(CPU_SIM_DIR)/Vtb_cpu

test: sim

clean:
	rm -rf impl/gwsynthesis impl/pnr
	rm -f *.fs *.rpt *.log *.vcd $(BUILD_TCL)
	rm -rf build obj_dir obj_tb_cpu

help:
	@echo "Targets: make | make download | make clean"
	@echo "         make sim | make test | make test-cpu"
	@echo "Vars: BOARD=9k|20k, GWSH=..., PRG=..."
