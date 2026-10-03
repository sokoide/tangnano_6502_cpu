# Day 01 Completed: LED Blink Project Makefile
# Tang Nano FPGA Development

# Project configuration
PROJECT = day01
TOP_MODULE = top
BOARD ?= 9k
BUILD_TCL = $(PROJECT)_build.tcl

# Tool paths (adjust as needed)
BASE := $(if \
  $(wildcard /Applications/GowinIDE.app/Contents/Resources/Gowin_EDA/IDE/bin/gw_sh),/Applications/GowinIDE.app/Contents/Resources/Gowin_EDA,$(HOME)/Gowin)
GWSH := $(BASE)/IDE/bin/gw_sh
PRG  := $(BASE)/Programmer/bin/programmer_cli
$(info BASE='$(BASE)')
$(info GWSH='$(GWSH)')

ifeq ($(BOARD),20k)
    DEVICE = GW2AR-18C
    GPRJ = day01_20k.gprj
    SRCS = top_20k.sv
else
    DEVICE = GW1NR-9C
    GPRJ = day01_9k.gprj
    SRCS = top_9k.sv
endif

# Build targets
.PHONY: all clean download help tools-check test sim

all: $(PROJECT)_$(BOARD).fs

VERILATOR ?= verilator
SIM_DIR := build/$(BOARD)/tb_led
test sim:
	@mkdir -p $(SIM_DIR)
	$(VERILATOR) --binary --timing --assert -Wno-fatal --top-module tb_led \
		$(if $(filter 20k,$(BOARD)),-DBOARD_20K,) --Mdir $(SIM_DIR) tb_led.sv $(SRCS)
	./$(SIM_DIR)/Vtb_led

# Synthesis and Place & Route
$(PROJECT)_$(BOARD).fs: $(GPRJ) $(SRCS) $(wildcard *.cst src/*.cst)
	@$(MAKE) tools-check
	@echo "Building for Tang Nano $(BOARD) using $(GPRJ)..."
	@rm -rf impl/gwsynthesis impl/pnr
	@printf '%s\n' \
		"open_project $(GPRJ)" \
		"set_option -verilog_std sysv2017" \
		"run all" \
		"exit" > $(BUILD_TCL)
	$(GWSH) $(BUILD_TCL)
	@rm -f $(BUILD_TCL)
	@# Gowin emits bitstreams under impl/pnr/. Copy the first .fs we find to $(PROJECT)_$(BOARD).fs.
	@fs=$$(ls -1 impl/pnr/*.fs 2>/dev/null | head -n 1); \
	if [ -n "$$fs" ]; then \
	  cp -f "$$fs" "$(PROJECT)_$(BOARD).fs"; \
	else \
	  echo "[ERROR] Bitstream not found. Check impl/pnr/ for errors." >&2; \
	  exit 1; \
	fi

# Download to FPGA
download: $(PROJECT)_$(BOARD).fs
	@../scripts/program_fpga.sh "$(PRG)" "$(DEVICE)" "$(abspath $(PROJECT)_$(BOARD).fs)"

# Tool availability check (portable): accepts absolute path or PATH lookup
tools-check:
	@# Check gw_sh
	@if [ -x "$(GWSH)" ] || command -v "$$(basename "$(GWSH)")" >/dev/null 2>&1; then \
	  : ; \
	else \
	  echo "[ERROR] gw_sh not found. Set GWSH=/path/to/gw_sh" >&2; exit 1; \
	fi
	@# Check programmer_cli
	@if [ -x "$(PRG)" ] || command -v "$$(basename "$(PRG)")" >/dev/null 2>&1; then \
	  : ; \
	else \
	  echo "[ERROR] programmer_cli not found. Set PRG=/path/to/programmer_cli" >&2; exit 1; \
	fi

# Clean build artifacts
clean:
	rm -rf impl/gwsynthesis impl/pnr build $(PROJECT)_$(BOARD).fs *.rpt *.log $(BUILD_TCL)

# Help
help:
	@echo "Tang Nano LED Blink Project"
	@echo ""
	@echo "Targets:"
	@echo "  all       - Build FPGA bitstream"
	@echo "  download  - Program FPGA SRAM"
	@echo "  clean     - Remove build artifacts"
	@echo "  help      - Show this help"
	@echo ""
	@echo "Variables:"
	@echo "  BOARD     - Target board: 9k (default) or 20k"
	@echo "  GWSH      - Path to gw_sh tool"
	@echo "  PRG       - Path to programmer_cli tool"
	@echo ""
	@echo "Examples:"
	@echo "  make BOARD=9k download   # Build and program Tang Nano 9K"
	@echo "  make BOARD=20k download  # Build and program Tang Nano 20K"
