# Day 01 Completed: LED Blink Project Makefile
# Tang Nano FPGA Development

# Project configuration
PROJECT = led_blink
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
    GPRJ = led_blink_20k.gprj
    SRCS = top_20k.sv
else
    DEVICE = GW1NR-9C
    GPRJ = led_blink_9k.gprj
    SRCS = top_9k.sv
endif

# Build targets
.PHONY: all clean download help tools-check

all: $(PROJECT).fs

# Synthesis and Place & Route
$(PROJECT).fs: $(GPRJ) $(SRCS)
	@$(MAKE) tools-check
	@echo "Building for Tang Nano $(BOARD)..."
	@printf '%s\n' \
		"open_project $(GPRJ)" \
		"run all" \
		"exit" > $(BUILD_TCL)
	$(GWSH) $(BUILD_TCL)
	@# Gowin emits bitstreams under impl/pnr/. Copy the first .fs we find to $(PROJECT).fs.
	@fs=$$(ls -1 impl/pnr/*.fs 2>/dev/null | head -n 1); \
	if [ -n "$$fs" ]; then \
	  cp -f "$$fs" "$(PROJECT).fs"; \
	else \
	  echo "[ERROR] Bitstream not found. Look under impl/pnr/ for a .fs output." >&2; \
	  exit 1; \
	fi

# Download to FPGA
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
	rm -f *.fs *.rpt *.log

	rm -f $(BUILD_TCL)

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
