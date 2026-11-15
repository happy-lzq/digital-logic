set root [file normalize [file join [file dirname [info script]] ..]]
open_project [file join $root vivado_project traffic_teaching.xpr]
launch_runs synth_1 -jobs 2
wait_on_run synth_1
if {[get_property PROGRESS [get_runs synth_1]] ne "100%"} { error "Synthesis did not complete" }
open_run synth_1
report_utilization -file [file join $root results utilization_synth.rpt]
report_timing_summary -file [file join $root results timing_synth.rpt]
report_exceptions -file [file join $root results exceptions_synth.rpt]
close_design
launch_runs impl_1 -to_step write_bitstream -jobs 2
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] ne "100%"} { error "Implementation/bitstream did not complete" }
open_run impl_1
report_timing_summary -file [file join $root results timing_routed.rpt]
report_drc -file [file join $root results drc_routed.rpt]
report_clock_utilization -file [file join $root results clock_utilization.rpt]
report_io -file [file join $root results pin_bindings.rpt]
write_checkpoint -force [file join $root results traffic_light_minisys_routed.dcp]
file copy -force [file join $root vivado_project traffic_teaching.runs impl_1 traffic_light_minisys.bit] [file join $root results traffic_light_minisys.bit]
puts "BOARD_BUILD_PASS: routed design and bitstream generated; no physical programming performed"
close_project
