log_wave /tb_traffic_light/clk /tb_traffic_light/rst_n /tb_traffic_light/pass_request /tb_traffic_light/clock /tb_traffic_light/light_name /tb_traffic_light/motor_green /tb_traffic_light/motor_yellow /tb_traffic_light/motor_red /tb_traffic_light/pass_red /tb_traffic_light/pass_green
log_wave /tb_traffic_light/dut/state /tb_traffic_light/dut/cnt /tb_traffic_light/dut/div_cnt /tb_traffic_light/dut/set10 /tb_traffic_light/dut/set5 /tb_traffic_light/dut/set50 /tb_traffic_light/dut/set90 /tb_traffic_light/dut/load_count /tb_traffic_light/dut/load_data /tb_traffic_light/dut/state_we /tb_traffic_light/dut/state_d
open_vcd results/traffic_light.vcd
log_vcd /tb_traffic_light/*
run all
close_vcd
quit
