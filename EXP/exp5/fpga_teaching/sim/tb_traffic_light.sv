`timescale 1ns/1ps
module tb_traffic_light;
    reg clk=0,rst_n=1,pass_request=0;
    wire [7:0] clock;
    wire motor_green,motor_yellow,motor_red,pass_red,pass_green;
    integer checks=0,phase;
    traffic_light dut(.*);
    always #5 clk=~clk;
    reg [47:0] light_name;
    always @(*)
        if(motor_green) light_name="GREEN";
        else if(motor_yellow) light_name="YELLOW";
        else light_name="RED";
    task check(input bit ok,input string label_text);
        begin checks++;if(!ok)$fatal(1,"FAIL %s at %0t, count=%0d",label_text,$time,clock);end
    endtask
    task tick(input integer n);repeat(n)begin @(posedge clk);#1;end endtask
    task reset;
        begin
            @(negedge clk);#2;rst_n=0;pass_request=0;#1;
            check(clock===90 && motor_green===1 && pass_red===1,"async reset before clock");
            @(negedge clk);rst_n=1;
        end
    endtask
    always @(negedge clk) if(rst_n)begin
        if(!(({motor_red,motor_yellow,motor_green,pass_red,pass_green}===5'b00110)||
             ({motor_red,motor_yellow,motor_green,pass_red,pass_green}===5'b01010)||
             ({motor_red,motor_yellow,motor_green,pass_red,pass_green}===5'b10001)))
             $fatal(1,"illegal light pairing");
        if((^clock===1'bx)||clock==0||clock>90)$fatal(1,"invalid countdown");
    end
    initial begin
        $timeformat(-9,0," ns",0);
        #2;rst_n=0;#1;
        check(clock===90,"initial reset");
        @(negedge clk);rst_n=1;
        tick(9);check(clock==90,"nine clocks hold");
        tick(1);check(clock==89,"tenth clock decrements");
        tick(889);check(clock==1&&motor_green,"green last clock");
        tick(1);check(clock==5&&motor_yellow,"900 clocks green duration");
        $display("GREEN_DURATION_PASS: 9000 ns");
        tick(49);check(clock==1&&motor_yellow,"yellow last clock");
        tick(1);check(clock==50&&motor_red,"50 clocks yellow duration");
        $display("YELLOW_DURATION_PASS: 500 ns");
        tick(499);check(clock==1&&motor_red,"red last clock");
        tick(1);check(clock==90&&motor_green,"500 clocks red duration");
        $display("RED_DURATION_PASS: 5000 ns");
        // Complete natural cycle from one registered GREEN entry to the next.
        tick(900);check(clock==5&&motor_yellow,"full natural green interval");
        tick(50);check(clock==50&&motor_red,"full natural yellow interval");
        tick(500);check(clock==90&&motor_green,"full natural red interval");
        // Green request greater than 10, then held request at/below 10.
        reset;tick(53);
        @(negedge clk);pass_request=1;
        tick(1);check(clock==10,"85 to 10 request");
        $display("REQUEST_PASS: 85 to 10");
        tick(10);check(clock==9,"held request does not freeze at 10");
        tick(10);check(clock==8,"request below 10 ignored");
        @(negedge clk);pass_request=0;
        tick(80);check(clock==5&&motor_yellow,"shortened green then yellow");
        @(negedge clk);pass_request=1;
        tick(50);check(clock==50&&motor_red,"yellow request ignored");
        tick(500);check(clock==90&&motor_green,"red request ignored");
        @(negedge clk);pass_request=0;
        // At count 11, every divider phase must start a fresh full 10T interval.
        for(phase=0;phase<10;phase++)begin
            reset;tick(790+phase);
            @(negedge clk);pass_request=1;
            tick(1);check(clock==10,"11 boundary clamp");
            tick(99);check(clock==1&&motor_green,"99 clocks after request");
            tick(1);check(clock==5&&motor_yellow,"100 clocks after request");
        end
        reset;tick(800);
        @(negedge clk);pass_request=1;
        tick(10);check(clock==9,"request at exactly 10 ignored");
        @(negedge clk);pass_request=0;
        reset;tick(900);reset; // reset from yellow
        tick(950);reset;      // reset from red
        $display("SIM_PASS: %0d directed checks, continuous pairing/countdown checks",checks);
        $finish;
    end
    initial begin #200000;$fatal(1,"watchdog timeout");end
endmodule
