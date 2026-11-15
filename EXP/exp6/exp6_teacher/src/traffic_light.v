`timescale 1ns / 1ps

module traffic_light #(
    // 板载晶振频率：100 MHz
    parameter integer CLKS_PER_SEC = 100_000_000
)(
    input  wire clk,
    input  wire reset,
    input  wire pass_request,

    output reg  motor_green,
    output reg  motor_yellow,
    output reg  motor_red,
    output reg  pass_red,
    output reg  pass_green
);

    localparam [1:0] GREEN  = 2'b00;
    localparam [1:0] YELLOW = 2'b01;
    localparam [1:0] RED    = 2'b10;

    reg [1:0] state;
    reg [7:0] countdown;

    // ==================================================
    // 1. 复位处理：高电平有效，异步置位、同步释放
    // ==================================================

    (* ASYNC_REG = "TRUE" *)
    reg [1:0] reset_pipe = 2'b11;

    wire rst;
    assign rst = reset_pipe[1];

    always @(posedge clk or posedge reset) begin
        if (reset)
            reset_pipe <= 2'b11;
        else
            reset_pipe <= {reset_pipe[0], 1'b0};
    end

    // ==================================================
    // 2. 晶振分频：100 MHz -> 1 Hz
    // ==================================================

    // 每5000万个周期翻转一次，即每0.5秒翻转一次。
    // 两次翻转构成完整周期，因此输出为1 Hz。
    localparam integer HALF_CYCLES = CLKS_PER_SEC / 2;

    reg [31:0] div_count;
    reg clk_1hz;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            div_count <= 32'd0;

            // 复位后先产生下降沿，
            // 满1秒后才产生第一个有效上升沿。
            clk_1hz <= 1'b1;
        end
        else if (div_count == HALF_CYCLES - 1) begin
            div_count <= 32'd0;
            clk_1hz   <= ~clk_1hz;
        end
        else begin
            div_count <= div_count + 32'd1;
        end
    end

    // ==================================================
    // 3. 行人按键同步和请求锁存
    // ==================================================

    (* ASYNC_REG = "TRUE" *)
    reg request_meta;

    (* ASYNC_REG = "TRUE" *)
    reg request_sync;

    reg request_prev;
    reg request_pending;

    // 在100 MHz时钟下捕获按键，
    // 保留请求，直到1 Hz状态机接收。
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            request_meta    <= 1'b0;
            request_sync    <= 1'b0;
            request_prev    <= 1'b0;
            request_pending <= 1'b0;
        end
        else begin
            request_meta <= pass_request;
            request_sync <= request_meta;
            request_prev <= request_sync;

            // 已经缩短到10秒，或不在绿灯状态：
            // 清除请求。
            if ((state != GREEN) || (countdown <= 8'd10))
                request_pending <= 1'b0;

            // 检测一次按下动作并锁存。
            else if (request_sync && !request_prev)
                request_pending <= 1'b1;
        end
    end

    // ==================================================
    // 4. 状态机：直接使用1 Hz时钟
    // ==================================================

    always @(posedge clk_1hz or posedge rst) begin
        if (rst) begin
            state     <= GREEN;
            countdown <= 8'd90;
        end
        else begin
            case (state)

                GREEN: begin
                    // 行人请求优先，装入10秒。
                    if (request_pending && countdown > 8'd10) begin
                        countdown <= 8'd10;
                    end
                    else if (countdown == 8'd1) begin
                        state     <= YELLOW;
                        countdown <= 8'd5;
                    end
                    else begin
                        countdown <= countdown - 8'd1;
                    end
                end

                YELLOW: begin
                    if (countdown == 8'd1) begin
                        state     <= RED;
                        countdown <= 8'd50;
                    end
                    else begin
                        countdown <= countdown - 8'd1;
                    end
                end

                RED: begin
                    if (countdown == 8'd1) begin
                        state     <= GREEN;
                        countdown <= 8'd90;
                    end
                    else begin
                        countdown <= countdown - 8'd1;
                    end
                end

                default: begin
                    state     <= GREEN;
                    countdown <= 8'd90;
                end

            endcase
        end
    end

    // ==================================================
    // 5. 根据状态控制灯光
    // ==================================================

    always @(*) begin
        motor_green  = 1'b0;
        motor_yellow = 1'b0;
        motor_red    = 1'b0;

        pass_red     = 1'b1;
        pass_green   = 1'b0;

        case (state)

            GREEN: begin
                motor_green = 1'b1;
            end

            YELLOW: begin
                motor_yellow = 1'b1;
            end

            RED: begin
                motor_red  = 1'b1;
                pass_red   = 1'b0;
                pass_green = 1'b1;
            end

            default: begin
                motor_green = 1'b1;
            end

        endcase
    end

endmodule