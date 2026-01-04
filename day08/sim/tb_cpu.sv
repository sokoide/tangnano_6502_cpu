// Day 08: Data Movement (Zero Page Addressing) - Logic Testbench
`timescale 1ns / 1ps

module tb_cpu;
    logic clk;
    logic rst_n;
    logic pc_enable;
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
        .pc_enable(pc_enable),
        .data_in(data_in),
        .address_bus(address_bus),
        .debug_a(debug_a),
        .debug_pc(debug_pc)
    );

    assign data_in = mem[address_bus];

    // 50MHz clock
    always #10 clk = ~clk;

    integer error_count = 0;

    initial begin
        $display("=== Day 08: Zero Page Addressing Test ===");

        // Memory setup:
        // $0010 = $42 (Data in Zero Page)
        // $8000 = $A5, $10 (LDA $10)
        // $8002 = $A9, $55 (LDA #$55)
        mem[16'h0010] = 8'h42;
        mem[16'h0200] = 8'hA5;  // LDA ZP
        mem[16'h0201] = 8'h10;  // address
        mem[16'h0202] = 8'hA9;  // LDA imm
        mem[16'h0203] = 8'h55;

        clk = 0;
        rst_n = 0;
        pc_enable = 1;
        #25;
        rst_n = 1;
        #20;

        // Execute LDA $10 (3 states: Fetch Op, Fetch Addr, Read Mem)
        repeat (3) @(posedge clk);
        #5;
        if (debug_a !== 8'h42) begin
            $display("FAIL: A should be 0x42 (from ZP $10), got 0x%h", debug_a);
            error_count++;
        end else begin
            $display("PASS: LDA ZP works");
        end

        // Execute LDA #$55 (2 states: Fetch Op, Execute Imm)
        repeat (2) @(posedge clk);
        #5;
        if (debug_a !== 8'h55) begin
            $display("FAIL: A should be 0x55 (from imm), got 0x%h", debug_a);
            error_count++;
        end else begin
            $display("PASS: LDA imm still works");
        end

        // Final result
        $display("---------------------------------------");
        if (error_count == 0) $display("RESULT: ALL TESTS PASSED");
        else $display("RESULT: %0d TESTS FAILED", error_count);
        $display("---------------------------------------");
        $finish;
    end
endmodule
