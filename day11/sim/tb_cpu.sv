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

    // Global watchdog: bounded completion
    initial begin
        #200000;  // 10000 cycles
        $fatal(1, "TIMEOUT: simulation did not finish");
    end

    // Wait (bounded) until PC reaches the target instruction boundary
    task automatic wait_pc(input logic [15:0] target, input integer bound, input string what);
        integer i;
        for (i = 0; i < bound; i++) begin
            @(posedge clk);
            #1;  // post-posedge sampling
            if (debug_pc === target) return;
        end
        $fatal(1, "TIMEOUT: %s: PC never reached 0x%04h (PC=0x%04h)", what, target, debug_pc);
    endtask

    task automatic check8(input string name, input logic [7:0] got, input logic [7:0] exp);
        if (got !== exp) begin
            $display("FAIL: %s = 0x%02h (expected 0x%02h)", name, got, exp);
            error_count++;
        end else begin
            $display("PASS: %s = 0x%02h", name, got);
        end
    endtask

    initial begin
        $display("=== Day 11: Zero Page & RAM Test ===");

        // Memory setup
        // $0200: LDA #$42
        // $0202: STA $10 (Zero Page)
        // $0204: LDA #$00
        // $0206: LDA $10 (Zero Page)
        // $0208: HLT
        mem[16'h0200] = 8'hA9;
        mem[16'h0201] = 8'h42;
        mem[16'h0202] = 8'h85;  // STA ZP
        mem[16'h0203] = 8'h10;
        mem[16'h0204] = 8'hA9;
        mem[16'h0205] = 8'h00;
        mem[16'h0206] = 8'hA5;  // LDA ZP
        mem[16'h0207] = 8'h10;
        mem[16'h0208] = 8'hEF;  // HLT

        clk = 0;
        rst_n = 0;
        pc_enable = 1;

        // Release reset on negedge
        @(negedge clk);
        rst_n = 1;

        // 1. LDA #$42
        wait_pc(16'h0202, 10, "LDA #$42");
        check8("debug_a after LDA #$42", debug_a, 8'h42);

        // 2. STA $10: zero page write
        wait_pc(16'h0204, 10, "STA $10");
        check8("mem[0x0010] after STA $10", mem[16'h0010], 8'h42);

        // 3. LDA #$00: A cleared
        wait_pc(16'h0206, 10, "LDA #$00");
        check8("debug_a after LDA #$00", debug_a, 8'h00);

        // 4. LDA $10: zero page read
        wait_pc(16'h0208, 10, "LDA $10");
        check8("debug_a after LDA $10", debug_a, 8'h42);

        // 5. HLT: PC must stay at 0x0208 (post-posedge stability)
        repeat (3) begin
            @(posedge clk);
            #1;
        end
        if (debug_pc !== 16'h0208) begin
            $display("FAIL: debug_pc after HLT = 0x%04h (expected 0x0208)", debug_pc);
            error_count++;
        end else begin
            $display("PASS: debug_pc stays at 0x0208 after HLT");
        end

        // Final result
        $display("---------------------------------------");
        if (error_count == 0) begin
            $display("RESULT: ALL TESTS PASSED");
            $finish;
        end else begin
            $fatal(1, "RESULT: %0d TESTS FAILED", error_count);
        end
    end

endmodule
