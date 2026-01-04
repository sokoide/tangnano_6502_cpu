// Day 06: Data Movement (LDA Immediate) - Logic Testbench
`timescale 1ns / 1ps

module tb_cpu;
    logic clk;
    logic rst_n;
    logic [7:0] data_in;
    logic [15:0] address_bus;
    logic [7:0] debug_a;
    logic [15:0] debug_pc;

    // Simple memory model
    logic [7:0] mem[65536];

    // Instance of CPU
    cpu dut (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .address_bus(address_bus),
        .debug_a(debug_a),
        .debug_pc(debug_pc)
    );

    // Memory read
    assign data_in = mem[address_bus];

    // 50MHz clock
    always #10 clk = ~clk;

    integer error_count = 0;

    initial begin
        $display("=== Day 06: LDA Immediate Test ===");

        // Initialize memory with test program
        // LDA #$42, NOP, LDA #$55
        mem[16'h0200] = 8'hA9;  // LDA imm
        mem[16'h0201] = 8'h42;  // operand
        mem[16'h0202] = 8'hEA;  // NOP
        mem[16'h0203] = 8'hA9;  // LDA imm
        mem[16'h0204] = 8'h55;  // operand

        // Initialize signals
        clk = 0;
        rst_n = 0;

        // Test Case 1: Reset
        #25;
        rst_n = 1;
        #20;

        // Wait for LDA #$42 execution (3 states usually: Fetch, Decode, Execute)
        repeat (3) @(posedge clk);
        #5;
        if (debug_a !== 8'h42) begin
            $display("FAIL: A should be 0x42 after LDA #$42, got 0x%h", debug_a);
            error_count++;
        end else begin
            $display("PASS: A is 0x42");
        end

        // Wait for NOP
        repeat (2) @(posedge clk);
        if (debug_a !== 8'h42) begin
            $display("FAIL: A should remain 0x42 after NOP, got 0x%h", debug_a);
            error_count++;
        end else begin
            $display("PASS: A remains 0x42 after NOP");
        end

        // Wait for LDA #$55
        repeat (3) @(posedge clk);
        #5;
        if (debug_a !== 8'h55) begin
            $display("FAIL: A should be 0x55 after second LDA, got 0x%h", debug_a);
            error_count++;
        end else begin
            $display("PASS: A is 0x55");
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
