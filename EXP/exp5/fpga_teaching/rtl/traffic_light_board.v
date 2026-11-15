`timescale 1ns/1ps
module traffic_light_board #(
    // EXAMPLES ONLY: set from the actual board manual before programming.
    parameter integer CLK_HZ=100_000_000,
    parameter integer UNIT_CYCLES=CLK_HZ,
    parameter integer DEBOUNCE_CYCLES=CLK_HZ/50,
    parameter integer BUTTON_ACTIVE_LOW=0,
    parameter integer LED_ACTIVE_LOW=0
)(
    input clk, input reset_n, input request_btn,
    output [4:0] led
);
    (* ASYNC_REG="TRUE" *) reg [1:0] reset_pipe;
    always @(posedge clk or negedge reset_n)
        if (!reset_n) reset_pipe<=0;
        else reset_pipe<={reset_pipe[0],1'b1};
    wire core_rst_n=reset_pipe[1];
    wire button_active=BUTTON_ACTIVE_LOW ? ~request_btn : request_btn;
    (* ASYNC_REG="TRUE" *) reg btn_meta,btn_sync;
    always @(posedge clk or negedge core_rst_n)
        if (!core_rst_n) begin btn_meta<=0;btn_sync<=0;end
        else begin btn_meta<=button_active;btn_sync<=btn_meta;end
    localparam integer DB_W=(DEBOUNCE_CYCLES<2)?1:$clog2(DEBOUNCE_CYCLES);
    reg [DB_W-1:0] stable_cnt;
    reg btn_level,request_pulse;
    always @(posedge clk or negedge core_rst_n) begin
        if (!core_rst_n) begin stable_cnt<=0;btn_level<=0;request_pulse<=0;end
        else begin
            request_pulse<=0;
            if (btn_sync==btn_level) stable_cnt<=0;
            else if (stable_cnt==DEBOUNCE_CYCLES-1) begin
                stable_cnt<=0;btn_level<=btn_sync;
                if (btn_sync) request_pulse<=1;
            end else stable_cnt<=stable_cnt+1'b1;
        end
    end
    wire [7:0] countdown;
    wire motor_green,motor_yellow,motor_red,pass_red,pass_green;
    traffic_light #(.UNIT_CYCLES(UNIT_CYCLES)) u_core(
        .clk(clk),.rst_n(core_rst_n),.pass_request(request_pulse),.clock(countdown),
        .motor_green(motor_green),.motor_yellow(motor_yellow),.motor_red(motor_red),
        .pass_red(pass_red),.pass_green(pass_green));
    wire [4:0] logical_lights={motor_red,motor_yellow,motor_green,pass_red,pass_green};
    assign led=LED_ACTIVE_LOW ? ~logical_lights : logical_lights;
endmodule
