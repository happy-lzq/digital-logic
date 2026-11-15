# TEACHING EXAMPLE ONLY: assumes 100 MHz. No physical pin map is supplied.
# This demonstrates clock constraint syntax; it is not a board-ready constraint file.
create_clock -name sys_clk -period 10.000 [get_ports clk]
