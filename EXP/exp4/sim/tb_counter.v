`timescale 1ns/1ps
module tb_counter;
    reg clk = 0;
    always #5 clk = ~clk;
    reg rst = 1;
    wire [3:0] count_sync;
    counter_sync dut_sync(.clk(clk), .rst(rst), .count(count_sync));
    reg [3:0] expected_sync = 0;
    integer cycles = 0, checks = 0;
    integer sync_errors = 0;

    task check_outputs;
        begin
            checks = checks + 1;
            if (count_sync !== expected_sync) begin
                sync_errors = sync_errors + 1;
                if (sync_errors <= 5)
                    $display("Mismatch t=%0t count_sync=%0d expected=%0d",
                             $time,count_sync,expected_sync);
            end

        end
    endtask

    task advance_counts;
        begin
            if (rst) begin
                expected_sync = 0;
            end else begin
                expected_sync = (expected_sync == 9) ? 0 : expected_sync + 1;
            end
            cycles = cycles + 1;
        end
    endtask

    task step;
        input reset_value;
        begin
            @(negedge clk);
            rst = reset_value;
            #1; check_outputs();
            @(posedge clk);
            advance_counts();
            #1; check_outputs();
        end
    endtask

    initial begin
        // At 5 ns, reset establishes known outputs for the synchronous design.
        step(1);
        repeat (11) step(0); // Includes 8 -> 9 -> 0.
        step(0);             // At 135 ns count_sync is 2.
        step(1);             // Reset rises at 140 ns, between rising edges.
        step(0);             // Reset falls at 150 ns; count at 155 ns.
        #6; rst = 1;         // Short reset pulse: 162 ns to 164 ns.
        #1; check_outputs();
        #1; rst = 0;
        #0.5; check_outputs(); // Releasing reset alone does not increment.
        @(posedge clk);
        advance_counts();
        #1; check_outputs();  // The synchronous design missed the short pulse.
        step(1);             // A full reset brings the synchronous counter to zero.
        step(0);
        // Required test: only counter_sync is instantiated.
        $display("==========");
        if (sync_errors == 0) $display("COUNTER_SYNC PASS");
        else $display("COUNTER_SYNC FAIL");
        $display("cycles=%0d; checks=%0d; failed_checks=%0d",
                 cycles, checks, sync_errors);
        $display("==========");
        $finish;
    end
    initial begin
        #10000;
        $display("==========\nCOUNTER_SYNC FAIL\nReason: TIMEOUT\n==========");
        $finish;
    end
endmodule
