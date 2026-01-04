// Day 12: Absolute Addressing - Logic Testbench
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
        $display("=== Day 12: Absolute Addressing Test ===");

        // Memory setup
        // $8000: LDA #$55
        // $8002: STA $1234 (Absolute)
        // $8005: LDA #$00
        // $8007: LDA $1234 (Absolute)
        // $800A: HLT
        mem[16'h0200] = 8'hA9;
        mem[16'h0201] = 8'h55;
        mem[16'h0202] = 8'h8D;  // STA abs
        mem[16'h0203] = 8'h34;  // low
        mem[16'h0204] = 8'h12;  // high
        mem[16'h0205] = 8'hA9;
        mem[16'h0206] = 8'h00;
        mem[16'h0207] = 8'hAD;  // LDA abs
        mem[16'h0208] = 8'h34;
        mem[16'h0209] = 8'h12;
        mem[16'h020A] = 8'hEF;

        clk = 0;
        rst_n = 0;
        pc_enable = 1;
        #25;
        rst_n = 1;
        #20;

        // 1. Initial Load A=0x55
        repeat (2) @(posedge clk);
        #5;
        if (debug_a !== 8'h55) begin
            $display("FAIL: Initial Load A failed, got 0x%h", debug_a);
            error_count++;
        end

        // 2. STA $1234 (Fetch Op, Fetch Low, Fetch High, Execute)
        repeat (4) @(posedge clk);
        #5;
        if (mem[16'h1234] !== 8'h55) begin
            $display("FAIL: STA $1234 failed, mem[0x1234]=%h", mem[16'h1234]);
            error_count++;
        end else $display("PASS: STA absolute correctly wrote 0x55 to RAM");

        // 3. Clear A
        repeat (2) @(posedge clk);
        #5;
        if (debug_a !== 8'h00) $display("INFO: A cleared to 0");

        // 4. LDA $1234
        repeat (4) @(posedge clk);
        #5;
        if (debug_a !== 8'h55) begin
            $display("FAIL: LDA $1234 failed, A=%h", debug_a);
            error_count++;
        end else $display("PASS: LDA absolute correctly read 0x55 from RAM");

        // Final result
        $display("---------------------------------------");
        if (error_count == 0) $display("RESULT: ALL TESTS PASSED");
        else $display("RESULT: %0d TESTS FAILED", error_count);
        $display("---------------------------------------");
        $finish;
    end
endmodule
