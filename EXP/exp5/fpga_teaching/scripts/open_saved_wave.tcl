set root [file normalize [file join [file dirname [info script]] ..]]
open_wave_database [file join $root results traffic_light.wdb]
create_wave_config
foreach n {clk rst_n pass_request motor_green motor_yellow motor_red pass_red pass_green} {add_wave /tb_traffic_light/$n}
add_wave -radix unsigned /tb_traffic_light/clock
add_wave -radix ascii /tb_traffic_light/light_name
foreach n {state cnt div_cnt load_data} {add_wave -radix unsigned /tb_traffic_light/dut/$n}
foreach n {set10 set5 set50 set90 load_count state_we} {add_wave /tb_traffic_light/dut/$n}
save_wave_config [file join $root results traffic_light.wcfg]
