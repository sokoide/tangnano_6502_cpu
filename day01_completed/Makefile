# Day 01 Completed: LED Blink Project Makefile
# Tang Nano FPGA Development

# Project configuration
PROJECT = led_blink
TOP_MODULE = top
BOARD ?= 9k

# Tool paths (adjust as needed)
GWSH ?= gw_sh
PRG ?= programmer_cli

# Board-specific settings
ifeq ($(BOARD),20k)
    DEVICE = GW2AR-18C
    PACKAGE = GW2AR-LV18QN88C8/I7
    CST_FILE = tang_nano_20k.cst
else
    DEVICE = GW1NR-9C
    PACKAGE = GW1NR-LV9QN88PC6/I5
    CST_FILE = tang_nano_9k.cst
endif

# Build targets
.PHONY: all clean download help

all: $(PROJECT).fs

# Synthesis and Place & Route
$(PROJECT).fs: $(TOP_MODULE).sv $(CST_FILE)
	@echo "Building for Tang Nano $(BOARD)..."
	$(GWSH) -c "set_device -device_version $(DEVICE) $(PACKAGE); \
				add_file $(TOP_MODULE).sv; \
				add_file $(CST_FILE); \
				set_option -top_module $(TOP_MODULE); \
				run_synthesis; \
				run_pnr; \
				gen_bitstream"

# Download to FPGA
download: $(PROJECT).fs
	@echo "Programming Tang Nano $(BOARD)..."
	$(PRG) --device GW1NR-9C --operation_mode=externalFlash \
		   --external_flash_cfg_file=$(PROJECT).fs

# Clean build artifacts
clean:
	rm -f *.fs *.rpt *.log
	rm -rf impl/

# Help
help:
	@echo "Tang Nano LED Blink Project"
	@echo ""
	@echo "Targets:"
	@echo "  all       - Build FPGA bitstream"
	@echo "  download  - Program FPGA (SRAM mode)"
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