# Copy to board.xdc and replace every placeholder from your exact board manual.
# Do not add this unedited template as active constraints.
# set_property PACKAGE_PIN <CLK_PIN> [get_ports clk]
# set_property IOSTANDARD <CLK_STANDARD> [get_ports clk]
# create_clock -name sys_clk -period <ACTUAL_PERIOD_NS> [get_ports clk]
# set_property PACKAGE_PIN <RESET_PIN> [get_ports reset_n]
# set_property IOSTANDARD <RESET_STANDARD> [get_ports reset_n]
# set_property PACKAGE_PIN <BUTTON_PIN> [get_ports request_btn]
# set_property IOSTANDARD <BUTTON_STANDARD> [get_ports request_btn]
# set_property PACKAGE_PIN <MOTOR_RED_PIN> [get_ports {led[4]}]
# set_property PACKAGE_PIN <MOTOR_YELLOW_PIN> [get_ports {led[3]}]
# set_property PACKAGE_PIN <MOTOR_GREEN_PIN> [get_ports {led[2]}]
# set_property PACKAGE_PIN <PASS_RED_PIN> [get_ports {led[1]}]
# set_property PACKAGE_PIN <PASS_GREEN_PIN> [get_ports {led[0]}]
# set_property IOSTANDARD <LED_STANDARD> [get_ports {led[*]}]
# 100 MHz -> 10.000 ns; 50 MHz -> 20.000 ns. Use actual frequency/voltage.
