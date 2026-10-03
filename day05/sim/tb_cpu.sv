// Day 05: CPU Heart (Program Counter) - Logic Testbench
`timescale 1ns / 1ps

module tb_cpu;
    logic clk;
    logic rst_n;
    logic pc_enable;
    logic [15:0] address_bus;
    logic [15:0] debug_pc;

    // Instance of CPU
    cpu dut (
        .clk(clk),
        .rst_n(rst_n),
        .pc_enable(pc_enable),
        .address_bus(address_bus),
        .debug_pc(debug_pc)
    );

    // 50MHz clock (20ns period)
    always #10 clk = ~clk;

    integer error_count = 0;

    // Global watchdog: bounded completion
    initial begin
        #200000;  // 10000 cycles
        $fatal(1, "TIMEOUT: simulation did not finish");
    end

    // Post-posedge sampling helper (stability check after the clock edge)
    task automatic sample ();
        @(posedge clk);
        #1;
    endtask

    task automatic check16(input string name, input logic [15:0] got, input logic [15:0] exp);
        if (got !== exp) begin
            $display("FAIL: %s = 0x%04h (expected 0x%04h)", name, got, exp);
            error_count++;
        end else begin
            $display("PASS: %s = 0x%04h", name, got, exp);
        end
    endtask

    initial begin
        $display("=== Day 05: CPU Program Counter Test ===");

        // Initialize (stimulus setup on negedge)
        clk = 0;
        rst_n = 0;
        pc_enable = 0;

        // Test Case 1: Reset state (reset vector is 0x0200)
        sample ();
        check16("debug_pc (reset)", debug_pc, 16'h0200);
        check16("address_bus (reset)", address_bus, 16'h0200);

        // Release reset on negedge
        @(negedge clk);
        rst_n = 1;

        // Test Case 2: PC must stay at 0x0200 while pc_enable is 0
        sample ();
        sample ();
        check16("debug_pc (gated off)", debug_pc, 16'h0200);

        // Test Case 3: PC increments each cycle while pc_enable is 1
        @(negedge clk);
        pc_enable = 1;
        sample ();
        check16("debug_pc (increment 1)", debug_pc, 16'h0201);
        sample ();
        check16("debug_pc (increment 2)", debug_pc, 16'h0202);

        // Test Case 4: PC stops incrementing when pc_enable returns to 0
        @(negedge clk);
        pc_enable = 0;
        sample ();
        sample ();
        check16("debug_pc (gated off again)", debug_pc, 16'h0202);
        check16("address_bus (gated off again)", address_bus, 16'h0202);

        // Final result
        $display("---------------------------------------");
        if (error_count == 0) begin
            $display("RESULT: ALL TESTS PASSED");
            $finish;
        end else begin
            $fatal(1, "RESULT: %0d TESTS FAILED", error_count);
        end
    end

endmodule
