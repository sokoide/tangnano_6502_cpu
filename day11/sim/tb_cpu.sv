// Day 11: Zero Page Addressing & RAM - Logic Testbench
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
        $display("=== Day 11: Zero Page & RAM Test ===");

        // Memory setup
        // $8000: LDA #$42
        // $8002: STA $10 (Zero Page)
        // $8004: LDA #$00
        // $8006: LDA $10 (Zero Page)
        // $8008: HLT
        mem[16'h8000] = 8'hA9;
        mem[16'h8001] = 8'h42;
        mem[16'h8002] = 8'h85;  // STA ZP
        mem[16'h8003] = 8'h10;
        mem[16'h8004] = 8'hA9;
        mem[16'h8005] = 8'h00;
        mem[16'h8006] = 8'hA5;  // LDA ZP
        mem[16'h8007] = 8'h10;
        mem[16'h8008] = 8'hEF;

        clk = 0;
        rst_n = 0;
        pc_enable = 1;
        #25;
        rst_n = 1;
        #20;

        // 1. Initial Load A=0x42
        repeat (2) @(posedge clk);
        #5;
        if (debug_a !== 8'h42) begin
            $display("FAIL: Initial Load A failed, got 0x%h", debug_a);
            error_count++;
        end

        // 2. STA $10
        repeat (3) @(posedge clk);
        #5;
        if (mem[16'h0010] !== 8'h42) begin
            $display("FAIL: STA $10 failed, mem[0x10]=%h", mem[16'h0010]);
            error_count++;
        end else $display("PASS: STA $10 correctly wrote 0x42 to RAM");

        // 3. Clear A
        repeat (2) @(posedge clk);
        #5;
        if (debug_a !== 8'h00) $display("INFO: A cleared to 0");

        // 4. LDA $10
        repeat (3) @(posedge clk);
        #5;
        if (debug_a !== 8'h42) begin
            $display("FAIL: LDA $10 failed, A=%h", debug_a);
            error_count++;
        end else $display("PASS: LDA $10 correctly read 0x42 from RAM");

        // Final result
        $display("---------------------------------------");
        if (error_count == 0) $display("RESULT: ALL TESTS PASSED");
        else $display("RESULT: %0d TESTS FAILED", error_count);
        $display("---------------------------------------");
        $finish;
    end
endmodule
