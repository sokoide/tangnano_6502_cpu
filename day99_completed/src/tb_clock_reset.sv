`timescale 1ns / 1ps
module tb_clock_reset;
`ifdef BOARD_20K
    localparam bit BOARD_20K = 1'b1;
`else
    localparam bit BOARD_20K = 1'b0;
`endif
    logic xtal = 0, button_n = 0;
    always #18.518519 xtal = ~xtal;
    wire p, m, pl, ml;
    wire ready_n = button_n && pl && ml;
    wire pr, mr;
    platform_clocks #(
        .BOARD_20K(BOARD_20K)
    ) clocks (
        .clkin(xtal),
        .rst_n(button_n),
        .pixel_clk(p),
        .memory_clk(m),
        .pixel_locked(pl),
        .memory_locked(ml)
    );
    reset_sync pixel (
        .clk(p),
        .ready_n(ready_n),
        .rst_n(pr)
    );
    reset_sync memory (
        .clk(m),
        .ready_n(ready_n),
        .rst_n(mr)
    );
    task release_check;
        wait (ready_n);
        if (pr || mr) $fatal(1, "Reset released before local edges");
        @(posedge p);
        #1;
        if (pr) $fatal(1, "Pixel reset released on first edge");
        @(posedge p);
        #1;
        if (!pr) $fatal(1, "Pixel reset not released on second edge");
        if (!mr) $fatal(1, "Memory reset did not release");
    endtask
    realtime last_p, last_m;
    initial begin
        #100;
        button_n = 1;
        release_check();
        @(posedge p);
        last_p = $realtime;
        @(posedge p);
        if ($realtime - last_p < 111.10 || $realtime - last_p > 111.12) $fatal(1, "Pixel period");
        @(posedge m);
        last_m = $realtime;
        @(posedge m);
`ifdef BOARD_20K
        if ($realtime - last_m < 24.68 || $realtime - last_m > 24.70) $fatal(1, "Memory period");
`else
        if ($realtime - last_m < 37.02 || $realtime - last_m > 37.05) $fatal(1, "Memory period");
`endif
        clocks.pixel_pll.lock_available = 0;
        @(posedge xtal);
        #1;
        if (pr || mr || ready_n) $fatal(1, "Lock loss did not assert both resets");
        clocks.pixel_pll.lock_available = 1;
        release_check();
        #3;
        button_n = 0;
        #1;
        if (pr || mr) $fatal(1, "Button reset assertion");
        $display("PASS PLL periods/lock wait/loss/relock and local reset release");
        $finish;
    end
    initial begin
        #10000;
        $fatal(1, "Clock timeout");
    end
endmodule
