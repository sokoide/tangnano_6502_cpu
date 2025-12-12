if {[info exists env(PROJ)]} {
  open_project $env(PROJ)
} else {
  open_project $env(BASE).gprj
}
set_option -include_path include
set_option -verilog_std sysv2017
set_option -use_sspi_as_gpio 1
run all
exit
