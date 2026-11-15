`timescale 1ns/1ps
// MINISYS hardware manual v1.1: clock 100 MHz; S6 and S1 active high; LEDs active high.
module traffic_light_minisys #(
    parameter integer CLK_HZ=100_000_000,
    parameter integer UNIT_CYCLES=100_000_000,
    parameter integer DEBOUNCE_CYCLES=2_000_000
)(
    input clk,
    input reset,        // S6/P20, active high, LVCMOS33
    input request_btn,  // S1/R1, active high, LVCMOS15
    output motor_red, output motor_yellow, output motor_green,
    output pass_red, output pass_green
);
    wire [4:0] lights;
    traffic_light_board #(
        .CLK_HZ(CLK_HZ),.UNIT_CYCLES(UNIT_CYCLES),.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES),
        .BUTTON_ACTIVE_LOW(0),.LED_ACTIVE_LOW(0)
    ) u_board(.clk(clk),.reset_n(~reset),.request_btn(request_btn),.led(lights));
    assign {motor_red,motor_yellow,motor_green,pass_red,pass_green}=lights;
endmodule
