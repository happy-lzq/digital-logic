`timescale 1ns/1ps
// 题 2：rst 为高电平同步复位；两个寄存器使用非阻塞赋值。
module pipeline2(input wire clk, input wire rst, input wire d,
                 output reg q1, output reg q2);
    always @(posedge clk) begin
        // TODO 2：复位时清零；否则 q1 采样 d，q2 采样旧 q1。
    end
endmodule

// 题 3A：同步复位，固定模 10，不需要使能和参数。
module counter_sync(input wire clk, input wire rst, output reg [3:0] count);
    always @(posedge clk) begin
        // TODO 3A：复位优先；9 后回到 0；其余情况加 1。
    end
endmodule

// 题 3B：复用题 3A 的计数规则，改变复位响应方式。
module counter_async(input wire clk, input wire rst, output reg [3:0] count);
    always @(posedge clk or posedge rst) begin
        // TODO 3B：rst 拉高时清零；未复位时在上升沿计数。
    end
endmodule
