set root [file normalize [file join [file dirname [info script]] ..]]
create_project traffic_teaching [file join $root vivado_project] -part xc7a100tfgg484-1 -force
set_property target_language Verilog [current_project]
add_files [list [file join $root rtl traffic_light.v] [file join $root rtl traffic_light_board.v] [file join $root rtl traffic_light_minisys.v]]
set_property top traffic_light_minisys [get_filesets sources_1]
add_files -fileset sim_1 [file join $root sim tb_traffic_light.sv]
set_property top tb_traffic_light [get_filesets sim_1]
set_property xsim.simulate.runtime all [get_filesets sim_1]
add_files -fileset constrs_1 [file join $root constraints minisys_traffic.xdc]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
close_project
