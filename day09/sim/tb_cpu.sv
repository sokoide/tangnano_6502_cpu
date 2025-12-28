// Day 09: Branch Instructions - Logic Testbench
`timescale 1ns / 1ps

module tb_cpu;
    logic clk;
    logic rst_n;
    logic pc_enable;
    logic [7:0] data_in;
    logic [15:0] address_bus;
    logic [15:0] debug_pc;
    logic [7:0] debug_a, debug_x, debug_y, debug_p;

    // Memory model
    logic [7:0] mem[65536];
    assign data_in = mem[address_bus];

    // Status flags unpacking
    logic z;
    assign z = debug_p[1];

    // Instance of CPU
    cpu dut (
        .clk(clk),
        .rst_n(rst_n),
        .pc_enable(pc_enable),
        .data_in(data_in),
        .address_bus(address_bus),
        .debug_pc(debug_pc),
        .debug_a(debug_a),
        .debug_x(debug_x),
        .debug_y(debug_y),
        .debug_p(debug_p)
    );

    // 50MHz clock
    always #10 clk = ~clk;

    integer error_count = 0;

    initial begin
        $display("=== Day 09: Branch Instructions Test ===");

        // Test Program:
        // $8000: LDX #$02
        // $8002: DEX (X=1)
        // $8003: BNE $FD (-3 relative, back to $8002)
        // $8005: HLT

        mem[16'h8000] = 8'hA2;  // LDX imm
        mem[16'h8001] = 8'h02;
        mem[16'h8002] = 8'hCA;  // DEX (assuming OP_DEX=CA)
        mem[16'h8003] = 8'hD0;  // BNE
        mem[16'h8004] = 8'hFD;  // -3 in two's complement
        mem[16'h8005] = 8'hEF;  // HLT

        clk = 0;
        rst_n = 0;
        pc_enable = 1;
        #25;
        rst_n = 1;
        #20;

        // 1. Initial Load X=2
        repeat (2) @(posedge clk);
        #5;
        if (debug_x !== 8'h02) begin
            $display("FAIL: X should be 0x02, got 0x%h", debug_x);
            error_count++;
        end

        // 2. Loop 1: DEX (X=1)
        @(posedge clk);
        #5;
        if (debug_x !== 8'h01) begin
            $display("FAIL: X should be 0x01, got 0x%h", debug_x);
            error_count++;
        end

        // 3. Branch 1: BNE target ($8002)
        repeat (2) @(posedge clk);
        #5;  // Fetch BNE, Execute Branch
        if (debug_pc !== 16'h8002) begin
            $display("FAIL: PC should branch back to 0x8002, got 0x%h", debug_pc);
            error_count++;
        end else $display("PASS: First branch taken");

        // 4. Loop 2: DEX (X=0)
        @(posedge clk);
        #5;
        if (debug_x !== 8'h00) begin
            $display("FAIL: X should be 0x00, got 0x%h", debug_x);
            error_count++;
        end

        // 5. Branch 2: BNE fall-through ($8005)
        repeat (2) @(posedge clk);
        #5;
        if (debug_pc !== 16'h8005) begin
            $display("FAIL: PC should fall through to 0x8005, got 0x%h", debug_pc);
            error_count++;
        end else $display("PASS: Loop exit correct");

        // Final result
        $display("---------------------------------------");
        if (error_count == 0) $display("RESULT: ALL TESTS PASSED");
        else $display("RESULT: %0d TESTS FAILED", error_count);
        $display("---------------------------------------");
        $finish;
    end
endmodule
