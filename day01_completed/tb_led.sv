`timescale 1ns / 1ps

module tb_led;
    logic clk = 0;
    logic led;
    top dut (
        .clk(clk),
        .led(led)
    );
    always #1 clk = ~clk;

    initial begin
        #0.1;
        for (int unsigned cycle = 0; cycle <= (1 << 25); cycle++) begin
            // Board wrappers retain their respective LED output polarity.
`ifdef BOARD_20K
            if (led !== ((cycle >> 24) & 1)) $fatal(1, "LED mismatch at %0d", cycle);
`else
            if (led !== (!((cycle >> 24) & 1))) $fatal(1, "LED mismatch at %0d", cycle);
`endif
            if (cycle != (1 << 25)) begin
                @(posedge clk);
                #0.1;
            end
        end
        $display("PASS: LED bit24, both transitions and counter wrap");
        $finish;
    end

    initial begin
        #70000000;
        $fatal(1, "LED test timeout");
    end
endmodule
