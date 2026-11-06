`timescale 1ns/1ps
// 第二题
module tb_pipeline;
    reg clk = 0;
    always #5 clk = ~clk;
    reg rst = 1, d = 0;
    wire q1, q2;
    pipeline2 dut(.clk(clk), .rst(rst), .d(d), .q1(q1), .q2(q2));
    reg expected_q1 = 0, expected_q2 = 0;
    integer cycles = 0, checks = 0, errors = 0;
    integer i;

    task check_outputs;
        begin
            checks = checks + 2;
            if (q1 !== expected_q1) begin
                errors = errors + 1;
                if (errors <= 5)
                    $display("Mismatch t=%0t q1=%b expected=%b",$time,q1,expected_q1);
            end
            if (q2 !== expected_q2) begin
                errors = errors + 1;
                if (errors <= 5)
                    $display("Mismatch t=%0t q2=%b expected=%b",$time,q2,expected_q2);
            end
        end
    endtask

    task step;
        input reset_value, data_value;
        begin
            @(negedge clk);
            rst = reset_value;
            d = data_value;
            #1; check_outputs();
            @(posedge clk);
            if (reset_value) begin
                expected_q1 = 0;
                expected_q2 = 0;
            end else begin
                // Reference model deliberately updates the old second stage first.
                expected_q2 = expected_q1;
                expected_q1 = data_value;
            end
            #1; check_outputs();
            cycles = cycles + 1;
            #1; d = ~data_value;
            #1; check_outputs();
        end
    endtask

    initial begin
        // The rising edge at 5 ns initializes both outputs by reset.
        step(1,1);
        for (i=0;i<10;i=i+1) step(0,(i+1)%2);
        step(1,1);
        $display("==========");
        if (errors) $display("PIPELINE FAIL");
        else $display("PIPELINE PASS");
        $display("cycles=%0d; checks=%0d; failed_checks=%0d",cycles,checks,errors);
        $display("==========");
        $finish;
    end
    initial begin
        #10000;
        $display("==========\nPIPELINE FAIL\nReason: TIMEOUT\n==========");
        $finish;
    end
endmodule
