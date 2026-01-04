// Day 16: Stack Operations (PHA/PLA) - Logic Testbench
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
        $display("=== Day 16: PHA/PLA Test ===");

        // Memory setup
        // $8000: LDA #$AA
        // $8002: PHA (Push A to Stack)
        // $8003: LDA #$00
        // $8005: PLA (Pull A from Stack)
        // $8006: HLT
        mem[16'h0200] = 8'hA9;
        mem[16'h0201] = 8'hAA;
        mem[16'h0202] = 8'h48;  // PHA
        mem[16'h0203] = 8'hA9;
        mem[16'h0204] = 8'h00;
        mem[16'h0205] = 8'h68;  // PLA
        mem[16'h0206] = 8'hEF;

        clk = 0;
        rst_n = 0;
        pc_enable = 1;
        #25;
        rst_n = 1;
        #20;

        // 1. Initial Load A=0xAA
        repeat (2) @(posedge clk);
        #5;
        if (debug_a !== 8'hAA) begin
            $display("FAIL: Initial Load A failed, got 0x%h", debug_a);
            error_count++;
        end

        // 2. PHA execution
        repeat (3) @(posedge clk);
        #5;
        if (debug_s !== 8'hFE || mem[16'h01FF] !== 8'hAA) begin
            $display("FAIL: PHA failed, S=%h, stack[0x1FF]=%h", debug_s, mem[16'h01FF]);
            error_count++;
        end else $display("PASS: PHA correctly pushed 0xAA to stack");

        // 3. Clear A
        repeat (2) @(posedge clk);
        #5;
        if (debug_a !== 8'h00) $display("INFO: A cleared to 0");

        // 4. PLA execution
        repeat (4) @(posedge clk);
        #5;
        if (debug_a !== 8'hAA || debug_s !== 8'hFF) begin
            $display("FAIL: PLA failed, A=%h, S=%h", debug_a, debug_s);
            error_count++;
        end else $display("PASS: PLA correctly pulled 0xAA from stack");

        // Final result
        $display("---------------------------------------");
        if (error_count == 0) $display("RESULT: ALL TESTS PASSED");
        else $display("RESULT: %0d TESTS FAILED", error_count);
        $display("---------------------------------------");
        $finish;
    end
endmodule
