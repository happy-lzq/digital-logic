# MINISYS hardware manual v1.1, pages 10-12, figures 1-2 / 1-3.
# Course confirmation: https://huangxici.github.io/Digital_Logic/labs/lab5.html
# All names below must match the top module traffic_light_minisys exactly.

# 100 MHz oscillator, period = 10 ns. This constrains timing; it does not create a clock.
set_property PACKAGE_PIN Y18 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -name sys_clk -period 10.000 [get_ports clk]

# S6 reset button: pressed=1, 3.3 V
set_property PACKAGE_PIN P20 [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]

# S1 user button: pressed=1, 1.5 V (do NOT copy reset's LVCMOS33 here)
set_property PACKAGE_PIN R1 [get_ports request_btn]
set_property IOSTANDARD LVCMOS15 [get_ports request_btn]

# Use the physical LED colors: RLD0/YLD0/GLD0 and RLD1/GLD1.
set_property PACKAGE_PIN N19 [get_ports motor_red]
set_property PACKAGE_PIN A21 [get_ports motor_yellow]
set_property PACKAGE_PIN J17 [get_ports motor_green]
set_property PACKAGE_PIN N20 [get_ports pass_red]
set_property PACKAGE_PIN L14 [get_ports pass_green]
set_property IOSTANDARD LVCMOS33 [get_ports {motor_red motor_yellow motor_green pass_red pass_green}]

# Asynchronous input -> first synchronizer only. Internal synchronous paths remain timed.
set_false_path -from [get_ports request_btn] -to [get_pins -hierarchical -filter {NAME =~ */btn_meta_reg/D}]
# External reset is asynchronously asserted into the reset-release synchronizer.
set_false_path -from [get_ports reset] -to [get_pins -hierarchical -filter {NAME =~ */reset_pipe_reg*/CLR || NAME =~ */reset_pipe_reg*/PRE}]

# LEDs have no external clocked receiver, so no invented set_output_delay is added.
# check_timing may list these LED ports as lacking an output delay; explain their role.
