SRCS= \
	include/consts.svh \
	include/boot_program.sv \
	include/cpu_ifo_auto_generated.sv \
	include/cpu_tasks.sv \
	src/top.sv \
	src/lcd.sv \
	src/ram.sv \
	src/cpu.sv \
	src/cpu_decoder.sv \
	src/cpu_alu.sv \
	src/cpu_memory.sv \
	src/gowin_sdpb/gowin_sdpb.v \
	src/gowin_sdpb/gowin_sdpb_vram.v \
	src/gowin_prom/gowin_prom_font.v

# src/gowin_rpll_9K/gowin_rpll9.v \
# src/gowin_rpll_9K/gowin_rpll40.v \

BOARD ?= 9k
PROJECT := lcd_cpu_bsram
BITSTREAM_BASE := $(PROJECT)_$(BOARD)
PROJ := $(BITSTREAM_BASE).gprj
export PROJ

#--------------------------------------------------
ifeq ($(origin DEVICE), undefined)
  ifeq ($(BOARD),9k)
    DEVICE := GW1NR-9C
  else ifeq ($(BOARD),20k)
    DEVICE := GW2AR-18C
  else
    $(error Unknown BOARD '$(BOARD)'; use 9k or 20k, or set DEVICE explicitly)
  endif
endif

# NOTE: don't use $(PWD) here because `make -C day99_completed ...` keeps PWD as the
# original shell directory on some systems. $(CURDIR) is the directory Make is operating in.
FS := $(CURDIR)/impl/pnr/$(BITSTREAM_BASE).fs

# Tool paths (override if installed elsewhere)
GOWIN_BASE := $(if \
  $(wildcard /Applications/GowinIDE.app/Contents/Resources/Gowin_EDA/IDE/bin/gw_sh),/Applications/GowinIDE.app/Contents/Resources/Gowin_EDA,$(HOME)/Gowin)
GWSH := $(GOWIN_BASE)/IDE/bin/gw_sh
PRG  := $(GOWIN_BASE)/Programmer/bin/programmer_cli
$(info GOWIN_BASE='$(GOWIN_BASE)')
$(info GWSH='$(GWSH)')

export PATH

all: $(FS)

.PHONY: all clean wave download help lint format format-check tools-check board-config
.PHONY: sim sim-build sim-ram sim-ram-build tools-check-sim

include/board_select.svh: board-config

board-config:
	@mkdir -p include
	@if [ "$(BOARD)" = "20k" ]; then \
	  printf '%s\n' '`ifndef BOARD_SELECT_SVH' '`define BOARD_SELECT_SVH' '`define BOARD_20K 1' '`endif' > include/board_select.svh; \
	else \
	  printf '%s\n' '`ifndef BOARD_SELECT_SVH' '`define BOARD_SELECT_SVH' '`endif' > include/board_select.svh; \
	fi

$(FS): $(SRCS) include/board_select.svh tools-check
	$(GWSH) proj.tcl

# operation_index
# /Applications/GowinIDE.app/Contents/Resources/Gowin_EDA/Programmer/bin/programmer_cli -h
#  --operation_index <int>, --run <int>, -r <int>
# 0: Read Device Codes;
# 1: Reprogram;
# 2: SRAM Program;
# 3: SRAM Read;
# 4: SRAM Program and Verify;
# 5: embFlash Erase,Program;
# ...
download: $(FS)
	# SRAM
	@fs="$(FS)"; \
	tmp="$$(mktemp -t gowin_programmer.XXXXXX)"; \
	"$(PRG)" --device "$(DEVICE)" --fsFile "$$fs" --operation_index 2 >"$$tmp" 2>&1; \
	rc="$$?"; \
	cat "$$tmp"; \
	if grep -q "Error:" "$$tmp"; then rm -f "$$tmp"; exit "$$rc"; fi; \
	if grep -q "Finished\\." "$$tmp"; then rm -f "$$tmp"; exit 0; fi; \
	rm -f "$$tmp"; \
	if [ "$$rc" -eq 0 ] || [ "$$rc" -eq 50 ] || [ "$$rc" -eq 17 ]; then exit 0; fi; \
	exit "$$rc"

wave:
	gtkwave ./waveform.vcd

clean:
	rm -rf obj_dir waveform.*

#--------------------------------------------------
# Helpers
#--------------------------------------------------
help:
	@echo "Targets:"
	@echo "  make                - Build FPGA bitstream ($(FS))"
	@echo "  make download       - Program Tang Nano SRAM (DEVICE=$(DEVICE))"
	@echo "  make clean          - Remove build artifacts"
	@echo "  make lint           - Verilator lint (excludes vendor IP)"
	@echo "  make format         - Verible format (in-place)"
	@echo "  make wave           - Open waveform.vcd in GTKWave"
	@echo "Variables:"
	@echo "  BOARD=9k|20k        - Select board (maps DEVICE if DEVICE unset)"
	@echo "  DEVICE=...          - Override explicit device code"
	@echo "Note: Also update lcd_cpu_bsram.gprj and src/top.sv for board switch."

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

#--------------------------------------------------
# Simulation (Verilator)
#--------------------------------------------------
VERILATOR ?= verilator
SIM_TOP ?= tb_vram_smoke

tools-check-sim:
	@if command -v "$(VERILATOR)" >/dev/null 2>&1; then : ; \
	else echo "[ERROR] verilator not found. Install Verilator and re-run (e.g. macOS: brew install verilator)." >&2; exit 1; fi

# Default: CPU -> VRAM smoke test (education-friendly)
SIM_SRCS := \
	src/tb_vram_smoke.sv \
	src/top.sv src/lcd.sv src/ram.sv \
	src/cpu.sv src/cpu_decoder.sv src/cpu_alu.sv src/cpu_memory.sv \
	sim/GSR.sv \
	sim/gowin_rpll9_stub.sv sim/gowin_rpll40_stub.sv \
	sim/gowin_prom_font_stub.sv \
	sim/Gowin_SDPB.sv sim/gowin_sdpb_vram_stub.sv

sim-build: include/board_select.svh tools-check-sim
	@echo "[sim] Building with Verilator (VRAM smoke test)..."
	@$(VERILATOR) -Wall -Wno-fatal --sv --timing --trace --binary --top-module $(SIM_TOP) \
		-Iinclude -Isrc \
		-o V$(SIM_TOP) \
		$(SIM_SRCS)

sim: sim-build
	@echo "[sim] Running..."
	@./obj_dir/V$(SIM_TOP)

# Optional: BSRAM (SDPB) smoke test using existing tb
SIM_RAM_TOP ?= tb_top
SIM_RAM_SRCS := \
	src/tb_top.sv \
	sim/GSR.sv \
	sim/Gowin_SDPB.sv

sim-ram-build: tools-check-sim
	@echo "[sim] Building with Verilator (SDPB smoke test)..."
	@$(VERILATOR) -Wall -Wno-fatal --sv --timing --trace --binary --top-module $(SIM_RAM_TOP) \
		-o V$(SIM_RAM_TOP) \
		$(SIM_RAM_SRCS)

sim-ram: sim-ram-build
	@echo "[sim] Running..."
	@./obj_dir/V$(SIM_RAM_TOP)

# Lint (exclude vendor IP and generated verilog outputs)
LINT_SRCS := $(filter-out src/gowin_% impl/pnr/%,$(SRCS))
lint:
	@if command -v verilator >/dev/null 2>&1; then \
	  echo "[lint] verilator --lint-only -Wall $(LINT_SRCS)"; \
	  verilator --lint-only -Wall $(LINT_SRCS); \
	else \
	  echo "[WARN] verilator not found. Install Verilator or skip lint."; \
	fi

# Format SystemVerilog (in-place) excluding vendor IP
FORMAT_FILES := $(shell find src include -type f \( -name '*.sv' -o -name '*.svh' \) ! -path 'src/gowin_*/*')
format:
	@if command -v verible-verilog-format >/dev/null 2>&1; then \
	  verible-verilog-format --inplace $(FORMAT_FILES); \
	else \
	  echo "[WARN] verible-verilog-format not found. Install Verible or skip format."; \
	fi
