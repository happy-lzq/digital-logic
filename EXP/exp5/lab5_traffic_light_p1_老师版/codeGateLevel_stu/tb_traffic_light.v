`timescale 1ns/1ns
module tb_traffic_light;

reg        clk;
reg        rst_n;
reg        pass_request;
wire [7:0] clock;
wire       motor_red;
wire       motor_yellow;
wire       motor_green;
wire       pass_red;
wire       pass_green;
time       t_release;
time       t_mark;

//------------------ instantiate the DUT ------------------
traffic_light u_traffic_light (
    .clk         (clk),
    .rst_n       (rst_n),
    .pass_request(pass_request),
    .clock       (clock),
    .motor_red   (motor_red),
    .motor_yellow(motor_yellow),
    .motor_green (motor_green),
    .pass_red    (pass_red),
    .pass_green  (pass_green)
);

//------------------ 100MHz clock (10ns period) ------------------
initial clk = 1'b0;
always #5 clk = ~clk;

//------------------ light name decode (view as ASCII in waveform) ------------------
reg [8*6-1:0] light_name;
always @(*) begin
    if (motor_green)       light_name = "GREEN";
    else if (motor_yellow) light_name = "YELLOW";
    else if (motor_red)    light_name = "RED";
    else                   light_name = "NONE";
end

//------------------ console output 1: light switching (with crosswalk pairing) ------------------
always @(posedge motor_green)  if (rst_n)
    $strobe("[%0t ns] >>> LIGHT SWITCH: motor GREEN  / pass RED,   countdown reload = %0d (x10 clk)", $time, clock);
always @(posedge motor_yellow) if (rst_n)
    $strobe("[%0t ns] >>> LIGHT SWITCH: motor YELLOW / pass RED,   countdown reload = %0d (x10 clk)", $time, clock);
always @(posedge motor_red)    if (rst_n)
    $strobe("[%0t ns] >>> LIGHT SWITCH: motor RED    / pass GREEN, countdown reload = %0d (x10 clk)", $time, clock);

//------------------ console output 2: pedestrian button events ------------------
always @(posedge pass_request)
    $strobe("[%0t ns] !!! Pedestrian button PRESSED: motor=%s, remaining=%0d (x10 clk)",
            $time, light_name, clock);

//------------------ background assertion: never green/green or red/red ------------------
always @(posedge clk) begin
    if (rst_n) begin
        if ((motor_green || motor_yellow) && pass_green)
            $display("[%0t ns] FATAL: motor GREEN/YELLOW but pass GREEN!", $time);
        if (motor_red && pass_red)
            $display("[%0t ns] FATAL: motor RED but pass RED!", $time);
    end
end

//------------------ tasks: short press (1 clk) / long press (3 clk) ------------------
task press_button;
    begin
        @(negedge clk) pass_request = 1'b1;   // drive while clk is low, avoid the sampling edge
        @(negedge clk) pass_request = 1'b0;
    end
endtask

task press_button_long;
    begin
        @(negedge clk) pass_request = 1'b1;
        repeat(3) @(negedge clk);
        pass_request = 1'b0;
    end
endtask

//------------------ tasks: check "shortened to 10" / check "unchanged" ------------------
task check_shorten(input [8*4-1:0] tag);
    begin
        #1;
        if (motor_green && (clock == 8'd10))
            $display("[%0t ns] [%0s] CHECK PASS: green shortened, countdown = %0d (x10 clk).", $time, tag, clock);
        else
            $display("[%0t ns] [%0s] CHECK FAIL: motor=%s, countdown=%0d, expected 10.", $time, tag, light_name, clock);
    end
endtask

task check_keep(input [8*4-1:0] tag, input [7:0] exp_cnt);
    begin
        #1;
        if (clock == exp_cnt)
            $display("[%0t ns] [%0s] CHECK PASS: countdown unchanged = %0d (x10 clk).", $time, tag, clock);
        else
            $display("[%0t ns] [%0s] CHECK FAIL: motor=%s, countdown=%0d, expected %0d.", $time, tag, light_name, clock, exp_cnt);
    end
endtask

//------------------ main stimulus ------------------
initial begin
    $display("============================================================");
    $display("   TRAFFIC LIGHT SIM (v3: 8 button presses over full run)");
    $display("============================================================");

    //---------- asynchronous reset at power-on, held for 5 clocks ----------
    rst_n        = 1'b0;
    pass_request = 1'b0;
    repeat(5) @(posedge clk);
    rst_n     = 1'b1;
    t_release = $time;
    $display("[%0t ns] Reset released. Initial: motor GREEN / pass RED, countdown=%0d", $time, clock);

    //---------- S1: check clock counts once every 10 clk ----------
    $display("------------------------------------------------------------");
    $display("[%0t ns] [SCENARIO 1] Check clock counts once per 10 clk (90 -> 89 in 100 ns)", $time);
    #1;
    if (!(motor_green && pass_red && (clock == 8'd90)))
        $display("[%0t ns] [SCENARIO 1] CHECK FAIL: motor_green=%b pass_red=%b countdown=%0d, expected 1/1/90.",
                 $time, motor_green, pass_red, clock);
    wait (clock == 8'd89);
    if (($time - t_release) == 100)
        $display("[%0t ns] [SCENARIO 1] CHECK PASS: 90 -> 89 took %0d ns = 10 clk, x10 counting OK.",
                 $time, ($time - t_release));
    else
        $display("[%0t ns] [SCENARIO 1] CHECK FAIL: 90 -> 89 took %0d ns, expected 100 ns.",
                 $time, ($time - t_release));

    //---------- S2: press #1, green remaining 85 (>10), shorten to 10 ----------
    $display("------------------------------------------------------------");
    wait (motor_green && (clock == 8'd85));
    $display("[%0t ns] [SCENARIO 2] Press #1: green remaining=%0d (>10), expect shorten to 10", $time, clock);
    press_button;
    check_shorten("S2");

    //---------- S3: press #2, green remaining 8 (<10), keep unchanged ----------
    $display("------------------------------------------------------------");
    wait (motor_green && (clock == 8'd8));
    $display("[%0t ns] [SCENARIO 3] Press #2: green remaining=%0d (<10), expect NO change", $time, clock);
    press_button;
    check_keep("S3", 8'd8);
    wait (motor_green && (clock == 8'd7));

    //---------- S4: press #3 during YELLOW, ignored ----------
    $display("------------------------------------------------------------");
    wait (motor_yellow && (clock == 8'd4));
    $display("[%0t ns] [SCENARIO 4] Press #3 during motor YELLOW, expect NO effect", $time);
    press_button;
    check_keep("S4", 8'd4);

    //---------- S5: press #4 during RED, ignored, crosswalk stays green ----------
    $display("------------------------------------------------------------");
    wait (motor_red && (clock == 8'd48));
    $display("[%0t ns] [SCENARIO 5] Press #4 during motor RED (pass GREEN), expect NO effect", $time);
    press_button;
    #1;
    if (motor_red && pass_green && (clock == 8'd48))
        $display("[%0t ns] [S5  ] CHECK PASS: still motor RED / pass GREEN, countdown=%0d, button ignored.", $time, clock);
    else
        $display("[%0t ns] [S5  ] CHECK FAIL: motor=%s pass_green=%b countdown=%0d, expected RED/1/48.",
                 $time, light_name, pass_green, clock);

    //---------- S6: press #5, long press (3 clk) at remaining 60, shorten to 10 without freeze ----------
    $display("------------------------------------------------------------");
    wait (motor_green && (clock == 8'd60));
    $display("[%0t ns] [SCENARIO 6] Press #5: LONG press (3 clk) with remaining=%0d, expect 10 then normal count", $time, clock);
    press_button_long;
    check_shorten("S6");
    wait (motor_green && (clock == 8'd9));   // a long-press freeze at 10 would hit the watchdog
    $display("[%0t ns] [S6  ] CHECK PASS: after release, natural decrement 10 -> 9, no freeze.", $time);

    //---------- S7: press #6, boundary value 11 -> shorten to 10 ----------
    $display("------------------------------------------------------------");
    wait (motor_green && (clock == 8'd11));
    $display("[%0t ns] [SCENARIO 7] Press #6: boundary remaining=%0d (just >10), expect shorten to 10", $time, clock);
    press_button;
    check_shorten("S7");

    //---------- S8: press #7, boundary value 10 (right after #6), keep unchanged ----------
    $display("------------------------------------------------------------");
    wait (motor_green && (clock == 8'd10));  // condition already true, press again immediately
    $display("[%0t ns] [SCENARIO 8] Press #7: boundary remaining=%0d (not >10), expect NO change", $time, clock);
    press_button;
    check_keep("S8", 8'd10);
    wait (motor_green && (clock == 8'd9));

    //---------- S9: press #8, green remaining 5, keep unchanged ----------
    $display("------------------------------------------------------------");
    wait (motor_green && (clock == 8'd5));
    $display("[%0t ns] [SCENARIO 9] Press #8: green remaining=%0d (<10), expect NO change", $time, clock);
    press_button;
    check_keep("S9", 8'd5);
    wait (motor_green && (clock == 8'd4));

    //---------- S10: no button, measure a full natural cycle ----------
    $display("------------------------------------------------------------");
    $display("[%0t ns] [SCENARIO 10] Free running full cycle, measuring GREEN/YELLOW/RED durations...", $time);
    @(posedge motor_green);  t_mark = $time;
    @(posedge motor_yellow);
    if (($time - t_mark) == 9000)
        $display("[%0t ns] [S10 ] CHECK PASS: motor GREEN lasted %0d ns = 900 clk.", $time, ($time - t_mark));
    else
        $display("[%0t ns] [S10 ] CHECK FAIL: motor GREEN lasted %0d ns, expected 9000 ns.", $time, ($time - t_mark));
    t_mark = $time;
    @(posedge motor_red);
    if (($time - t_mark) == 500)
        $display("[%0t ns] [S10 ] CHECK PASS: motor YELLOW lasted %0d ns = 50 clk.", $time, ($time - t_mark));
    else
        $display("[%0t ns] [S10 ] CHECK FAIL: motor YELLOW lasted %0d ns, expected 500 ns.", $time, ($time - t_mark));
    t_mark = $time;
    @(posedge motor_green);
    if (($time - t_mark) == 5000)
        $display("[%0t ns] [S10 ] CHECK PASS: motor RED (pass GREEN) lasted %0d ns = 500 clk.", $time, ($time - t_mark));
    else
        $display("[%0t ns] [S10 ] CHECK FAIL: motor RED lasted %0d ns, expected 5000 ns.", $time, ($time - t_mark));

    repeat(20) @(posedge clk);
    $display("============================================================");
    $display("   SIMULATION FINISHED: 8 presses, all scenarios done.");
    $display("============================================================");
    $finish;
end

//------------------ timeout watchdog ------------------
initial begin
    #50000;
    $display("[%0t ns] ERROR: simulation TIMEOUT, please check the design!", $time);
    $finish;
end

endmodule
