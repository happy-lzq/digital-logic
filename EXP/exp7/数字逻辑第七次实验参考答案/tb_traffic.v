`timescale 1ns/1ps
module tb_traffic;
    localparam CPS=8, MG=0, MY=1, SG=2, SY=3;
    reg clk=0, rst=1, side_req=0, main_car=0;
    always #5 clk=~clk;
    wire mr,my,mg,sr,sy,sg;
    wire [1:0] state,cars;
    wire [4:0] elapsed;
    integer checks=0,errors=0,cycle=0,scenario=0,fd,i;
    traffic_ctrl #(.CLOCKS_PER_SECOND(CPS)) dut(
        .clk(clk),.rst(rst),.side_req(side_req),.main_car(main_car),
        .main_red(mr),.main_yellow(my),.main_green(mg),
        .side_red(sr),.side_yellow(sy),.side_green(sg),
        .state(state),.elapsed(elapsed),.car_count(cars));
    task check_state;
        input [1:0] expected;
        begin
            checks=checks+1;
            if (state !== expected) begin
                errors=errors+1;
                $display("State mismatch cycle=%0d expected=%0d actual=%0d",
                         cycle,expected,state);
            end
        end
    endtask
    task step;
        input r,q,c;
        begin
            @(negedge clk);rst=r;side_req=q;main_car=c;
            @(posedge clk);#1;
            cycle=cycle+1;
            checks=checks+1;
            case(state)
                MG: if ({mr,my,mg,sr,sy,sg} !== 6'b001100) errors=errors+1;
                MY: if ({mr,my,mg,sr,sy,sg} !== 6'b010100) errors=errors+1;
                SG: if ({mr,my,mg,sr,sy,sg} !== 6'b100001) errors=errors+1;
                SY: if ({mr,my,mg,sr,sy,sg} !== 6'b100010) errors=errors+1;
                default: errors=errors+1;
            endcase
            $fdisplay(fd,"%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d",
                      scenario,cycle,state,dut.waiting,elapsed,cars,side_req,main_car);
        end
    endtask
    task hold_state;
        input integer n;
        input [1:0] expected;
        integer k;
        begin for(k=0;k<n;k=k+1) begin step(0,0,0);check_state(expected);end end
    endtask
    task enter_side;
        begin
            step(1,0,0);check_state(MG);
            step(0,1,0);check_state(MG);
            // Request is withdrawn, but must remain latched internally.
            hold_state(6*CPS-1,MG);step(0,0,0);check_state(MY);
            hold_state(4*CPS-1,MY);step(0,0,0);check_state(SG);
        end
    endtask
    initial begin
        fd=$fopen("trace.csv","w");
        $fdisplay(fd,"scenario,cycle,state,waiting,elapsed,cars,side_req,main_car");
        // Idle and non-SG car pulses must not start a service.
        repeat(12) begin step(0,0,1);check_state(MG);end
        scenario=1;enter_side();
        hold_state(25*CPS-1,SG);step(0,0,0);check_state(SY);
        hold_state(4*CPS-1,SY);step(0,0,0);check_state(MG);
        scenario=2;enter_side();
        hold_state(CPS,SG);step(0,0,1);check_state(SG);
        hold_state(CPS,SG);step(0,0,1);check_state(SG);
        hold_state(CPS+1,SG);step(0,0,1);check_state(SY);
        checks=checks+1;if(cars !== 3) errors=errors+1;
        // Full 4 seconds from the early transition, not a global tick boundary.
        hold_state(4*CPS-1,SY);step(0,0,0);check_state(MG);
        scenario=3;enter_side();
        step(0,0,1);step(0,0,1);check_state(SG);
        hold_state(25*CPS-3,SG);step(0,0,0);check_state(SY);
        scenario=4;
        // Reset from SY, MG with a pending request, MY, and SG.
        step(1,0,0);check_state(MG);
        step(0,1,0);step(1,0,0);check_state(MG);
        hold_state(6*CPS+2,MG);
        step(0,1,0);hold_state(6*CPS-1,MG);step(0,0,0);check_state(MY);
        step(1,0,0);check_state(MG);
        enter_side();step(1,0,0);check_state(MG);
        $fclose(fd);
        $display("==========");
        if(errors==0) $display("TRAFFIC PASS");else $display("TRAFFIC FAIL");
        $display("checks=%0d; failed_checks=%0d",checks,errors);
        $display("==========");$finish;
    end
    initial begin #100000;$display("TRAFFIC FAIL: TIMEOUT");$finish;end
endmodule
