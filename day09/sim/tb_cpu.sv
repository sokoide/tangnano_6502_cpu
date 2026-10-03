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
            $display("PASS: %s = 0x%02h", name, got, exp);
        end
    endtask

    initial begin
        $display("=== Day 09: Branch Instructions Test ===");

        // Test program (Day 09 CPU has no DEX: flags come from LDA):
        // $0200: LDA #$00        Z=1
        // $0202: BEQ +2          taken  -> $0206 (skips LDA #$7F at $0204)
        // $0206: LDA #$01        Z=0
        // $0208: BNE +2          taken  -> $020C (skips LDA #$7F at $020A)
        // $020C: LDA #$80        N=1
        // $020E: BMI +2          taken  -> $0212 (skips LDA #$7F at $0210)
        // $0212: LDA #$01        N=0
        // $0214: BPL +2          taken  -> $0218 (skips LDA #$7F at $0216)
        // $0218: LDA #$05        Z=0
        // $021A: BEQ +2          NOT taken -> falls through to $021C
        // $021C: NOP             (end boundary: no HLT in Day 05-09)
        mem[16'h0200] = 8'hA9;  // LDA imm
        mem[16'h0201] = 8'h00;
        mem[16'h0202] = 8'hF0;  // BEQ
        mem[16'h0203] = 8'h02;
        mem[16'h0204] = 8'hA9;  // LDA #$7F (must be skipped)
        mem[16'h0205] = 8'h7F;
        mem[16'h0206] = 8'hA9;  // LDA imm
        mem[16'h0207] = 8'h01;
        mem[16'h0208] = 8'hD0;  // BNE
        mem[16'h0209] = 8'h02;
        mem[16'h020A] = 8'hA9;  // LDA #$7F (must be skipped)
        mem[16'h020B] = 8'h7F;
        mem[16'h020C] = 8'hA9;  // LDA imm
        mem[16'h020D] = 8'h80;
        mem[16'h020E] = 8'h30;  // BMI
        mem[16'h020F] = 8'h02;
        mem[16'h0210] = 8'hA9;  // LDA #$7F (must be skipped)
        mem[16'h0211] = 8'h7F;
        mem[16'h0212] = 8'hA9;  // LDA imm
        mem[16'h0213] = 8'h01;
        mem[16'h0214] = 8'h10;  // BPL
        mem[16'h0215] = 8'h02;
        mem[16'h0216] = 8'hA9;  // LDA #$7F (must be skipped)
        mem[16'h0217] = 8'h7F;
        mem[16'h0218] = 8'hA9;  // LDA imm
        mem[16'h0219] = 8'h05;
        mem[16'h021A] = 8'hF0;  // BEQ (must fall through: Z=0)
        mem[16'h021B] = 8'h02;
        mem[16'h021C] = 8'hEA;  // NOP

        clk = 0;
        rst_n = 0;
        pc_enable = 1;

        // Release reset on negedge
        @(negedge clk);
        rst_n = 1;

        // LDA #$00: Z=1
        wait_pc(16'h0202, 10, "LDA #$00");
        check8("debug_a after LDA #$00", debug_a, 8'h00);

        // BEQ taken -> 0x0206
        wait_pc(16'h0206, 10, "BEQ taken");
        check8("debug_a after BEQ taken (skipped LDA #$7F)", debug_a, 8'h00);

        // LDA #$01: Z=0
        wait_pc(16'h0208, 10, "LDA #$01");
        check8("debug_a after LDA #$01", debug_a, 8'h01);

        // BNE taken -> 0x020C
        wait_pc(16'h020C, 10, "BNE taken");
        check8("debug_a after BNE taken (skipped LDA #$7F)", debug_a, 8'h01);

        // LDA #$80: N=1
        wait_pc(16'h020E, 10, "LDA #$80");
        check8("debug_a after LDA #$80", debug_a, 8'h80);

        // BMI taken -> 0x0212
        wait_pc(16'h0212, 10, "BMI taken");
        check8("debug_a after BMI taken (skipped LDA #$7F)", debug_a, 8'h80);

        // LDA #$01: N=0
        wait_pc(16'h0214, 10, "LDA #$01 (N=0)");
        check8("debug_a after LDA #$01 (N=0)", debug_a, 8'h01);

        // BPL taken -> 0x0218
        wait_pc(16'h0218, 10, "BPL taken");
        check8("debug_a after BPL taken (skipped LDA #$7F)", debug_a, 8'h01);

        // LDA #$05: Z=0
        wait_pc(16'h021A, 10, "LDA #$05");
        check8("debug_a after LDA #$05", debug_a, 8'h05);

        // BEQ not taken: fall through to 0x021C
        wait_pc(16'h021C, 10, "BEQ fall-through");

        // Trailing NOP: known PC boundary instead of HLT
        wait_pc(16'h021D, 5, "final NOP");

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
