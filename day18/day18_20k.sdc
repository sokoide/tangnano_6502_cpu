# Gowin SUG940-2.0E timing constraints for Tang Nano 20K.
# pixel_clk: Gowin_rPLL9 (FCLKIN=27, IDIV_SEL=2, FBDIV_SEL=0, ODIV_SEL=64) = 27MHz / 3 = 9MHz.
# memory_clk: Gowin_rPLL40 (FCLKIN=27, IDIV_SEL=1, FBDIV_SEL=2, ODIV_SEL=16) = 27MHz * 3 / 2 = 40.5MHz.
create_clock -name xtal_clk -period 37.037037 -waveform {0 18.518519} [get_ports {XTAL_IN}]
create_generated_clock -name pixel_clk -source [get_ports {XTAL_IN}] -divide_by 3 [get_pins {u_demo/pll9_inst/rpll_inst/CLKOUT}]
create_generated_clock -name memory_clk -source [get_ports {XTAL_IN}] -multiply_by 3 -divide_by 2 [get_pins {u_demo/pll40_inst/rpll_inst/CLKOUT}]

# LCD_CLK (pixel) to MEMORY_CLK CDC: vsync is quasi-static (frame rate) and
# double-flopped by u_demo (vsync_meta/vsync_cpu).
set_false_path -from [get_clocks {pixel_clk}] -to [get_regs {u_demo/*vsync_meta*}]
set_false_path -from [get_ports {ResetButton}]
set_false_path -from [get_pins {u_demo/pll9_inst/rpll_inst/LOCK}]
set_false_path -from [get_pins {u_demo/pll40_inst/rpll_inst/LOCK}]

report_timing -setup -from_clock [get_clocks {pixel_clk}] -to_clock [get_clocks {pixel_clk}] -max_paths 10
report_timing -hold -from_clock [get_clocks {pixel_clk}] -to_clock [get_clocks {pixel_clk}] -max_paths 10
report_timing -setup -from_clock [get_clocks {memory_clk}] -to_clock [get_clocks {memory_clk}] -max_paths 10
report_timing -hold -from_clock [get_clocks {memory_clk}] -to_clock [get_clocks {memory_clk}] -max_paths 10
