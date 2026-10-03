# Gowin SUG940-2.0E timing constraints for Tang Nano 20K.
create_clock -name xtal_clk -period 37.037037 -waveform {0 18.518519} [get_ports {XTAL_IN}]
create_generated_clock -name pixel_clk -source [get_ports {XTAL_IN}] -divide_by 3 [get_pins {u_core/clocks/pixel_pll/rpll_inst/CLKOUT}]
create_generated_clock -name memory_clk -source [get_ports {XTAL_IN}] -multiply_by 3 -divide_by 2 [get_pins {u_core/clocks/memory_pll/rpll_inst/CLKOUT}]

set_false_path -from [get_clocks {pixel_clk}] -to [get_regs {u_core/cpu_inst/*vsync_meta*}]
set_false_path -from [get_ports {ResetButton}]
set_false_path -from [get_pins {u_core/clocks/pixel_pll/rpll_inst/LOCK}]
set_false_path -from [get_pins {u_core/clocks/memory_pll/rpll_inst/LOCK}]

report_timing -setup -from_clock [get_clocks {pixel_clk}] -to_clock [get_clocks {pixel_clk}] -max_paths 10
report_timing -hold -from_clock [get_clocks {pixel_clk}] -to_clock [get_clocks {pixel_clk}] -max_paths 10
report_timing -setup -from_clock [get_clocks {memory_clk}] -to_clock [get_clocks {memory_clk}] -max_paths 10
report_timing -hold -from_clock [get_clocks {memory_clk}] -to_clock [get_clocks {memory_clk}] -max_paths 10
