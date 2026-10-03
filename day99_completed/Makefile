SRCS= \
	include/consts.svh \
	include/boot_program.sv \
	include/cpu_ifo_auto_generated.svh \
	src/top_core.sv \
	src/platform_clocks.sv \
	src/reset_sync.sv \
	src/lcd.sv \
	src/ram.sv \
	src/cpu.sv \
	src/cpu_decoder.sv \
	src/cpu_alu.sv \
	src/cpu_memory.sv \
	src/gowin_sdpb/gowin_sdpb.v \
	src/gowin_sdpb/gowin_sdpb_vram.v \
	src/gowin_prom/gowin_prom_font.v \
	include/consts_pkg.sv include/cpu_pkg.sv \
	src/cpu/cpu_types_pkg.sv src/cpu/cpu_fsm_next_pkg.sv

# src/gowin_rpll_9K/gowin_rpll9.v \
# src/gowin_rpll_9K/gowin_rpll40.v \

BOARD ?= 9k

# Boot program embedded into the bitstream: examples/<PROG>.s. Switch it with
# `make prog PROG=<name>` (regenerates include/boot_program.sv), or
# `make prog-download PROG=<name>` to also rebuild the bitstream and program
# the board.
PROG ?= simple5
EMBEDDED_PROG := $(shell sed -n 's|^// source: ||p' include/boot_program.sv 2>/dev/null)

PROJECT := day99
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

.PHONY: all clean wave download help lint format format-check tools-check
.PHONY: sim sim-build sim-ram sim-ram-build tools-check-sim
.PHONY: prog prog-download

ifeq ($(BOARD),20k)
  TOP_WRAPPER := src/top_20k.sv
  SIM_DEFS := -DBOARD_20K
else
  TOP_WRAPPER := src/top_9k.sv
  SIM_DEFS :=
endif

$(FS): $(SRCS) $(TOP_WRAPPER) $(PROJ) proj.tcl $(wildcard *.cst src/*.cst *.sdc src/*.sdc)
	@$(MAKE) tools-check
	@rm -rf impl/gwsynthesis impl/pnr
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
	@../scripts/program_fpga.sh "$(PRG)" "$(DEVICE)" "$(abspath $(FS))"

# Rebuild include/boot_program.sv from examples/$(PROG).s. The FPGA bitstream
# target $(FS) already depends on boot_program.sv, so a later `make` / `make
# download` picks the new program up automatically.
prog:
	@$(MAKE) -C examples PROG=$(PROG) sv

prog-download: prog
	$(MAKE) BOARD=$(BOARD) download

wave:
	gtkwave ./waveform.vcd

clean:
	$(MAKE) -C examples clean
	rm -rf build obj_dir waveform.* impl/gwsynthesis impl/pnr

#--------------------------------------------------
# Helpers
#--------------------------------------------------
help:
	@echo "Targets:"
	@echo "  make                - Build FPGA bitstream ($(FS))"
	@echo "  make download       - Program Tang Nano SRAM (DEVICE=$(DEVICE))"
	@echo "  make prog           - Rebuild include/boot_program.sv from examples/$(PROG).s"
	@echo "  make prog-download  - prog + download (switch boot program and program the board)"
	@echo "  make clean          - Remove build artifacts"
	@echo "  make lint           - Verilator lint (excludes vendor IP)"
	@echo "  make format         - Verible format (in-place)"
	@echo "  make wave           - Open waveform.vcd in GTKWave"
	@echo "Variables:"
	@echo "  BOARD=9k|20k        - Select board (maps DEVICE if DEVICE unset)"
	@echo "  DEVICE=...          - Override explicit device code"
	@echo "  PROG=<name>         - Boot program (examples/<name>.s; embedded now: $(EMBEDDED_PROG))"
	@echo "Switch the sample program:"
	@echo "  make prog-download PROG=simple   # pick examples/simple.s, rebuild bitstream, program board"
	@echo "  make prog PROG=simple            # regenerate boot_program.sv only (no build/download)"
	@echo "  make help                        # show the program embedded now (PROG=<name>: ...)"
	@echo "Note: Board selection is encoded in the per-board .gprj (top_9k/top_20k wrapper)."

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
SIM_DIR = build/$(BOARD)/$(SIM_TOP)


tools-check-sim:
	@if command -v "$(VERILATOR)" >/dev/null 2>&1; then : ; \
	else echo "[ERROR] verilator not found. Install Verilator and re-run (e.g. macOS: brew install verilator)." >&2; exit 1; fi

# Default: CPU -> VRAM smoke test (education-friendly)
SIM_SRCS := \
	src/tb_vram_smoke.sv \
	$(TOP_WRAPPER) src/top_core.sv src/lcd.sv src/ram.sv \
	src/platform_clocks.sv src/reset_sync.sv \
	src/cpu.sv src/cpu_decoder.sv src/cpu_alu.sv src/cpu_memory.sv \
	sim/GSR.sv \
	sim/gowin_prom_font_stub.sv \
	sim/gowin_sdpb_vram_stub.sv

sim-build: tools-check-sim
	@mkdir -p $(SIM_DIR)
	@echo "[sim] Building with Verilator (VRAM smoke test)..."
	@$(VERILATOR) -Wall -Wno-fatal --assert --sv --timing --trace --binary --top-module $(SIM_TOP) $(SIM_DEFS) \
		--Mdir $(SIM_DIR) \
		-Iinclude -Isrc \
		-o V$(SIM_TOP) \
		$(SIM_SRCS)

sim: sim-build
	@echo "[sim] Running..."
	@./$(SIM_DIR)/V$(SIM_TOP)

.PHONY: test test-cpu-regression test-cpu-contract test-alu
test: test-cpu-regression test-cpu-contract test-simple5 test-diag-simple5 test-alu test-ram test-font test-lcd test-clock test-system sim

.PHONY: test-simple5
test-simple5: tools-check-sim
	@mkdir -p build/$(BOARD)/tb_simple5_sweep
	$(VERILATOR) --binary --timing --assert -Wno-fatal -Iinclude -Isrc \
		--Mdir build/$(BOARD)/tb_simple5_sweep --top-module tb_simple5_sweep \
		src/cpu.sv src/ram.sv src/tb_simple5_sweep.sv \
		src/gowin_sdpb/gowin_sdpb.v src/gowin_sdpb/gowin_sdpb_vram.v $(PRIMITIVE_MODEL)
	./build/$(BOARD)/tb_simple5_sweep/Vtb_simple5_sweep
	./build/$(BOARD)/tb_simple5_sweep/Vtb_simple5_sweep +poison_live_read

.PHONY: test-diag-simple5
test-diag-simple5: tools-check-sim
	@mkdir -p build/$(BOARD)/tb_diag_simple5
	$(VERILATOR) --binary --timing --assert -Wno-fatal -Iinclude -Isrc \
		--Mdir build/$(BOARD)/tb_diag_simple5 --top-module tb_diag_simple5 \
		src/cpu.sv src/tb_diag_simple5.sv
	./build/$(BOARD)/tb_diag_simple5/Vtb_diag_simple5

# This uses the currently embedded program and the actual P&R netlist.
# Keep it explicit: gate simulation is much slower than RTL regression.
.PHONY: test-simple5-netlist
test-simple5-netlist: $(FS) tools-check-sim
	@test "$(EMBEDDED_PROG)" = simple5.s || \
		{ echo "Run make prog PROG=simple5 before the netlist test" >&2; exit 1; }
	python3 utils/test_simple5_netlist.py --netlist impl/pnr/$(BITSTREAM_BASE).vo \
		--primitives $(PRIMITIVE_MODEL) --output-dir build/$(BOARD)/simple5-netlist \
		--verilator $(VERILATOR)

test-cpu-contract: tools-check-sim
	@mkdir -p build/$(BOARD)/tb_cpu_contract
	$(VERILATOR) --binary --timing --assert -Wno-fatal -Iinclude -Isrc \
		--Mdir build/$(BOARD)/tb_cpu_contract --top-module tb_cpu_contract \
		src/cpu.sv src/tb_cpu_contract.sv
	./build/$(BOARD)/tb_cpu_contract/Vtb_cpu_contract

test-cpu-regression: tools-check-sim
	@mkdir -p build/$(BOARD)/tb_cpu_regression
	$(VERILATOR) --binary --timing --assert -Wno-fatal -Iinclude -Isrc \
		--Mdir build/$(BOARD)/tb_cpu_regression --top-module tb_cpu_regression \
		src/cpu.sv src/tb_cpu_regression.sv
	./build/$(BOARD)/tb_cpu_regression/Vtb_cpu_regression

test-alu: tools-check-sim
	@mkdir -p build/$(BOARD)/tb_alu_regression
	$(VERILATOR) --binary --timing --assert -Wno-fatal -Iinclude -Isrc \
		--Mdir build/$(BOARD)/tb_alu_regression --top-module tb_alu_regression \
		src/cpu_alu.sv src/tb_alu_regression.sv
	./build/$(BOARD)/tb_alu_regression/Vtb_alu_regression

# Contract tests exercise the active design and vendor models separately.
CONTRACT_TARGETS := test-ram test-font test-lcd test-clock test-system
PRIMITIVE_MODEL := deps/$(if $(filter 20k,$(BOARD)),gw2a,gw1n)/prim_sim.v
.PHONY: $(CONTRACT_TARGETS)
.PHONY: test-reset
test-reset: test-system
test-ram: TEST_TOP = tb_ram_contract
test-font: TEST_TOP = tb_font_contract
test-lcd: TEST_TOP = tb_lcd_pipeline
test-clock: TEST_TOP = tb_clock_reset
test-system: TEST_TOP = tb_top_reset
TEST_SRCS_tb_ram_contract := src/tb_ram_contract.sv src/ram.sv \
	src/gowin_sdpb/gowin_sdpb.v src/gowin_sdpb/gowin_sdpb_vram.v $(PRIMITIVE_MODEL)
TEST_SRCS_tb_font_contract := src/tb_font_contract.sv src/gowin_prom/gowin_prom_font.v $(PRIMITIVE_MODEL)
TEST_SRCS_tb_lcd_pipeline := src/tb_lcd_pipeline.sv src/ram.sv src/lcd.sv sim/gowin_prom_font_stub.sv
TEST_SRCS_tb_clock_reset := src/tb_clock_reset.sv src/platform_clocks.sv src/reset_sync.sv
TEST_SRCS_tb_top_reset := src/tb_top_reset.sv src/top_core.sv src/cpu.sv src/ram.sv src/lcd.sv \
	src/platform_clocks.sv src/reset_sync.sv sim/gowin_prom_font_stub.sv

$(CONTRACT_TARGETS): tools-check-sim
	@mkdir -p build/$(BOARD)/$(TEST_TOP)
	$(VERILATOR) --binary --timing --assert -Wno-fatal $(SIM_DEFS) -Iinclude -Isrc \
		--Mdir build/$(BOARD)/$(TEST_TOP) --top-module $(TEST_TOP) $(TEST_SRCS_$(TEST_TOP))
	@if [ "$(TEST_TOP)" = tb_lcd_pipeline ]; then \
		for phase in 0 7 31; do ./build/$(BOARD)/$(TEST_TOP)/V$(TEST_TOP) +phase=$$phase || exit 1; done; \
	else ./build/$(BOARD)/$(TEST_TOP)/V$(TEST_TOP); fi

sim-ram sim-ram-build: test-ram

# Lint (exclude vendor IP and generated verilog outputs)
LINT_SRCS := $(TOP_WRAPPER) src/top_core.sv src/platform_clocks.sv src/reset_sync.sv \
	src/lcd.sv src/ram.sv src/cpu.sv sim/gowin_prom_font_stub.sv
lint: tools-check-sim
	$(VERILATOR) --lint-only --timing --sv -Wall -Wno-fatal --top-module top \
		$(SIM_DEFS) -Iinclude -Isrc $(LINT_SRCS)

# Format SystemVerilog (in-place) excluding vendor IP
FORMAT_FILES := $(shell find src include -type f -name '*.sv' ! -path 'src/gowin_*/*' ! -path 'src/cpu/legacy/*' ! -name boot_program.sv ! -name cpu_ifo_auto_generated.svh)
FORMAT_FILES += include/consts.svh
format:
	@if command -v verible-verilog-format >/dev/null 2>&1; then \
	  verible-verilog-format --inplace $(FORMAT_FILES); \
	else \
	  echo "[WARN] verible-verilog-format not found. Install Verible or skip format."; \
	fi
