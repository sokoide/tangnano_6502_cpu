.DEFAULT_GOAL := all
PROJECT = day15
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

COMMON_SRCS = lcd_demo.sv boot_loader.sv rom.sv ram.sv cpu.sv \
	lcd/lcd.sv lcd/vram.sv lcd/font_rom.sv include/consts.svh include/opcodes.svh

ifeq ($(BOARD),20k)
  DEVICE = GW2AR-18C
  GPRJ = day15_20k.gprj
  SRCS = top_20k.sv $(COMMON_SRCS)
else
  DEVICE = GW1NR-9C
  GPRJ = day15_9k.gprj
  SRCS = top_9k.sv $(COMMON_SRCS)
endif

.PHONY: all clean download help tools-check sim sim-build test test-cpu test-lcd tools-check-sim
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
	@echo "[sim] Building with Verilator..."
	@$(VERILATOR) -Wall -Wno-fatal --sv --timing --trace --binary --top-module $(SIM_TOP) \
		-o V$(SIM_TOP) --Mdir $(LCD_SIM_DIR) --assert \
		$(if $(filter 20k,$(BOARD)),-DBOARD_20K,) \
		sim/Gowin_rPLL9_stub.sv \
		sim/gowin_rpll40_stub.sv \
	lcd/tb_tft.sv top_$(BOARD).sv lcd_demo.sv boot_loader.sv rom.sv ram.sv \
	lcd/lcd.sv lcd/vram.sv lcd/font_rom.sv include/consts.svh include/opcodes.svh

# CPU logic simulation: shared testbench from the starter workspace (day15/sim)
# Built in a fresh per-top build directory so it never clobbers the TFT sim build.
SIM_CPU_TOP ?= tb_cpu
CPU_SIM_DIR = build/$(BOARD)/$(SIM_CPU_TOP)
TB_CPU = ../day15/sim/tb_cpu.sv
TB_CPU_DEFINES =

test-cpu: tools-check-sim
	@echo "[test] Building CPU logic simulation with Verilator (--assert)..."
	@rm -rf $(CPU_SIM_DIR)
	@mkdir -p $(CPU_SIM_DIR)
	@$(VERILATOR) -Wall -Wno-fatal --sv --timing --trace --assert --binary --top-module $(SIM_CPU_TOP) \
		-o V$(SIM_CPU_TOP) --Mdir $(CPU_SIM_DIR) \
		$(TB_CPU_DEFINES) \
		$(TB_CPU) cpu.sv
	@echo "[test] Running CPU logic simulation..."
	@./$(CPU_SIM_DIR)/V$(SIM_CPU_TOP)

sim: sim-build
	@echo "[sim] Running..."
	@./$(LCD_SIM_DIR)/V$(SIM_TOP)

test-lcd: sim

test: test-cpu test-lcd

clean:
	rm -rf impl/gwsynthesis impl/pnr
	rm -f *.fs *.rpt *.log *.vcd $(BUILD_TCL)
	rm -rf build obj_dir $(CPU_SIM_DIR)

help:
	@echo "Targets: make | make download | make clean"
	@echo "         make sim | make test | make test-cpu | make test-lcd"
	@echo "Vars: BOARD=9k|20k, GWSH=..., PRG=..."

# The synchronous RAM integration is tested at full speed and with sparse enables.
.PHONY: test-sync test-sync-one test-manual-step
test: test-sync
test-sync:
	@for step in 1 4 16; do $(MAKE) test-sync-one STEP_PERIOD=$$step || exit 1; done
	@$(MAKE) test-manual-step
STEP_PERIOD ?= 1
SYNC_DEFS =
test-sync-one: tools-check-sim
	@mkdir -p build/$(BOARD)/sync-$(STEP_PERIOD)
	$(VERILATOR) --binary --timing --assert -Wno-fatal $(SYNC_DEFS) \
		--Mdir build/$(BOARD)/sync-$(STEP_PERIOD) --top-module tb_curriculum_sync \
		-GSTEP_PERIOD=$(STEP_PERIOD) ../sim/tb_curriculum_sync.sv cpu.sv ram.sv
	./build/$(BOARD)/sync-$(STEP_PERIOD)/Vtb_curriculum_sync
test-manual-step: tools-check-sim
	@mkdir -p build/$(BOARD)/manual-step
	$(VERILATOR) --binary --timing --assert -Wno-fatal $(SYNC_DEFS) \
		--Mdir build/$(BOARD)/manual-step --top-module tb_manual_step \
		../sim/tb_manual_step.sv cpu.sv ram.sv
	./build/$(BOARD)/manual-step/Vtb_manual_step

# Verify all pixels, cell boundaries, DE latency and two complete frame periods.
.PHONY: test-lcd-pipeline
test-lcd-pipeline: tools-check-sim
	@mkdir -p build/$(BOARD)/tb_lcd_pipeline
	$(VERILATOR) --binary --timing --assert -Wno-fatal --top-module tb_lcd_pipeline \
		--Mdir build/$(BOARD)/tb_lcd_pipeline sim/tb_lcd_pipeline.sv lcd/lcd.sv
	@./build/$(BOARD)/tb_lcd_pipeline/Vtb_lcd_pipeline
test: test-lcd-pipeline
