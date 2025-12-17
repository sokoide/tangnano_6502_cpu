.DEFAULT_GOAL := all

PROJECT := day10
PROGRAM ?= hello_world
PROGRAMS := hello_world counter_display scroll_text

BOARD ?= 9k

CONFIG = build.cfg
BOOT_PROGRAM ?= $(PROGRAM)
HEXFILE = $(BOOT_PROGRAM).hex
BINARY = $(PROGRAM).bin
OBJECT = $(PROGRAM).o
SV_INCLUDE = include/boot_program.sv
BUILD_TCL = $(PROJECT)_build.tcl
SIM_TOP ?= tb_tft
VERILATOR ?= verilator

CA65 ?= ca65
LD65 ?= ld65
SREC ?= srec_cat

BASE := $(if \
  $(wildcard /Applications/GowinIDE.app/Contents/Resources/Gowin_EDA/IDE/bin/gw_sh),/Applications/GowinIDE.app/Contents/Resources/Gowin_EDA,$(HOME)/Gowin)
GWSH := $(BASE)/IDE/bin/gw_sh
PRG  := $(BASE)/Programmer/bin/programmer_cli
$(info BASE='$(BASE)')
$(info GWSH='$(GWSH)')

ifeq ($(BOARD),20k)
  DEVICE = GW2AR-18C
  GPRJ = hw_20k.gprj
  TOP_WRAPPER = top_20k.sv
  SIM_DEFS := -DBOARD_20K
else
  DEVICE = GW1NR-9C
  GPRJ = hw_9k.gprj
  TOP_WRAPPER = top_9k.sv
  SIM_DEFS :=
endif

.PHONY: all include clean build download sim sim-build test tools-check tools-check-sim help

all: $(PROGRAMS:%=%.hex)

$(PROGRAMS:%=%.o): %.o: %.s
	$(CA65) -t none -o $@ $<

$(PROGRAMS:%=%.bin): %.bin: %.o
	$(LD65) -C $(CONFIG) -o $@ $<

$(PROGRAMS:%=%.hex): %.hex: %.bin
	$(SREC) $< -binary -offset 0x0200 -o $@ -intel

include: $(HEXFILE)
	@mkdir -p include
	python3 hex_to_sv.py $(HEXFILE) > $(SV_INCLUDE)

clean:
	rm -f $(PROGRAMS:%=%.o) $(PROGRAMS:%=%.bin) $(PROGRAMS:%=%.hex)
	rm -f $(SV_INCLUDE)
	rm -f *.fs $(PROJECT).fs *.rpt *.log *.vcd $(BUILD_TCL)
	rm -rf obj_dir/

$(PROJECT).fs: $(GPRJ) tools-check include
	@echo "Building for Tang Nano $(BOARD)..."
	@printf '%s\n' \
		"open_project $(GPRJ)" \
		"set_option -verilog_std sysv2017" \
		"set_option -use_sspi_as_gpio 1" \
		"set_option -top_module top" \
		"run all" \
		"exit" > $(BUILD_TCL)
	$(GWSH) $(BUILD_TCL)
	@fs=$$(ls -1 impl/pnr/*.fs 2>/dev/null | head -n 1); \
	if [ -n "$$fs" ]; then cp -f "$$fs" "$(PROJECT).fs"; else \
	  echo "[ERROR] Bitstream not found under impl/pnr/." >&2; exit 1; fi

build: $(PROJECT).fs

download: $(PROJECT).fs
	@echo "Programming Tang Nano $(BOARD)..."
	@fs="$(abspath $(PROJECT).fs)"; \
	tmp="$$(mktemp -t gowin_programmer.XXXXXX)"; \
	"$(PRG)" --device "$(DEVICE)" --fsFile "$$fs" --operation_index 2 >"$$tmp" 2>&1; \
	rc="$$?"; \
	cat "$$tmp"; \
	if grep -q "Error:" "$$tmp"; then rm -f "$$tmp"; exit "$$rc"; fi; \
	if grep -q "Finished\." "$$tmp"; then rm -f "$$tmp"; exit 0; fi; \
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
	else echo "[ERROR] verilator not found. Install Verilator and re-run." >&2; exit 1; fi

sim-build: include tools-check-sim
	@echo "[sim] Building with Verilator..."
	@$(VERILATOR) -Wall -Wno-fatal --sv --timing --trace --binary --top-module $(SIM_TOP) $(SIM_DEFS) -DVERILATOR \
		-o V$(SIM_TOP) \
		sim/Gowin_rPLL9_stub.sv \
		tb_tft.sv $(TOP_WRAPPER) top_core.sv lcd.sv vram.sv font_rom.sv boot_rom.sv \
		memory_controller.sv memory_interface.sv include/consts.svh include/boot_program.sv \
		../day07_completed/simple_ram.sv ../day07_completed/stack_pointer.sv \
		../day08_completed/addressing_mode_calculator.sv ../day08_completed/cpu_control_unit.sv \
		../day08_completed/cpu_core.sv ../day08_completed/cpu_datapath.sv ../day08_completed/cpu_registers.sv \
		../day06_completed/cpu_alu.sv ../day06_completed/cpu_decoder.sv ../day06_completed/status_register.sv

sim: sim-build
	@echo "[sim] Running..."
	@./obj_dir/V$(SIM_TOP)

test: sim

help:
	@echo "Usage:"
	@echo "  make                 # build every assembly sample (.hex)"
	@echo "  make PROGRAM=<name>  # build a specific sample"
	@echo "  make include         # regenerate include/boot_program.sv"
	@echo "  make build BOARD=9k|20k    # synthesize the Tang Nano bitstream"
	@echo "  make download BOARD=9k|20k # program the Tang Nano SRAM"
	@echo "  make test            # run the Verilator smoke test"
	@echo "  make clean           # clean generated artifacts"
