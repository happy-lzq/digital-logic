`timescale 1ns/1ps
module tb_minisys;
    reg clk=0,reset=0,request_btn=0;
    wire motor_red,motor_yellow,motor_green,pass_red,pass_green;
    integer pulses=0,checks=0;
    traffic_light_minisys #(.CLK_HZ(100),.UNIT_CYCLES(100),.DEBOUNCE_CYCLES(4)) dut(.*);
    always #5 clk=~clk;
    always @(posedge clk) if(dut.u_board.request_pulse) pulses++;
    task tick(input integer n);repeat(n)begin @(posedge clk);#1;end endtask
    task check(input bit ok,input string msg);begin checks++;if(!ok)$fatal(1,"FAIL %s",msg);end endtask
    initial begin
        #2;reset=1;#1;
        check({motor_red,motor_yellow,motor_green,pass_red,pass_green}===5'b00110,"active-high S6 asynchronous reset");
        check(dut.u_board.u_core.clock===90,"board reset countdown");
        @(negedge clk);reset=0;tick(3);
        @(negedge clk);request_btn=1;
        tick(1);@(negedge clk);request_btn=0;tick(8);
        check(pulses==0,"short bounce rejected");
        @(negedge clk);request_btn=1;tick(10);
        check(pulses==1,"active-high S1 stable press accepted");
        check(dut.u_board.u_core.clock==10,"request shortens green");
        tick(110);
        check(pulses==1,"held button gives one request");
        check(dut.u_board.u_core.clock==9,"board scaled time unit continues");
        @(negedge clk);request_btn=0;tick(10);
        @(negedge clk);request_btn=1;tick(10);
        check(pulses==2,"release rearms button");
        #2;reset=1;#1;
        check(dut.u_board.u_core.clock===90 && motor_green===1,"reset works during request");
        $display("BOARD_SIM_PASS: %0d checks",checks);$finish;
    end
    initial begin #10000;$fatal(1,"board timeout");end
endmodule
