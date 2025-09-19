# Makefile for Day 08: Integrated 6502 CPU Core
# Tang Nano 9K/20K FPGA Build System

# Project configuration
PROJECT_NAME = day08_cpu_core
TOP_MODULE = top
DEVICE_9K = GW1NR-LV9QN88PC6/I5
DEVICE_20K = GW2A-LV18PG256C8/I7
FAMILY = GW1N

# Source files (all CPU components)
SOURCES = top.sv \
          cpu_core.sv \
          cpu_datapath.sv \
          cpu_control_unit.sv \
          cpu_registers.sv \
          test_rom.sv \
          ../day06_completed/cpu_alu.sv \
          ../day06_completed/cpu_decoder.sv \
          ../day06_completed/status_register.sv \
          ../day07_completed/memory_controller.sv \
          ../day07_completed/memory_interface.sv \
          ../day07_completed/stack_pointer.sv \
          ../day07_completed/simple_ram.sv \
          ../day05_completed/addressing_mode_calculator.sv

# Testbench files
TB_SOURCES = tb_cpu_core.sv \
             cpu_core.sv \
             cpu_datapath.sv \
             cpu_control_unit.sv \
             cpu_registers.sv \
             test_rom.sv \
             ../day06_completed/cpu_alu.sv \
             ../day06_completed/cpu_decoder.sv \
             ../day06_completed/status_register.sv \
             ../day07_completed/memory_controller.sv \
             ../day07_completed/memory_interface.sv \
             ../day07_completed/stack_pointer.sv \
             ../day07_completed/simple_ram.sv \
             ../day05_completed/addressing_mode_calculator.sv

# Constraint files
SDC_FILE = constraints.sdc
CST_FILE = pins.cst

# Build directories
BUILD_DIR = build
SIM_DIR = sim

# Default target
all: tang_nano_9k

# Tang Nano 9K build
tang_nano_9k: $(BUILD_DIR)/$(PROJECT_NAME)_9k.fs

$(BUILD_DIR)/$(PROJECT_NAME)_9k.fs: $(SOURCES) $(CST_FILE) $(SDC_FILE)
	@mkdir -p $(BUILD_DIR)
	gw_sh -tcl_cmd "create_project -name $(PROJECT_NAME)_9k -device $(DEVICE_9K) -family $(FAMILY) -force" \
	      -tcl_cmd "add_files $(SOURCES)" \
	      -tcl_cmd "add_files -type cst $(CST_FILE)" \
	      -tcl_cmd "add_files -type sdc $(SDC_FILE)" \
	      -tcl_cmd "set_property top $(TOP_MODULE)" \
	      -tcl_cmd "run_synthesis" \
	      -tcl_cmd "run_place_and_route" \
	      -tcl_cmd "run_bitstream -bit_file $(BUILD_DIR)/$(PROJECT_NAME)_9k.fs"

# Tang Nano 20K build
tang_nano_20k: $(BUILD_DIR)/$(PROJECT_NAME)_20k.fs

$(BUILD_DIR)/$(PROJECT_NAME)_20k.fs: $(SOURCES) $(CST_FILE) $(SDC_FILE)
	@mkdir -p $(BUILD_DIR)
	gw_sh -tcl_cmd "create_project -name $(PROJECT_NAME)_20k -device $(DEVICE_20K) -family GW2A -force" \
	      -tcl_cmd "add_files $(SOURCES)" \
	      -tcl_cmd "add_files -type cst $(CST_FILE)" \
	      -tcl_cmd "add_files -type sdc $(SDC_FILE)" \
	      -tcl_cmd "set_property top $(TOP_MODULE)" \
	      -tcl_cmd "run_synthesis" \
	      -tcl_cmd "run_place_and_route" \
	      -tcl_cmd "run_bitstream -bit_file $(BUILD_DIR)/$(PROJECT_NAME)_20k.fs"

# Simulation with iverilog
sim: $(SIM_DIR)/cpu_core_tb

$(SIM_DIR)/cpu_core_tb: $(TB_SOURCES)
	@mkdir -p $(SIM_DIR)
	iverilog -g2012 -o $(SIM_DIR)/cpu_core_tb $(TB_SOURCES)

# Run simulation
run_sim: sim
	cd $(SIM_DIR) && ./cpu_core_tb

# Synthesis check only
synth_check:
	@mkdir -p $(BUILD_DIR)
	gw_sh -tcl_cmd "create_project -name $(PROJECT_NAME)_check -device $(DEVICE_9K) -family $(FAMILY) -force" \
	      -tcl_cmd "add_files $(SOURCES)" \
	      -tcl_cmd "set_property top $(TOP_MODULE)" \
	      -tcl_cmd "run_synthesis"

# Program Tang Nano 9K
program_9k: $(BUILD_DIR)/$(PROJECT_NAME)_9k.fs
	openFPGALoader -b tangnano9k $(BUILD_DIR)/$(PROJECT_NAME)_9k.fs

# Program Tang Nano 20K
program_20k: $(BUILD_DIR)/$(PROJECT_NAME)_20k.fs
	openFPGALoader -b tangnano20k $(BUILD_DIR)/$(PROJECT_NAME)_20k.fs

# Create constraint files if they don't exist
constraints: $(CST_FILE) $(SDC_FILE)

$(CST_FILE):
	@echo "Creating comprehensive pin constraints file..."
	@echo "# Tang Nano Pin Constraints for 6502 CPU Core" > $(CST_FILE)
	@echo "# Clock input (27MHz crystal)" >> $(CST_FILE)
	@echo 'IO_LOC "clk" 52;' >> $(CST_FILE)
	@echo 'IO_PORT "clk" IO_TYPE=LVCMOS33 PULL_MODE=UP;' >> $(CST_FILE)
	@echo "" >> $(CST_FILE)
	@echo "# Reset button (active low)" >> $(CST_FILE)
	@echo 'IO_LOC "rst_n" 3;' >> $(CST_FILE)
	@echo 'IO_PORT "rst_n" IO_TYPE=LVCMOS18 PULL_MODE=UP;' >> $(CST_FILE)
	@echo "" >> $(CST_FILE)
	@echo "# DIP switches for CPU control" >> $(CST_FILE)
	@echo 'IO_LOC "switches[0]" 25;' >> $(CST_FILE)
	@echo 'IO_LOC "switches[1]" 26;' >> $(CST_FILE)
	@echo 'IO_LOC "switches[2]" 27;' >> $(CST_FILE)
	@echo 'IO_LOC "switches[3]" 28;' >> $(CST_FILE)
	@echo 'IO_PORT "switches[0]" IO_TYPE=LVCMOS18 PULL_MODE=UP;' >> $(CST_FILE)
	@echo 'IO_PORT "switches[1]" IO_TYPE=LVCMOS18 PULL_MODE=UP;' >> $(CST_FILE)
	@echo 'IO_PORT "switches[2]" IO_TYPE=LVCMOS18 PULL_MODE=UP;' >> $(CST_FILE)
	@echo 'IO_PORT "switches[3]" IO_TYPE=LVCMOS18 PULL_MODE=UP;' >> $(CST_FILE)
	@echo "" >> $(CST_FILE)
	@echo "# Debug LEDs for register outputs" >> $(CST_FILE)
	@echo 'IO_LOC "debug_reg_a[0]" 10;' >> $(CST_FILE)
	@echo 'IO_LOC "debug_reg_a[1]" 11;' >> $(CST_FILE)
	@echo 'IO_LOC "debug_reg_a[2]" 13;' >> $(CST_FILE)
	@echo 'IO_LOC "debug_reg_a[3]" 14;' >> $(CST_FILE)
	@echo 'IO_LOC "debug_reg_a[4]" 15;' >> $(CST_FILE)
	@echo 'IO_LOC "debug_reg_a[5]" 16;' >> $(CST_FILE)
	@echo 'IO_LOC "debug_reg_a[6]" 17;' >> $(CST_FILE)
	@echo 'IO_LOC "debug_reg_a[7]" 18;' >> $(CST_FILE)
	@echo 'IO_PORT "debug_reg_a[0]" IO_TYPE=LVCMOS18 DRIVE=8;' >> $(CST_FILE)
	@echo 'IO_PORT "debug_reg_a[1]" IO_TYPE=LVCMOS18 DRIVE=8;' >> $(CST_FILE)
	@echo 'IO_PORT "debug_reg_a[2]" IO_TYPE=LVCMOS18 DRIVE=8;' >> $(CST_FILE)
	@echo 'IO_PORT "debug_reg_a[3]" IO_TYPE=LVCMOS18 DRIVE=8;' >> $(CST_FILE)
	@echo 'IO_PORT "debug_reg_a[4]" IO_TYPE=LVCMOS18 DRIVE=8;' >> $(CST_FILE)
	@echo 'IO_PORT "debug_reg_a[5]" IO_TYPE=LVCMOS18 DRIVE=8;' >> $(CST_FILE)
	@echo 'IO_PORT "debug_reg_a[6]" IO_TYPE=LVCMOS18 DRIVE=8;' >> $(CST_FILE)
	@echo 'IO_PORT "debug_reg_a[7]" IO_TYPE=LVCMOS18 DRIVE=8;' >> $(CST_FILE)

$(SDC_FILE):
	@echo "Creating timing constraints file..."
	@echo "# Tang Nano Timing Constraints for 6502 CPU Core" > $(SDC_FILE)
	@echo "create_clock -period 37.037 [get_ports clk]" >> $(SDC_FILE)
	@echo "set_clock_uncertainty 0.5 [get_clocks]" >> $(SDC_FILE)
	@echo "set_input_delay -clock [get_clocks] -max 5 [all_inputs]" >> $(SDC_FILE)
	@echo "set_output_delay -clock [get_clocks] -max 5 [all_outputs]" >> $(SDC_FILE)
	@echo "" >> $(SDC_FILE)
	@echo "# CPU internal clock constraints" >> $(SDC_FILE)
	@echo "create_generated_clock -name cpu_clk_div3 -source [get_ports clk] -divide_by 8 [get_pins cpu_clk_div_reg[2]/Q]" >> $(SDC_FILE)
	@echo "create_generated_clock -name cpu_clk_div2 -source [get_ports clk] -divide_by 4 [get_pins cpu_clk_div_reg[1]/Q]" >> $(SDC_FILE)
	@echo "create_generated_clock -name cpu_clk_div1 -source [get_ports clk] -divide_by 2 [get_pins cpu_clk_div_reg[0]/Q]" >> $(SDC_FILE)

# Clean build files
clean:
	rm -rf $(BUILD_DIR) $(SIM_DIR)
	rm -f *.log *.rpt

# Clean all generated files
distclean: clean
	rm -f $(CST_FILE) $(SDC_FILE)

# Help
help:
	@echo "Available targets:"
	@echo "  all          - Build for Tang Nano 9K (default)"
	@echo "  tang_nano_9k - Build for Tang Nano 9K"
	@echo "  tang_nano_20k- Build for Tang Nano 20K"
	@echo "  sim          - Compile simulation"
	@echo "  run_sim      - Run CPU core simulation"
	@echo "  synth_check  - Synthesis check only"
	@echo "  program_9k   - Program Tang Nano 9K"
	@echo "  program_20k  - Program Tang Nano 20K"
	@echo "  constraints  - Generate constraint files"
	@echo "  clean        - Clean build files"
	@echo "  distclean    - Clean all generated files"
	@echo "  help         - Show this help"

.PHONY: all tang_nano_9k tang_nano_20k sim run_sim synth_check program_9k program_20k constraints clean distclean help