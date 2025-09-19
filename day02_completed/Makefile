# Day 02 Completed: SystemVerilog Combinational Circuits Makefile

# Project configuration
PROJECT = combinational_circuits
TOP_MODULE = top
BOARD ?= 9k

# Tool paths
GWSH ?= gw_sh
PRG ?= programmer_cli

# Simulation tools
SIM ?= iverilog
VCD_VIEWER ?= gtkwave

# Source files
SOURCES = seven_seg_decoder.sv alu_4bit.sv mux_8to1.sv $(TOP_MODULE).sv
TESTBENCHES = tb_alu_4bit.sv

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
.PHONY: all clean download sim test help

all: $(PROJECT).fs

# Synthesis and Place & Route
$(PROJECT).fs: $(SOURCES) $(CST_FILE)
	@echo "Building combinational circuits for Tang Nano $(BOARD)..."
	$(GWSH) -c "set_device -device_version $(DEVICE) $(PACKAGE); \
				$(foreach src,$(SOURCES),add_file $(src);) \
				add_file $(CST_FILE); \
				set_option -top_module $(TOP_MODULE); \
				run_synthesis; \
				run_pnr; \
				gen_bitstream"

# Download to FPGA
download: $(PROJECT).fs
	@echo "Programming Tang Nano $(BOARD)..."
	$(PRG) --device $(DEVICE) --operation_mode=externalFlash \
		   --external_flash_cfg_file=$(PROJECT).fs

# Simulation
sim: tb_alu_4bit
	@echo "Running ALU simulation..."
	./tb_alu_4bit
	@if [ -f tb_alu_4bit.vcd ]; then \
		echo "Waveform saved to tb_alu_4bit.vcd"; \
		echo "View with: $(VCD_VIEWER) tb_alu_4bit.vcd"; \
	fi

# Compile testbench
tb_alu_4bit: $(TESTBENCHES) alu_4bit.sv
	$(SIM) -g2012 -o $@ $^

# Run all tests
test: sim
	@echo "All tests completed"

# Create constraints file for Tang Nano 9K
tang_nano_9k.cst:
	@echo "Creating constraints file for Tang Nano 9K..."
	@echo 'IO_LOC "clk" 52;' > $@
	@echo 'IO_PORT "clk" PULL_MODE=UP;' >> $@
	@echo 'IO_LOC "switches[0]" 3;' >> $@
	@echo 'IO_LOC "switches[1]" 4;' >> $@
	@echo 'IO_LOC "switches[2]" 5;' >> $@
	@echo 'IO_LOC "switches[3]" 6;' >> $@
	@echo 'IO_LOC "segments[0]" 25;' >> $@
	@echo 'IO_LOC "segments[1]" 26;' >> $@
	@echo 'IO_LOC "segments[2]" 27;' >> $@
	@echo 'IO_LOC "segments[3]" 28;' >> $@
	@echo 'IO_LOC "segments[4]" 29;' >> $@
	@echo 'IO_LOC "segments[5]" 30;' >> $@
	@echo 'IO_LOC "segments[6]" 31;' >> $@
	@echo 'IO_LOC "led_zero" 10;' >> $@
	@echo 'IO_LOC "led_carry" 11;' >> $@
	@echo 'IO_LOC "mux_out" 12;' >> $@

# Create constraints file for Tang Nano 20K
tang_nano_20k.cst:
	@echo "Creating constraints file for Tang Nano 20K..."
	@echo 'IO_LOC "clk" 4;' > $@
	@echo 'IO_PORT "clk" PULL_MODE=UP;' >> $@
	@echo 'IO_LOC "switches[0]" 88;' >> $@
	@echo 'IO_LOC "switches[1]" 87;' >> $@
	@echo 'IO_LOC "switches[2]" 86;' >> $@
	@echo 'IO_LOC "switches[3]" 85;' >> $@
	@echo 'IO_LOC "segments[0]" 79;' >> $@
	@echo 'IO_LOC "segments[1]" 80;' >> $@
	@echo 'IO_LOC "segments[2]" 81;' >> $@
	@echo 'IO_LOC "segments[3]" 82;' >> $@
	@echo 'IO_LOC "segments[4]" 83;' >> $@
	@echo 'IO_LOC "segments[5]" 84;' >> $@
	@echo 'IO_LOC "segments[6]" 77;' >> $@
	@echo 'IO_LOC "led_zero" 15;' >> $@
	@echo 'IO_LOC "led_carry" 16;' >> $@
	@echo 'IO_LOC "mux_out" 17;' >> $@

# Clean build artifacts
clean:
	rm -f *.fs *.rpt *.log *.vcd tb_alu_4bit
	rm -rf impl/

# Help
help:
	@echo "SystemVerilog Combinational Circuits Project"
	@echo ""
	@echo "Targets:"
	@echo "  all       - Build FPGA bitstream"
	@echo "  download  - Program FPGA"
	@echo "  sim       - Run simulation"
	@echo "  test      - Run all tests"
	@echo "  clean     - Remove build artifacts"
	@echo "  help      - Show this help"
	@echo ""
	@echo "Variables:"
	@echo "  BOARD     - Target board: 9k (default) or 20k"
	@echo "  SIM       - Simulator: iverilog (default)"
	@echo ""
	@echo "Examples:"
	@echo "  make test             # Run simulation tests"
	@echo "  make BOARD=9k download # Build and program Tang Nano 9K"