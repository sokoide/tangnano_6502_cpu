# Makefile for Day 09: LCD Controller System
# Tang Nano 9K/20K FPGA Build System with LCD Interface

# Project configuration
PROJECT_NAME = day09_lcd_system
TOP_MODULE = top
DEVICE_9K = GW1NR-LV9QN88PC6/I5
DEVICE_20K = GW2A-LV18PG256C8/I7
FAMILY = GW1N

# Source files (LCD + CPU system)
SOURCES = top.sv \
          cpu_lcd_system.sv \
          lcd_controller.sv \
          lcd_display.sv \
          ../day08_completed/cpu_core.sv \
          ../day08_completed/cpu_datapath.sv \
          ../day08_completed/cpu_control_unit.sv \
          ../day08_completed/cpu_registers.sv \
          ../day08_completed/test_rom.sv \
          ../day06_completed/cpu_alu.sv \
          ../day06_completed/cpu_decoder.sv \
          ../day06_completed/status_register.sv \
          ../day07_completed/memory_controller.sv \
          ../day07_completed/memory_interface.sv \
          ../day07_completed/stack_pointer.sv \
          ../day07_completed/simple_ram.sv \
          ../day05_completed/addressing_mode_calculator.sv

# Testbench files
TB_SOURCES = tb_lcd_system.sv \
             cpu_lcd_system.sv \
             lcd_controller.sv \
             lcd_display.sv \
             ../day08_completed/cpu_core.sv \
             ../day08_completed/cpu_datapath.sv \
             ../day08_completed/cpu_control_unit.sv \
             ../day08_completed/cpu_registers.sv \
             ../day08_completed/test_rom.sv \
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
sim: $(SIM_DIR)/lcd_system_tb

$(SIM_DIR)/lcd_system_tb: $(TB_SOURCES)
	@mkdir -p $(SIM_DIR)
	iverilog -g2012 -o $(SIM_DIR)/lcd_system_tb $(TB_SOURCES)

# Run simulation
run_sim: sim
	cd $(SIM_DIR) && ./lcd_system_tb

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
	@echo "Creating LCD interface pin constraints file..."
	@echo "# Tang Nano Pin Constraints for LCD Controller System" > $(CST_FILE)
	@echo "# Clock input (27MHz crystal)" >> $(CST_FILE)
	@echo 'IO_LOC "clk" 52;' >> $(CST_FILE)
	@echo 'IO_PORT "clk" IO_TYPE=LVCMOS33 PULL_MODE=UP;' >> $(CST_FILE)
	@echo "" >> $(CST_FILE)
	@echo "# Reset button (active low)" >> $(CST_FILE)
	@echo 'IO_LOC "rst_n" 3;' >> $(CST_FILE)
	@echo 'IO_PORT "rst_n" IO_TYPE=LVCMOS18 PULL_MODE=UP;' >> $(CST_FILE)
	@echo "" >> $(CST_FILE)
	@echo "# DIP switches for system control" >> $(CST_FILE)
	@echo 'IO_LOC "switches[0]" 25;' >> $(CST_FILE)
	@echo 'IO_LOC "switches[1]" 26;' >> $(CST_FILE)
	@echo 'IO_LOC "switches[2]" 27;' >> $(CST_FILE)
	@echo 'IO_LOC "switches[3]" 28;' >> $(CST_FILE)
	@echo 'IO_PORT "switches[0]" IO_TYPE=LVCMOS18 PULL_MODE=UP;' >> $(CST_FILE)
	@echo 'IO_PORT "switches[1]" IO_TYPE=LVCMOS18 PULL_MODE=UP;' >> $(CST_FILE)
	@echo 'IO_PORT "switches[2]" IO_TYPE=LVCMOS18 PULL_MODE=UP;' >> $(CST_FILE)
	@echo 'IO_PORT "switches[3]" IO_TYPE=LVCMOS18 PULL_MODE=UP;' >> $(CST_FILE)
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
	@echo "# Tang Nano Timing Constraints for LCD Controller System" > $(SDC_FILE)
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
	@echo "create_generated_clock -name cpu_clk_div3 -source [get_ports clk] -divide_by 16 [get_pins cpu_clk_div_reg[3]/Q]" >> $(SDC_FILE)

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
	@echo "  run_sim      - Run LCD system simulation"
	@echo "  synth_check  - Synthesis check only"
	@echo "  program_9k   - Program Tang Nano 9K"
	@echo "  program_20k  - Program Tang Nano 20K"
	@echo "  constraints  - Generate constraint files"
	@echo "  clean        - Clean build files"
	@echo "  distclean    - Clean all generated files"
	@echo "  help         - Show this help"
	@echo ""
	@echo "LCD Interface Connections:"
	@echo "  lcd_rs  -> Pin 71 (Register Select)"
	@echo "  lcd_rw  -> Pin 53 (Read/Write, tied to write)"
	@echo "  lcd_en  -> Pin 54 (Enable pulse)"
	@echo "  lcd_data[0:3] -> Pins 55,56,57,68 (4-bit data)"
	@echo ""
	@echo "Switch Functions:"
	@echo "  switches[1:0] - CPU clock speed control"
	@echo "  switches[3:2] - System configuration"

.PHONY: all tang_nano_9k tang_nano_20k sim run_sim synth_check program_9k program_20k constraints clean distclean help