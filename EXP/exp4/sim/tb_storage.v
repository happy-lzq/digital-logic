`timescale 1ns/1ps
module tb_storage;
    reg clk = 0, d = 0;
    wire q_latch, q_dff;
    integer checks = 0, errors = 0;
    dlatch u_latch(.clk(clk), .d(d), .q(q_latch));
    dff u_dff(.clk(clk), .d(d), .q(q_dff));

    task check;
        input expected_latch, expected_dff;
        begin
            #1; // Wait for nonblocking assignments to complete.
            checks = checks + 1;
            if ({q_latch, q_dff} !== {expected_latch, expected_dff}) begin
                errors = errors + 1;
                $display("FAIL t=%0t clk=%b d=%b latch=%b dff=%b",
                         $time, clk, d, q_latch, q_dff);
                $display("Expected: latch=%b dff=%b",
                         expected_latch, expected_dff);
            end
            #4;
        end
    endtask

    initial begin
        // Change d before clock edges, avoiding stimulus races.
        #5; clk = 1; check(0, 0); // 5 ns: first rising edge.
        d = 1; check(1, 0);      // 10 ns: high level, latch follows.
        d = 0; check(0, 0);      // 15 ns: high level, latch follows.
        d = 1; check(1, 0);      // 20 ns: dff still holds.
        clk = 0; check(1, 0);    // 25 ns: falling edge, both hold.
        d = 0; check(1, 0);      // 30 ns: low level, both hold.
        d = 1; check(1, 0);      // 35 ns: prepare before rising edge.
        clk = 1; check(1, 1);    // 40 ns: dff samples d=1.
        d = 0; check(0, 1);      // 45 ns: outputs differ again.
        clk = 0; check(0, 1);    // 50 ns: both hold.
        d = 1; check(0, 1);      // 55 ns: low level, both hold.
        d = 0; check(0, 1);      // 60 ns: prepare d=0.
        clk = 1; check(0, 0);    // 65 ns: dff samples d=0.
        $display("==========");
        if (errors == 0) $display("STORAGE PASS");
        else $display("STORAGE FAIL");
        $display("checks=%0d; failed_checks=%0d", checks, errors);
        $display("==========");
        $finish;
    end
    initial begin
        #1000;
        $display("==========\nSTORAGE FAIL\nReason: TIMEOUT\n==========");
        $finish;
    end
endmodule
