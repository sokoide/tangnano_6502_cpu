`timescale 1ns / 1ps
module tb_clock_divider;
    logic clk_in = 0, rst_n = 0;
    logic [3:0] div_ratio = 0;
    logic clk_out;
    clock_divider dut (.*);
    always #5 clk_in = ~clk_in;
    initial begin
        for (int ratio = 0; ratio < 16; ratio++) begin
            @(negedge clk_in);
            rst_n = 0;
            div_ratio = 4'(ratio);
            #1;
            assert (!clk_out)
            else $fatal(1, "Reset must drive Low");
            @(negedge clk_in);
            rst_n = 1;
            if (ratio <= 1) begin
                repeat (4) begin
                    @(posedge clk_in);
                    #1;
                    assert (clk_out == (ratio == 1))
                    else $fatal(1, "Bypass/disable High");
                    @(negedge clk_in);
                    #1;
                    assert (!clk_out)
                    else $fatal(1, "Bypass/disable Low");
                end
            end else begin
                for (int period = 0; period < 3; period++) begin
                    int high_count;
                    high_count = 0;
                    for (int phase = 0; phase < ratio; phase++) begin
                        #1;
                        assert (clk_out == (phase < ratio / 2))
                        else $fatal(1, "ratio=%0d phase=%0d", ratio, phase);
                        if (clk_out) high_count++;
                        @(negedge clk_in);
                    end
                    assert (high_count == ratio / 2)
                    else $fatal(1, "Duty mismatch");
                end
            end
        end
        $display("PASS: divider ratios 0..15, reset, period and duty");
        $finish;
    end
    initial begin
        #20000;
        $fatal(1, "divider watchdog");
    end
endmodule
