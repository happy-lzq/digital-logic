`timescale 1ns/1ps
// D latch: transparent while clk is high, holds while clk is low.
module dlatch(input wire clk, input wire d, output reg q);
    always @(*) begin
        if (clk) q <= d;
    end
endmodule

// D flip-flop: samples d only on a rising clock edge.
module dff(input wire clk, input wire d, output reg q);
    always @(posedge clk) begin
        q <= d;
    end
endmodule
