// Day 07: Data Movement (Register Transfers) - Logic Testbench
`timescale 1ns / 1ps

module tb_cpu;
    logic clk;
    logic rst_n;
    logic pc_enable;
    logic [7:0] data_in;
    logic [15:0] address_bus;
    logic [7:0] debug_a, debug_x, debug_y;
    logic [15:0] debug_pc;

    // Simple memory model
    logic [7:0] mem[65536];

    // Instance of CPU
    cpu dut (
        .clk(clk),
        .rst_n(rst_n),
        .pc_enable(pc_enable),
        .data_in(data_in),
        .address_bus(address_bus),
        .debug_a(debug_a),
        .debug_x(debug_x),
        .debug_y(debug_y),
        .debug_pc(debug_pc)
    );

    assign data_in = mem[address_bus];

    // 50MHz clock
    always #10 clk = ~clk;

    integer error_count = 0;

    initial begin
        $display("=== Day 07: Register Transfer Test ===");

        // Test program:
        // LDA #$42, TAX, INX, TAY, INY, TXA, TYA
        mem[16'h0200] = 8'hA9;  // LDA imm
        mem[16'h0201] = 8'h42;
        mem[16'h0202] = 8'hAA;  // TAX
        mem[16'h0203] = 8'hE8;  // INX
        mem[16'h0204] = 8'hA8;  // TAY
        mem[16'h0205] = 8'hC8;  // INY
        mem[16'h0206] = 8'h8A;  // TXA
        mem[16'h0207] = 8'h98;  // TYA

        clk = 0;
        rst_n = 0;
        pc_enable = 1;
        #25;
        rst_n = 1;
        #20;

        // LDA #$42
        repeat (2) @(posedge clk);
        #5;
        if (debug_a !== 8'h42) begin
            $display("FAIL: A should be 0x42, got 0x%h", debug_a);
            error_count++;
        end

        // TAX
        @(posedge clk);
        #5;
        if (debug_x !== 8'h42) begin
            $display("FAIL: X should be 0x42 after TAX, got 0x%h", debug_x);
            error_count++;
        end

        // INX
        @(posedge clk);
        #5;
        if (debug_x !== 8'h43) begin
            $display("FAIL: X should be 0x43 after INX, got 0x%h", debug_x);
            error_count++;
        end

        // TAY
        @(posedge clk);
        #5;
        if (debug_y !== 8'h42) begin
            $display("FAIL: Y should be 0x42 after TAY, got 0x%h", debug_y);
            error_count++;
        end

        // INY
        @(posedge clk);
        #5;
        if (debug_y !== 8'h43) begin
            $display("FAIL: Y should be 0x43 after INY, got 0x%h", debug_y);
            error_count++;
        end

        // TXA (X=43)
        @(posedge clk);
        #5;
        if (debug_a !== 8'h43) begin
            $display("FAIL: A should be 0x43 after TXA, got 0x%h", debug_a);
            error_count++;
        end

        // TYA (Y=43)
        // Set A back to something else first
        // (Actually TYA is the next instruction in memory)
        @(posedge clk);
        #5;
        if (debug_a !== 8'h43) begin
            $display("FAIL: A should be 0x43 after TYA, got 0x%h", debug_a);
            error_count++;
        end

        // Final result
        $display("---------------------------------------");
        if (error_count == 0) $display("RESULT: ALL TESTS PASSED");
        else $display("RESULT: %0d TESTS FAILED", error_count);
        $display("---------------------------------------");
        $finish;
    end
endmodule
