// Day 13: JMP Instruction - Logic Testbench
`timescale 1ns / 1ps

module tb_cpu;
    logic clk;
    logic rst_n;
    logic pc_enable;
    logic [7:0] data_in;
    logic [7:0] data_out;
    logic write_en;
    logic [15:0] address_bus;
    logic [15:0] debug_pc;
    logic [7:0] debug_a, debug_x, debug_y, debug_p, debug_s;

    // Memory model
    logic [7:0] mem[65536];
    assign data_in = mem[address_bus];

    // Instance of CPU
    cpu dut (
        .clk(clk),
        .rst_n(rst_n),
        .pc_enable(pc_enable),
        .data_in(data_in),
        .data_out(data_out),
        .write_en(write_en),
        .address_bus(address_bus),
        .debug_pc(debug_pc),
        .debug_a(debug_a),
        .debug_x(debug_x),
        .debug_y(debug_y),
        .debug_p(debug_p),
        .debug_s(debug_s)
    );

    // 50MHz clock
    always #10 clk = ~clk;

    integer error_count = 0;

    initial begin
        $display("=== Day 13: JMP Instruction Test ===");

        // Memory setup
        // $8000: LDA #$01
        // $8002: JMP $8006
        // $8005: LDA #$02 (Should be skipped)
        // $8006: HLT
        mem[16'h8000] = 8'hA9;
        mem[16'h8001] = 8'h01;
        mem[16'h8002] = 8'h4C;  // JMP abs
        mem[16'h8003] = 8'h06;  // low
        mem[16'h8004] = 8'h80;  // high
        mem[16'h8005] = 8'hA9;  // LDA #$02 (skipped)
        mem[16'h8006] = 8'hEF;  // HLT

        clk = 0;
        rst_n = 0;
        pc_enable = 1;
        #25;
        rst_n = 1;
        #20;

        // 1. Initial Load A=0x01
        repeat (2) @(posedge clk);
        #5;
        if (debug_a !== 8'h01) begin
            $display("FAIL: Initial Load A failed, got 0x%h", debug_a);
            error_count++;
        end

        // 2. JMP $8006 (Fetch Op, Fetch Low, Fetch High, Execute)
        repeat (4) @(posedge clk);
        #5;
        if (debug_pc !== 16'h8006) begin
            $display("FAIL: JMP failed, PC=%h", debug_pc);
            error_count++;
        end else $display("PASS: JMP correctly updated PC to 0x8006");

        // 3. Verify skipped instruction
        if (debug_a !== 8'h01) begin
            $display("FAIL: Skip check failed, A changed unexpectedly to 0x%h", debug_a);
            error_count++;
        end else $display("PASS: Skipped instruction correctly");

        // Final result
        $display("---------------------------------------");
        if (error_count == 0) $display("RESULT: ALL TESTS PASSED");
        else $display("RESULT: %0d TESTS FAILED", error_count);
        $display("---------------------------------------");
        $finish;
    end
endmodule
