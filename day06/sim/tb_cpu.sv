// Day 06: Data Movement (LDA Immediate) - Logic Testbench
`timescale 1ns / 1ps

module tb_cpu;
    logic clk;
    logic rst_n;
`ifdef TB_CPU_HAS_PC_ENABLE
    logic pc_enable;
`endif
    logic [7:0] data_in;
    logic [15:0] address_bus;
    logic [7:0] debug_a;
    logic [15:0] debug_pc;

    // Simple memory model
    logic [7:0] mem[65536];
    assign data_in = mem[address_bus];

    // Instance of CPU
    // Note: the completed CPU has a pc_enable input (manual stepping).
    // The starter skeleton does not have it yet, so the port is connected
    // only when TB_CPU_HAS_PC_ENABLE is defined (set by day06_completed/Makefile).
    cpu dut (
        .clk(clk),
        .rst_n(rst_n),
`ifdef TB_CPU_HAS_PC_ENABLE
        .pc_enable(pc_enable),
`endif
        .data_in(data_in),
        .address_bus(address_bus),
        .debug_a(debug_a),
        .debug_pc(debug_pc)
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
        $display("=== Day 06: LDA Immediate Test ===");

        // Test program:
        // $0200: LDA #$42
        // $0202: NOP
        // $0203: LDA #$55
        // $0205: NOP (end marker: PC boundary 0x0206, no HLT in Day 06)
        mem[16'h0200] = 8'hA9;
        mem[16'h0201] = 8'h42;
        mem[16'h0202] = 8'hEA;  // NOP
        mem[16'h0203] = 8'hA9;
        mem[16'h0204] = 8'h55;
        mem[16'h0205] = 8'hEA;  // NOP

        clk = 0;
        rst_n = 0;
`ifdef TB_CPU_HAS_PC_ENABLE
        pc_enable = 1;
`endif

        // Reset state check
        @(posedge clk);
        #1;
        check8("debug_a (reset)", debug_a, 8'h00);

        // Release reset on negedge
        @(negedge clk);
        rst_n = 1;

        // LDA #$42 (2 cycles)
        wait_pc(16'h0202, 10, "LDA #$42");
        check8("debug_a after LDA #$42", debug_a, 8'h42);

        // NOP (1 cycle): A must be preserved
        wait_pc(16'h0203, 5, "NOP");
        check8("debug_a after NOP", debug_a, 8'h42);

        // LDA #$55 (2 cycles)
        wait_pc(16'h0205, 10, "LDA #$55");
        check8("debug_a after LDA #$55", debug_a, 8'h55);

        // Trailing NOP: known PC boundary instead of HLT
        wait_pc(16'h0206, 5, "final NOP");

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
