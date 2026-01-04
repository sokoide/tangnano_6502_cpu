// Day 15: Integration - Logic Testbench
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

    // RAM write logic
    always @(posedge clk) begin
        if (write_en) mem[address_bus] <= data_out;
    end

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
        $display("=== Day 15: CPU Integration Test ===");

        // Memory setup: Combined test
        // 1. LDA #$10, STA $20 (ZP), ADC #$05 -> A=15, [0x20]=10
        // 2. LDX #$02, DEX, BNE loop
        mem[16'h0200] = 8'hA9;
        mem[16'h0201] = 8'h10;  // LDA #$10
        mem[16'h0202] = 8'h85;
        mem[16'h0203] = 8'h20;  // STA $20
        mem[16'h0204] = 8'h69;
        mem[16'h0205] = 8'h05;  // ADC #$05
        mem[16'h0206] = 8'hEF;  // HLT

        clk = 0;
        rst_n = 0;
        pc_enable = 1;
        #25;
        rst_n = 1;
        #20;

        // Execute instructions
        repeat (15) @(posedge clk);
        #5;

        // Check A register (16 + 5 = 21, 0x15)
        if (debug_a !== 8'h15) begin
            $display("FAIL: Final A should be 0x15, got 0x%h", debug_a);
            error_count++;
        end else $display("PASS: Integration results correct");

        // Check memory write
        if (mem[16'h0020] !== 8'h10) begin
            $display("FAIL: ZP write check failed, mem[0x20]=%h", mem[16'h0020]);
            error_count++;
        end else $display("PASS: ZP write check correct");

        // Final result
        $display("---------------------------------------");
        if (error_count == 0) $display("RESULT: ALL TESTS PASSED");
        else $display("RESULT: %0d TESTS FAILED", error_count);
        $display("---------------------------------------");
        $finish;
    end
endmodule
