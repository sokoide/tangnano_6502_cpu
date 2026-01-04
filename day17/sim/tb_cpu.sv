// Day 17: Stack Operations (JSR/RTS) - Logic Testbench
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
        $display("=== Day 17: JSR/RTS Test ===");

        // Memory setup
        // $8000: JSR sub ($8005)
        // $8003: HLT
        // $8005: sub: LDA #$42
        // $8007: RTS
        mem[16'h0200] = 8'h20;  // JSR
        mem[16'h0201] = 8'h05;  // sub low
        mem[16'h0202] = 8'h80;  // sub high
        mem[16'h0203] = 8'hEF;  // HLT

        mem[16'h0205] = 8'hA9;  // LDA imm
        mem[16'h0206] = 8'h42;
        mem[16'h0207] = 8'h60;  // RTS

        clk = 0;
        rst_n = 0;
        pc_enable = 1;
        #25;
        rst_n = 1;
        #20;

        // 1. JSR sub
        repeat (6) @(posedge clk);
        #5;  // JSR takes 6 cycles
        if (debug_pc !== 16'h0205) begin
            $display("FAIL: JSR failed to jump, PC=%h", debug_pc);
            error_count++;
        end else $display("PASS: JSR jumped to 0x8005");

        // 2. sub: LDA #$42
        repeat (2) @(posedge clk);
        #5;
        if (debug_a !== 8'h42) begin
            $display("FAIL: Subroutine code not executed, A=%h", debug_a);
            error_count++;
        end

        // 3. RTS
        repeat (6) @(posedge clk);
        #5;  // RTS takes 6 cycles
        if (debug_pc !== 16'h0203) begin
            $display("FAIL: RTS failed to return, PC=%h", debug_pc);
            error_count++;
        end else $display("PASS: RTS returned to 0x8003");

        // Final result
        $display("---------------------------------------");
        if (error_count == 0) $display("RESULT: ALL TESTS PASSED");
        else $display("RESULT: %0d TESTS FAILED", error_count);
        $display("---------------------------------------");
        $finish;
    end
endmodule
