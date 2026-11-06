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

// 1. Current-state decoding and request detection
localparam [3:0] DIV_LAST = UNIT_DIV - 4'd1;

wire state_red;
wire state_yellow;
wire state_green;
wire state_invalid;
wire div_is_last;
wire cnt_gt_10;
wire shorten_green;

assign state_red     = ~cur_state[1] & ~cur_state[0];
assign state_yellow  = ~cur_state[1] &  cur_state[0];
assign state_green   =  cur_state[1] & ~cur_state[0];
assign state_invalid =  cur_state[1] &  cur_state[0];

assign div_is_last = &(div_cnt ~^ DIV_LAST);
assign cnt_gt_10   = (|cnt[7:4])
                   | (cnt[3] & (cnt[2] | (cnt[1] & cnt[0])));
assign shorten_green = pass_request & state_green & cnt_gt_10;

// 2. Divider incrementer: AND carry chain and XOR gates
wire [3:0] div_carry;
wire [3:0] div_inc;

assign div_carry[0] = 1'b1;
assign div_carry[1] = div_cnt[0] & div_carry[0];
assign div_carry[2] = div_cnt[1] & div_carry[1];
assign div_carry[3] = div_cnt[2] & div_carry[2];
assign div_inc     = div_cnt ^ div_carry;

// 3. Countdown decrementer: borrow chain and XOR gates
wire [7:0] cnt_borrow;
wire [7:0] cnt_dec;

assign cnt_borrow[0] = 1'b1;
assign cnt_borrow[1] = ~cnt[0] & cnt_borrow[0];
assign cnt_borrow[2] = ~cnt[1] & cnt_borrow[1];
assign cnt_borrow[3] = ~cnt[2] & cnt_borrow[2];
assign cnt_borrow[4] = ~cnt[3] & cnt_borrow[3];
assign cnt_borrow[5] = ~cnt[4] & cnt_borrow[4];
assign cnt_borrow[6] = ~cnt[5] & cnt_borrow[5];
assign cnt_borrow[7] = ~cnt[6] & cnt_borrow[6];
assign cnt_dec      = cnt ^ cnt_borrow;

// 4. Counter D-input selection: request > reload > decrement > hold
wire [7:0] reload_cnt;
wire       sel_request;
wire       sel_reload;
wire       sel_decrement;
wire       sel_hold;
wire [7:0] cnt_d;
wire [3:0] div_cnt_d;

assign reload_cnt = ({8{state_green}} & YELLOW_UNITS)
                  | ({8{state_red}} & GREEN_UNITS)
                  | ({8{state_yellow | state_invalid}} & RED_UNITS);

assign sel_request   =  shorten_green;
assign sel_reload    = ~shorten_green &  last_clk;
assign sel_decrement = ~shorten_green & ~last_clk &  div_is_last;
assign sel_hold      = ~shorten_green & ~last_clk & ~div_is_last;

assign cnt_d = ({8{sel_request}}   & 8'd10)
             | ({8{sel_reload}}    & reload_cnt)
             | ({8{sel_decrement}} & cnt_dec)
             | ({8{sel_hold}}      & cnt);

assign div_cnt_d = {4{sel_hold}} & div_inc;

// 5. Registered lookahead for the unchanged reg nxt_state
// Predict F(next cur_state, next cnt, next div_cnt).
// Since next cur_state = nxt_state, decode nxt_state here.
wire ahead_red;
wire ahead_yellow;
wire ahead_green;
wire ahead_invalid;
wire predicted_last_clk;
wire [1:0] nxt_state_d;

assign ahead_red     = ~nxt_state[1] & ~nxt_state[0];
assign ahead_yellow  = ~nxt_state[1] &  nxt_state[0];
assign ahead_green   =  nxt_state[1] & ~nxt_state[0];
assign ahead_invalid =  nxt_state[1] &  nxt_state[0];

assign predicted_last_clk = (~|cnt_d[7:1]) & cnt_d[0]
                          & (&(div_cnt_d ~^ DIV_LAST));

assign nxt_state_d[1] = (ahead_green & ~predicted_last_clk)
                      | (ahead_red & predicted_last_clk)
                      | ahead_invalid;

assign nxt_state_d[0] = (ahead_green & predicted_last_clk)
                      | (ahead_yellow & ~predicted_last_clk);

// 6. DFFs: only constants or single signals on assignment RHS
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cur_state <= GREEN;
        nxt_state <= GREEN;
        cnt       <= GREEN_UNITS;
        div_cnt   <= 4'd0;
    end
    else begin
        cur_state <= nxt_state;
        nxt_state <= nxt_state_d;
        cnt       <= cnt_d;
        div_cnt   <= div_cnt_d;
    end
end

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
