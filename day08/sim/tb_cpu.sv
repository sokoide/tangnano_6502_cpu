// Day 08: Arithmetic Operations (ADC/SBC) & Status Flags - Logic Testbench
`timescale 1ns / 1ps

module tb_cpu;
    logic clk;
    logic rst_n;
    logic pc_enable;
    logic [7:0] data_in;
    logic [15:0] address_bus;
    logic [7:0] debug_a;
`ifdef TB_CPU_HAS_DEBUG_P
    logic [7:0] debug_p;
`endif
    logic [15:0] debug_pc;

    // Simple memory model
    logic [7:0] mem[65536];
    assign data_in = mem[address_bus];

    // Instance of CPU
    // Note: the completed CPU exposes the P register on debug_p.
    // The starter skeleton does not have it yet, so the port is connected
    // only when TB_CPU_HAS_DEBUG_P is defined (set by day08_completed/Makefile).
    cpu dut (
        .clk(clk),
        .rst_n(rst_n),
        .pc_enable(pc_enable),
        .data_in(data_in),
        .address_bus(address_bus),
        .debug_a(debug_a),
`ifdef TB_CPU_HAS_DEBUG_P
        .debug_p(debug_p),
`endif
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
            $display("PASS: %s = 0x%02h", name, got);
        end
    endtask

`ifdef TB_CPU_HAS_DEBUG_P
    // P register layout: {N, V, 1, 1, 1, 1, Z, C}
    task automatic check_p(input string name, input logic [7:0] exp);
        if (debug_p !== exp) begin
            $display("FAIL: %s: P = 0x%02h (expected N=%b V=%b Z=%b C=%b -> 0x%02h)", name,
                     debug_p, exp[7], exp[6], exp[1], exp[0], exp);
            error_count++;
        end else begin
            $display("PASS: %s: P = 0x%02h (N=%b V=%b Z=%b C=%b)", name, debug_p, debug_p[7],
                     debug_p[6], debug_p[1], debug_p[0]);
        end
    endtask
`endif

    initial begin
        $display("=== Day 08: ADC/SBC & Status Flags Test ===");

        // Test program (immediate addressing only; Day 08 has no ZP mode):
        // $0200: CLC
        // $0201: LDA #$3C
        // $0203: ADC #$42    ; 3C+42+0 = 7E  C=0 V=0 Z=0 N=0
        // $0205: ADC #$45    ; 7E+45+0 = C3  C=0 V=1 Z=0 N=1 (pos+pos -> neg)
        // $0207: SEC
        // $0208: SBC #$C3    ; C3-C3-0 = 00  C=1 V=0 Z=1 N=0
        // $020A: SBC #$01    ; 00-01-0 = FF  C=0 V=0 Z=0 N=1 (borrow)
        // $020C: LDA #$01
        // $020E: ADC #$FF    ; 01+FF+0 = 100 -> A=00 C=1 V=0 Z=1 N=0
        // $0210: NOP (end boundary: no HLT in Day 05-09)
        mem[16'h0200] = 8'h18;  // CLC
        mem[16'h0201] = 8'hA9;  // LDA imm
        mem[16'h0202] = 8'h3C;
        mem[16'h0203] = 8'h69;  // ADC imm
        mem[16'h0204] = 8'h42;
        mem[16'h0205] = 8'h69;  // ADC imm
        mem[16'h0206] = 8'h45;
        mem[16'h0207] = 8'h38;  // SEC
        mem[16'h0208] = 8'hE9;  // SBC imm
        mem[16'h0209] = 8'hC3;
        mem[16'h020A] = 8'hE9;  // SBC imm
        mem[16'h020B] = 8'h01;
        mem[16'h020C] = 8'hA9;  // LDA imm
        mem[16'h020D] = 8'h01;
        mem[16'h020E] = 8'h69;  // ADC imm
        mem[16'h020F] = 8'hFF;
        mem[16'h0210] = 8'hEA;  // NOP

        clk = 0;
        rst_n = 0;
        pc_enable = 1;

        // Reset state check
        @(posedge clk);
        #1;
        check8("debug_a (reset)", debug_a, 8'h00);

        // Release reset on negedge
        @(negedge clk);
        rst_n = 1;

        // CLC (1 cycle)
        wait_pc(16'h0201, 5, "CLC");
`ifdef TB_CPU_HAS_DEBUG_P
        check_p("after CLC", 8'h3C);
`endif

        // LDA #$3C (2 cycles)
        wait_pc(16'h0203, 10, "LDA #$3C");
        check8("debug_a after LDA #$3C", debug_a, 8'h3C);

        // ADC #$42: 0x3C + 0x42 + C(0) = 0x7E
        wait_pc(16'h0205, 10, "ADC #$42");
        check8("debug_a after ADC #$42", debug_a, 8'h7E);
`ifdef TB_CPU_HAS_DEBUG_P
        check_p("after ADC #$42 (C=0 V=0 Z=0 N=0)", 8'h3C);
`endif

        // ADC #$45: 0x7E + 0x45 + C(0) = 0xC3, overflow (pos+pos -> neg)
        wait_pc(16'h0207, 10, "ADC #$45");
        check8("debug_a after ADC #$45", debug_a, 8'hC3);
`ifdef TB_CPU_HAS_DEBUG_P
        check_p("after ADC #$45 (C=0 V=1 Z=0 N=1)", 8'hFC);
`endif

        // SEC (1 cycle)
        wait_pc(16'h0208, 5, "SEC");
`ifdef TB_CPU_HAS_DEBUG_P
        check_p("after SEC (C=1)", 8'hFD);
`endif

        // SBC #$C3: 0xC3 - 0xC3 - 0 = 0x00, no borrow
        wait_pc(16'h020A, 10, "SBC #$C3");
        check8("debug_a after SBC #$C3", debug_a, 8'h00);
`ifdef TB_CPU_HAS_DEBUG_P
        check_p("after SBC #$C3 (C=1 V=0 Z=1 N=0)", 8'h3F);
`endif

        // SBC #$01: 0x00 - 0x01 - 0 = 0xFF, borrow
        wait_pc(16'h020C, 10, "SBC #$01");
        check8("debug_a after SBC #$01", debug_a, 8'hFF);
`ifdef TB_CPU_HAS_DEBUG_P
        check_p("after SBC #$01 (C=0 V=0 Z=0 N=1)", 8'hBC);
`endif

        // LDA #$01 (2 cycles)
        wait_pc(16'h020E, 10, "LDA #$01");
        check8("debug_a after LDA #$01", debug_a, 8'h01);

        // ADC #$FF: 0x01 + 0xFF + C(0) = 0x100 -> A=0x00, carry out
        wait_pc(16'h0210, 10, "ADC #$FF");
        check8("debug_a after ADC #$FF", debug_a, 8'h00);
`ifdef TB_CPU_HAS_DEBUG_P
        check_p("after ADC #$FF (C=1 V=0 Z=1 N=0)", 8'h3F);
`endif

        // Trailing NOP: known PC boundary instead of HLT
        wait_pc(16'h0211, 5, "final NOP");

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
