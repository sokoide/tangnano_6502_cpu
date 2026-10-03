if {[info exists env(PROJ)]} {
  open_project $env(PROJ)
} else {
  open_project $env(BASE).gprj
}
set_option -include_path include
set_option -verilog_std sysv2017
set_option -use_sspi_as_gpio 1
# Preserve the implemented logic for optional functional netlist regression.
set_option -gen_verilog_sim_netlist 1
run all
exit
