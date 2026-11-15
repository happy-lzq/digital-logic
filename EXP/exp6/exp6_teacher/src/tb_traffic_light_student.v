`timescale 1ns / 1ps

// 学生波形版：只提供测试输入，由学生观察波形判断功能。
// clk周期10 ns，CLKS_PER_SEC取10，所以仿真中的1T为100 ns。
module tb_traffic_light_student;
    reg clk = 1'b0;
    reg reset;
    reg pass_request;
    reg [3:0] stage;  // 测试场景编号，只用于定位截图，不参与状态机控制。
    wire motor_green, motor_yellow, motor_red, pass_red, pass_green;

    traffic_light #(.CLKS_PER_SEC(10)) dut (
        .clk(clk), .reset(reset), .pass_request(pass_request),
        .motor_green(motor_green), .motor_yellow(motor_yellow),
        .motor_red(motor_red), .pass_red(pass_red), .pass_green(pass_green)
    );

    // 读取内部信号用于观察，不改动FPGA模块端口。
    wire [1:0] state = dut.state;
    wire [7:0] countdown = dut.countdown;
    wire clk_1hz = dut.clk_1hz;
    wire rst = dut.rst;

    always #5 clk = ~clk;

    initial begin
        stage = 0; reset = 1; pass_request = 0;
        #40 reset = 0;

        // 场景1：无请求，观察绿90T、黄5T、红50T的完整循环。
        stage = 1;
        #14560;

        // 场景2：绿灯剩余85T时发出请求，应在有效计时边沿装入10。
        stage = 2;
        #500 pass_request = 1;
        #20  pass_request = 0;
        #80;

        // 场景3：分别在剩余10T和8T时请求，不应重装或暂停计时。
        stage = 3;
        pass_request = 1;
        #20  pass_request = 0;
        #180 pass_request = 1;
        #20  pass_request = 0;
        #780;

        // 场景4：黄灯期间请求，不改变正常计时。
        stage = 4;
        pass_request = 1;
        #20  pass_request = 0;
        #480;

        // 场景5：红灯期间请求，不改变正常计时。
        stage = 5;
        pass_request = 1;
        #20  pass_request = 0;
        #280;

        // 场景6：红灯运行中复位，立即恢复车辆绿灯、行人红灯及90T。
        stage = 6;
        reset = 1;
        #40 reset = 0;
        #300;
        $display("STUDENT WAVEFORM FINISHED: time=%0t", $time);
        $finish;
    end
endmodule
