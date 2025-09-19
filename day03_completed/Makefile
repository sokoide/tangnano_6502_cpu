# Day 03 Completed: SystemVerilog Sequential Circuits Makefile

# Project configuration
PROJECT = sequential_circuits
TOP_MODULE = top
BOARD ?= 9k

# Tool paths
GWSH ?= gw_sh
PRG ?= programmer_cli

# Simulation tools
SIM ?= iverilog
VCD_VIEWER ?= gtkwave

# Source files
SOURCES = counter_8bit.sv pwm_generator.sv traffic_light.sv \
          shift_register.sv clock_divider.sv $(TOP_MODULE).sv
TESTBENCHES = tb_traffic_light.sv

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
	@echo "Building sequential circuits for Tang Nano $(BOARD)..."
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
sim: tb_traffic_light
	@echo "Running traffic light simulation..."
	./tb_traffic_light
	@if [ -f tb_traffic_light.vcd ]; then \
		echo "Waveform saved to tb_traffic_light.vcd"; \
		echo "View with: $(VCD_VIEWER) tb_traffic_light.vcd"; \
	fi

# Compile testbench
tb_traffic_light: $(TESTBENCHES) traffic_light.sv
	$(SIM) -g2012 -o $@ $^

# Run all tests
test: sim
	@echo "All sequential circuit tests completed"

# Create constraints file for Tang Nano 9K
tang_nano_9k.cst:
	@echo "Creating constraints file for Tang Nano 9K..."
	@echo 'IO_LOC "clk" 52;' > $@
	@echo 'IO_PORT "clk" PULL_MODE=UP;' >> $@
	@echo 'IO_LOC "rst_n" 3;' >> $@
	@echo 'IO_LOC "switches[0]" 4;' >> $@
	@echo 'IO_LOC "switches[1]" 5;' >> $@
	@echo 'IO_LOC "switches[2]" 6;' >> $@
	@echo 'IO_LOC "switches[3]" 7;' >> $@
	@echo 'IO_LOC "count_out[0]" 15;' >> $@
	@echo 'IO_LOC "count_out[1]" 16;' >> $@
	@echo 'IO_LOC "count_out[2]" 17;' >> $@
	@echo 'IO_LOC "count_out[3]" 18;' >> $@
	@echo 'IO_LOC "count_out[4]" 19;' >> $@
	@echo 'IO_LOC "count_out[5]" 20;' >> $@
	@echo 'IO_LOC "count_out[6]" 21;' >> $@
	@echo 'IO_LOC "count_out[7]" 22;' >> $@
	@echo 'IO_LOC "pwm_out" 10;' >> $@
	@echo 'IO_LOC "red_led" 11;' >> $@
	@echo 'IO_LOC "yellow_led" 12;' >> $@
	@echo 'IO_LOC "green_led" 13;' >> $@
	@echo 'IO_LOC "shift_serial_out" 14;' >> $@
	@echo 'IO_LOC "div_clk_out" 23;' >> $@

# Create constraints file for Tang Nano 20K
tang_nano_20k.cst:
	@echo "Creating constraints file for Tang Nano 20K..."
	@echo 'IO_LOC "clk" 4;' > $@
	@echo 'IO_PORT "clk" PULL_MODE=UP;' >> $@
	@echo 'IO_LOC "rst_n" 88;' >> $@
	@echo 'IO_LOC "switches[0]" 87;' >> $@
	@echo 'IO_LOC "switches[1]" 86;' >> $@
	@echo 'IO_LOC "switches[2]" 85;' >> $@
	@echo 'IO_LOC "switches[3]" 84;' >> $@
	@echo 'IO_LOC "count_out[0]" 79;' >> $@
	@echo 'IO_LOC "count_out[1]" 80;' >> $@
	@echo 'IO_LOC "count_out[2]" 81;' >> $@
	@echo 'IO_LOC "count_out[3]" 82;' >> $@
	@echo 'IO_LOC "count_out[4]" 83;' >> $@
	@echo 'IO_LOC "count_out[5]" 77;' >> $@
	@echo 'IO_LOC "count_out[6]" 76;' >> $@
	@echo 'IO_LOC "count_out[7]" 75;' >> $@
	@echo 'IO_LOC "pwm_out" 15;' >> $@
	@echo 'IO_LOC "red_led" 16;' >> $@
	@echo 'IO_LOC "yellow_led" 17;' >> $@
	@echo 'IO_LOC "green_led" 18;' >> $@
	@echo 'IO_LOC "shift_serial_out" 19;' >> $@
	@echo 'IO_LOC "div_clk_out" 20;' >> $@

# Clean build artifacts
clean:
	rm -f *.fs *.rpt *.log *.vcd tb_traffic_light
	rm -rf impl/

# Help
help:
	@echo "SystemVerilog Sequential Circuits Project"
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