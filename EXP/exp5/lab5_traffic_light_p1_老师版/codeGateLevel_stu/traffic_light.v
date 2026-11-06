`timescale 1ns/1ns
module traffic_light
(
    input        rst_n,        // asynchronous reset, active low
    input        clk,          // system clock
    input        pass_request, // pedestrian push-button, active high
    output [7:0] clock,        // countdown readout (unit: 10 clk)
    output reg   motor_red,    // motor-lane red light
    output reg   motor_yellow, // motor-lane yellow light
    output reg   motor_green,  // motor-lane green light
    output reg   pass_red,     // crosswalk red light
    output reg   pass_green    // crosswalk green light
);

//-------- state encoding --------
localparam RED    = 2'd0;
localparam YELLOW = 2'd1;
localparam GREEN  = 2'd2;

//-------- light durations in counts (1 count = 10 clk) --------
localparam GREEN_UNITS  = 8'd90;   // 900 clk
localparam YELLOW_UNITS = 8'd5;    // 50  clk
localparam RED_UNITS    = 8'd50;   // 500 clk
localparam UNIT_DIV     = 4'd10;   // 1 count = 10 clk

reg [1:0] cur_state;
reg [1:0] nxt_state;
reg [7:0] cnt;          // remaining counts of the current light
reg [3:0] div_cnt;      // clk divider inside one count (0~9)

// last clk of the current light
wire last_clk = (cnt == 8'd1) && (div_cnt == UNIT_DIV-1);

// [TODO] begin: writing your design here.






// [TODO] end

//------------------------------------------------------
//    light outputs (registered): motor and crosswalk
//    lights are strictly paired
//------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        motor_red    <= 1'b0;
        motor_yellow <= 1'b0;
        motor_green  <= 1'b1;
        pass_red     <= 1'b1;
        pass_green   <= 1'b0;
    end
    else begin
        motor_red    <= (nxt_state == RED);
        motor_yellow <= (nxt_state == YELLOW);
        motor_green  <= (nxt_state == GREEN);
        pass_green   <= (nxt_state == RED);
        pass_red     <= (nxt_state == GREEN) || (nxt_state == YELLOW);
    end
end

assign clock = cnt;

endmodule
