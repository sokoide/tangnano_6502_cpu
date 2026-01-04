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

    initial begin
        $display("=== Day 05: CPU Program Counter Test ===");

        // Initialize
        clk = 0;
        rst_n = 0;
        pc_enable = 0;

        // Test Case 1: Reset state
        #25;
        if (debug_pc !== 16'h0200) begin
            $display("FAIL: Reset PC should be 0x8000, got 0x%h", debug_pc);
            error_count++;
        end else begin
            $display("PASS: Reset PC is 0x8000");
        end

        // Release reset
        rst_n = 1;
        #20;

        // Test Case 2: PC should stay when pc_enable is 0
        if (debug_pc !== 16'h0200) begin
            $display("FAIL: PC should stay at 0x8000 when disabled, got 0x%h", debug_pc);
            error_count++;
        end else begin
            $display("PASS: PC stays when disabled");
        end

        // Test Case 3: PC should increment when pc_enable is 1
        pc_enable = 1;
        #20;  // 1st clock
        if (debug_pc !== 16'h0201) begin
            $display("FAIL: PC should be 0x8001, got 0x%h", debug_pc);
            error_count++;
        end else begin
            $display("PASS: PC incremented to 0x8001");
        end

        #20;  // 2nd clock
        if (debug_pc !== 16'h0202) begin
            $display("FAIL: PC should be 0x8002, got 0x%h", debug_pc);
            error_count++;
        end else begin
            $display("PASS: PC incremented to 0x8002");
        end

        // Test Case 4: PC should stop incrementing when pc_enable is 0 again
        pc_enable = 0;
        #20;
        if (debug_pc !== 16'h0202) begin
            $display("FAIL: PC should stay at 0x8002, got 0x%h", debug_pc);
            error_count++;
        end else begin
            $display("PASS: PC stopped incrementing");
        end

        // Final result
        $display("---------------------------------------");
        if (error_count == 0) begin
            $display("RESULT: ALL TESTS PASSED");
        end else begin
            $display("RESULT: %0d TESTS FAILED", error_count);
        end
        $display("---------------------------------------");

        $finish;
    end

endmodule
