# Makefile for Day 10: Assembly Programming Examples
# Tang Nano 9K/20K FPGA Build System with Complete 6502 Development Environment

# Project configuration
PROJECT_NAME = day10_assembly_system
TOP_MODULE = top
DEVICE_9K = GW1NR-LV9QN88PC6/I5
DEVICE_20K = GW2A-LV18PG256C8/I7
FAMILY = GW1N

# Source files (Complete system)
SOURCES = top.sv \
          assembly_examples.sv \
          program_selector.sv \
          enhanced_lcd_display.sv \
          ../day09_completed/lcd_controller.sv \
          ../day08_completed/cpu_core.sv \
          ../day08_completed/cpu_datapath.sv \
          ../day08_completed/cpu_control_unit.sv \
          ../day08_completed/cpu_registers.sv \
          ../day06_completed/cpu_alu.sv \
          ../day06_completed/cpu_decoder.sv \
          ../day06_completed/status_register.sv \
          ../day07_completed/memory_controller.sv \
          ../day07_completed/memory_interface.sv \
          ../day07_completed/stack_pointer.sv \
          ../day07_completed/simple_ram.sv \
          ../day05_completed/addressing_mode_calculator.sv

# Testbench files
TB_SOURCES = tb_assembly_system.sv \
             assembly_examples.sv \
             program_selector.sv \
             enhanced_lcd_display.sv \
             ../day09_completed/lcd_controller.sv \
             ../day08_completed/cpu_core.sv \
             ../day08_completed/cpu_datapath.sv \
             ../day08_completed/cpu_control_unit.sv \
             ../day08_completed/cpu_registers.sv \
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
sim: $(SIM_DIR)/assembly_system_tb

$(SIM_DIR)/assembly_system_tb: $(TB_SOURCES)
	@mkdir -p $(SIM_DIR)
	iverilog -g2012 -o $(SIM_DIR)/assembly_system_tb $(TB_SOURCES)

# Run simulation
run_sim: sim
	cd $(SIM_DIR) && ./assembly_system_tb

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
	@echo "Creating comprehensive pin constraints file for assembly system..."
	@echo "# Tang Nano Pin Constraints for Assembly Programming System" > $(CST_FILE)
	@echo "# Clock input (27MHz crystal)" >> $(CST_FILE)
	@echo 'IO_LOC "clk" 52;' >> $(CST_FILE)
	@echo 'IO_PORT "clk" IO_TYPE=LVCMOS33 PULL_MODE=UP;' >> $(CST_FILE)
	@echo "" >> $(CST_FILE)
	@echo "# Reset button (active low)" >> $(CST_FILE)
	@echo 'IO_LOC "rst_n" 3;' >> $(CST_FILE)
	@echo 'IO_PORT "rst_n" IO_TYPE=LVCMOS18 PULL_MODE=UP;' >> $(CST_FILE)
	@echo "" >> $(CST_FILE)
	@echo "# Program selector switches" >> $(CST_FILE)
	@echo 'IO_LOC "switches[0]" 25;' >> $(CST_FILE)
	@echo 'IO_LOC "switches[1]" 26;' >> $(CST_FILE)
	@echo 'IO_LOC "switches[2]" 27;' >> $(CST_FILE)
	@echo 'IO_LOC "switches[3]" 28;' >> $(CST_FILE)
	@echo 'IO_PORT "switches[0]" IO_TYPE=LVCMOS18 PULL_MODE=UP;' >> $(CST_FILE)
	@echo 'IO_PORT "switches[1]" IO_TYPE=LVCMOS18 PULL_MODE=UP;' >> $(CST_FILE)
	@echo 'IO_PORT "switches[2]" IO_TYPE=LVCMOS18 PULL_MODE=UP;' >> $(CST_FILE)
	@echo 'IO_PORT "switches[3]" IO_TYPE=LVCMOS18 PULL_MODE=UP;' >> $(CST_FILE)
	@echo "" >> $(CST_FILE)
	@echo "# Program start button" >> $(CST_FILE)
	@echo 'IO_LOC "program_start_btn" 4;' >> $(CST_FILE)
	@echo 'IO_PORT "program_start_btn" IO_TYPE=LVCMOS18 PULL_MODE=UP;' >> $(CST_FILE)
	@echo "" >> $(CST_FILE)
	@echo "# LCD Interface (HD44780 compatible)" >> $(CST_FILE)
	@echo 'IO_LOC "lcd_rs" 71;' >> $(CST_FILE)
	@echo 'IO_LOC "lcd_rw" 53;' >> $(CST_FILE)
	@echo 'IO_LOC "lcd_en" 54;' >> $(CST_FILE)
	@echo 'IO_LOC "lcd_data[0]" 55;' >> $(CST_FILE)
	@echo 'IO_LOC "lcd_data[1]" 56;' >> $(CST_FILE)
	@echo 'IO_LOC "lcd_data[2]" 57;' >> $(CST_FILE)
	@echo 'IO_LOC "lcd_data[3]" 68;' >> $(CST_FILE)
	@echo 'IO_PORT "lcd_rs" IO_TYPE=LVCMOS33 DRIVE=8;' >> $(CST_FILE)
	@echo 'IO_PORT "lcd_rw" IO_TYPE=LVCMOS33 DRIVE=8;' >> $(CST_FILE)
	@echo 'IO_PORT "lcd_en" IO_TYPE=LVCMOS33 DRIVE=8;' >> $(CST_FILE)
	@echo 'IO_PORT "lcd_data[0]" IO_TYPE=LVCMOS33 DRIVE=8;' >> $(CST_FILE)
	@echo 'IO_PORT "lcd_data[1]" IO_TYPE=LVCMOS33 DRIVE=8;' >> $(CST_FILE)
	@echo 'IO_PORT "lcd_data[2]" IO_TYPE=LVCMOS33 DRIVE=8;' >> $(CST_FILE)
	@echo 'IO_PORT "lcd_data[3]" IO_TYPE=LVCMOS33 DRIVE=8;' >> $(CST_FILE)
	@echo "" >> $(CST_FILE)
	@echo "# Debug LEDs" >> $(CST_FILE)
	@echo 'IO_LOC "debug_leds[0]" 10;' >> $(CST_FILE)
	@echo 'IO_LOC "debug_leds[1]" 11;' >> $(CST_FILE)
	@echo 'IO_LOC "debug_leds[2]" 13;' >> $(CST_FILE)
	@echo 'IO_LOC "debug_leds[3]" 14;' >> $(CST_FILE)
	@echo 'IO_LOC "debug_leds[4]" 15;' >> $(CST_FILE)
	@echo 'IO_LOC "debug_leds[5]" 16;' >> $(CST_FILE)
	@echo 'IO_LOC "debug_leds[6]" 17;' >> $(CST_FILE)
	@echo 'IO_LOC "debug_leds[7]" 18;' >> $(CST_FILE)
	@echo 'IO_PORT "debug_leds[0]" IO_TYPE=LVCMOS18 DRIVE=8;' >> $(CST_FILE)
	@echo 'IO_PORT "debug_leds[1]" IO_TYPE=LVCMOS18 DRIVE=8;' >> $(CST_FILE)
	@echo 'IO_PORT "debug_leds[2]" IO_TYPE=LVCMOS18 DRIVE=8;' >> $(CST_FILE)
	@echo 'IO_PORT "debug_leds[3]" IO_TYPE=LVCMOS18 DRIVE=8;' >> $(CST_FILE)
	@echo 'IO_PORT "debug_leds[4]" IO_TYPE=LVCMOS18 DRIVE=8;' >> $(CST_FILE)
	@echo 'IO_PORT "debug_leds[5]" IO_TYPE=LVCMOS18 DRIVE=8;' >> $(CST_FILE)
	@echo 'IO_PORT "debug_leds[6]" IO_TYPE=LVCMOS18 DRIVE=8;' >> $(CST_FILE)
	@echo 'IO_PORT "debug_leds[7]" IO_TYPE=LVCMOS18 DRIVE=8;' >> $(CST_FILE)

$(SDC_FILE):
	@echo "Creating timing constraints file..."
	@echo "# Tang Nano Timing Constraints for Assembly Programming System" > $(SDC_FILE)
	@echo "create_clock -period 37.037 [get_ports clk]" >> $(SDC_FILE)
	@echo "set_clock_uncertainty 0.5 [get_clocks]" >> $(SDC_FILE)
	@echo "set_input_delay -clock [get_clocks] -max 5 [all_inputs]" >> $(SDC_FILE)
	@echo "set_output_delay -clock [get_clocks] -max 5 [all_outputs]" >> $(SDC_FILE)
	@echo "" >> $(SDC_FILE)
	@echo "# LCD timing constraints" >> $(SDC_FILE)
	@echo "set_output_delay -clock [get_clocks] -max 10 [get_ports {lcd_rs lcd_rw lcd_en lcd_data[*]}]" >> $(SDC_FILE)
	@echo "set_output_delay -clock [get_clocks] -min 2 [get_ports {lcd_rs lcd_rw lcd_en lcd_data[*]}]" >> $(SDC_FILE)
	@echo "" >> $(SDC_FILE)
	@echo "# CPU internal clock constraints" >> $(SDC_FILE)
	@echo "create_generated_clock -name cpu_clk_slow -source [get_ports clk] -divide_by 32 [get_pins cpu_clk_div_reg[4]/Q]" >> $(SDC_FILE)
	@echo "create_generated_clock -name cpu_clk_med -source [get_ports clk] -divide_by 16 [get_pins cpu_clk_div_reg[3]/Q]" >> $(SDC_FILE)
	@echo "create_generated_clock -name cpu_clk_fast -source [get_ports clk] -divide_by 8 [get_pins cpu_clk_div_reg[2]/Q]" >> $(SDC_FILE)
	@echo "" >> $(SDC_FILE)
	@echo "# Button debounce timing" >> $(SDC_FILE)
	@echo "set_input_delay -clock [get_clocks] -max 20 [get_ports program_start_btn]" >> $(SDC_FILE)

# Generate assembly documentation
docs: assembly_programs.md

assembly_programs.md:
	@echo "# 6502 Assembly Programming Examples" > assembly_programs.md
	@echo "" >> assembly_programs.md
	@echo "This document describes the assembly programs included in the system." >> assembly_programs.md
	@echo "" >> assembly_programs.md
	@echo "## Program List" >> assembly_programs.md
	@echo "" >> assembly_programs.md
	@echo "| Program | Address | Description |" >> assembly_programs.md
	@echo "|---------|---------|-------------|" >> assembly_programs.md
	@echo "| 0 | \$$C000 | Basic Arithmetic - Addition and subtraction |" >> assembly_programs.md
	@echo "| 1 | \$$C020 | Loop with Counter - Count from 0 to 10 |" >> assembly_programs.md
	@echo "| 2 | \$$C040 | Data Manipulation - Bit operations and shifts |" >> assembly_programs.md
	@echo "| 3 | \$$C060 | Subroutine with Stack - JSR/RTS demonstration |" >> assembly_programs.md
	@echo "| 4 | \$$C080 | Array Processing - Indexed memory operations |" >> assembly_programs.md
	@echo "| 5 | \$$C0C0 | String Operations - Character processing |" >> assembly_programs.md
	@echo "| 6 | \$$C0E0 | Math Functions - Multiplication by addition |" >> assembly_programs.md
	@echo "| 7 | \$$C100 | I/O Operations - Reading switches |" >> assembly_programs.md
	@echo "" >> assembly_programs.md
	@echo "## Usage Instructions" >> assembly_programs.md
	@echo "" >> assembly_programs.md
	@echo "1. Use switches[3:0] to select program (0-7)" >> assembly_programs.md
	@echo "2. Use switches[3:2] to select display mode" >> assembly_programs.md
	@echo "3. Use switches[1:0] to control CPU speed" >> assembly_programs.md
	@echo "4. Press program_start_btn to start selected program" >> assembly_programs.md
	@echo "" >> assembly_programs.md
	@echo "## Display Modes" >> assembly_programs.md
	@echo "" >> assembly_programs.md
	@echo "- Mode 0: CPU Registers (A, X, Y, PC)" >> assembly_programs.md
	@echo "- Mode 1: Program Information and Status Flags" >> assembly_programs.md
	@echo "- Mode 2: System Status and Debug Info" >> assembly_programs.md
	@echo "- Mode 3: Memory View (reserved for future)" >> assembly_programs.md

# Clean build files
clean:
	rm -rf $(BUILD_DIR) $(SIM_DIR)
	rm -f *.log *.rpt

# Clean all generated files
distclean: clean
	rm -f $(CST_FILE) $(SDC_FILE) assembly_programs.md

# Help
help:
	@echo "Available targets:"
	@echo "  all          - Build for Tang Nano 9K (default)"
	@echo "  tang_nano_9k - Build for Tang Nano 9K"
	@echo "  tang_nano_20k- Build for Tang Nano 20K"
	@echo "  sim          - Compile simulation"
	@echo "  run_sim      - Run assembly system simulation"
	@echo "  synth_check  - Synthesis check only"
	@echo "  program_9k   - Program Tang Nano 9K"
	@echo "  program_20k  - Program Tang Nano 20K"
	@echo "  constraints  - Generate constraint files"
	@echo "  docs         - Generate assembly documentation"
	@echo "  clean        - Clean build files"
	@echo "  distclean    - Clean all generated files"
	@echo "  help         - Show this help"
	@echo ""
	@echo "Assembly Programming System:"
	@echo "  This is a complete 6502 development environment with:"
	@echo "  - 8 example assembly programs"
	@echo "  - Program selection and execution"
	@echo "  - LCD display with multiple modes"
	@echo "  - Real-time CPU monitoring"
	@echo "  - Variable CPU speed control"
	@echo ""
	@echo "Hardware Connections:"
	@echo "  switches[3:0] -> Program/Display selector"
	@echo "  program_start_btn -> Program start/reset"
	@echo "  LCD -> Standard HD44780 16x2 display"
	@echo "  debug_leds[7:0] -> System status indicators"

.PHONY: all tang_nano_9k tang_nano_20k sim run_sim synth_check program_9k program_20k constraints docs clean distclean help