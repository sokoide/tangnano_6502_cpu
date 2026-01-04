// Day 14: Branch Instructions - Logic Testbench
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

    // Status flags unpacking
    logic z;
    assign z = debug_p[1];

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
        $display("=== Day 14: Branch Instructions Test ===");

        // Memory setup: Loop 2 times
        // $8000: LDX #$02
        // $8002: DEX (X=1)
        // $8003: BNE $FD (Branch back to $8002)
        // $8005: HLT
        mem[16'h0200] = 8'hA2;
        mem[16'h0201] = 8'h02;
        mem[16'h0202] = 8'hCA;  // DEX
        mem[16'h0203] = 8'hD0;  // BNE
        mem[16'h0204] = 8'hFD;  // -3
        mem[16'h0205] = 8'hEF;

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
            $display("FAIL: Initial Load X failed, got 0x%h", debug_x);
            error_count++;
        end

        // 2. First loop (X=1)
        @(posedge clk);
        #5;  // DEX
        repeat (2) @(posedge clk);
        #5;  // BNE (Fetch, Branch)
        if (debug_pc !== 16'h0202) begin
            $display("FAIL: Branch back failed, PC=%h", debug_pc);
            error_count++;
        end else $display("PASS: First branch taken (X=1)");

        // 3. Second loop (X=0)
        @(posedge clk);
        #5;  // DEX
        repeat (2) @(posedge clk);
        #5;  // BNE (Fetch, Fall through)
        if (debug_pc !== 16'h0205) begin
            $display("FAIL: Fall through failed, PC=%h", debug_pc);
            error_count++;
        end else $display("PASS: Loop exit correct (X=0)");

        // Final result
        $display("---------------------------------------");
        if (error_count == 0) $display("RESULT: ALL TESTS PASSED");
        else $display("RESULT: %0d TESTS FAILED", error_count);
        $display("---------------------------------------");
        $finish;
    end
endmodule
