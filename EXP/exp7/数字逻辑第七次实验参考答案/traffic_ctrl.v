`timescale 1ns/1ps
module traffic_ctrl #(
    parameter integer CLOCKS_PER_SECOND = 50000000
)(
    input wire clk, rst, side_req, main_car,
    output reg main_red, main_yellow, main_green,
    output reg side_red, side_yellow, side_green,
    output reg [1:0] state,
    output reg [4:0] elapsed,
    output reg [1:0] car_count
);
    localparam MG=2'd0, MY=2'd1, SG=2'd2, SY=2'd3;
    reg [1:0] next_state;
    reg waiting;
    reg [31:0] phase;
    wire second_done = (phase == CLOCKS_PER_SECOND-1);
    wire third_car = main_car && (car_count == 2);
// 组合逻辑确定状态转移次态发生瞬间的条件出触发
    always @(*) begin
        next_state = state;
        case (state)
            MG: if (waiting && second_done && elapsed == 5) next_state=MY;
            MY: if (second_done && elapsed == 3) next_state=SG;
            SG: if (third_car || car_count == 3 ||
                    (second_done && elapsed == 24)) next_state=SY;
            SY: if (second_done && elapsed == 3) next_state=MG;
            default: next_state=MG;
        endcase
    end
// 时序逻辑来维持当前态
    always @(posedge clk) begin
        if (rst) begin
            state <= MG;
            waiting <= 0;
            phase <= 0;
            elapsed <= 0;
            car_count <= 0;
        end else begin
            state <= next_state;
            if (next_state != state) begin
                phase <= 0;
                elapsed <= 0;
                waiting <= 0;
            end else if (state == MG && !waiting && side_req) begin
                waiting <= 1;
                phase <= 0;
                elapsed <= 0;
            end else if (state != MG || waiting) begin
                if (second_done) begin
                    phase <= 0;
                    elapsed <= elapsed + 1'b1;
                end else phase <= phase + 1'b1;
            end else begin
                phase <= 0;
                elapsed <= 0;
            end

            // Clear on entry to SG; retain the final count for observation.
            if (state != SG && next_state == SG) car_count <= 0;
            else if (state == SG && main_car && car_count < 3)
                car_count <= car_count + 1'b1;
        end
    end

    always @(*) begin
        // Safe default for an unknown state: both directions red.
        main_red=1; main_yellow=0; main_green=0;
        side_red=1; side_yellow=0; side_green=0;
        case (state)
            MG: begin main_red=0; main_green=1; end
            MY: begin main_red=0; main_yellow=1; end
            SG: begin side_red=0; side_green=1; end
            SY: begin side_red=0; side_yellow=1; end
            default: begin end
        endcase
    end
endmodule
