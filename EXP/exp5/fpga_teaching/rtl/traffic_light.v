`timescale 1ns/1ps
// Teaching core: same state codes and one-hot load selection as the Logisim drawing.
module traffic_light #(
    parameter integer UNIT_CYCLES = 10
)(
    input clk, input rst_n, input pass_request,
    output [7:0] clock,
    output reg motor_green, output reg motor_yellow, output reg motor_red,
    output reg pass_red, output reg pass_green
);
    localparam [1:0] GREEN=2'b00, YELLOW=2'b01, RED=2'b10;
    localparam integer DIV_W=(UNIT_CYCLES<2)?1:$clog2(UNIT_CYCLES);
    reg [1:0] state;
    reg [7:0] cnt;
    reg [DIV_W-1:0] div_cnt;
    wire green=(state==GREEN), yellow=(state==YELLOW), red=(state==RED);
    wire recover=(state==2'b11);
    wire unit_done=(div_cnt==UNIT_CYCLES-1);
    wire expired=(cnt==8'd1) && unit_done;

    // Each signal selects ONE fixed load value; it is not itself an 8-bit number.
    wire set10=green && pass_request && (cnt>8'd10);
    wire set5=green && expired;
    wire set50=yellow && expired;
    wire set90=red && expired;
    wire load_count=set10 | set5 | set50 | set90 | recover;
    wire [7:0] load_data=({8{set10}} & 8'd10)
                          |({8{set5}} & 8'd5)
                          |({8{set50}} & 8'd50)
                          |({8{set90|recover}} & 8'd90);
    wire state_we=set5 | set50 | set90 | recover;
    wire [1:0] state_d={set50,set5};
    wire [1:0] state_next=state_we ? state_d : state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state<=GREEN;
            cnt<=8'd90;
            div_cnt<=0;
        end else begin
            state<=state_next;
            if (load_count) begin
                cnt<=load_data;
                div_cnt<=0;
            end else if (unit_done) begin
                cnt<=cnt-8'd1;
                div_cnt<=0;
            end else div_cnt<=div_cnt+1'b1;
        end
    end

    // Register lamps on the same edge as the state update.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            motor_green<=1; motor_yellow<=0; motor_red<=0;
            pass_red<=1; pass_green<=0;
        end else begin
            motor_green<=(state_next==GREEN);
            motor_yellow<=(state_next==YELLOW);
            motor_red<=(state_next==RED);
            pass_red<=(state_next==GREEN)||(state_next==YELLOW);
            pass_green<=(state_next==RED);
        end
    end
    assign clock=cnt; // Data bus, not a clock signal.
endmodule
