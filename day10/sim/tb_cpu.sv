// Day 10: Stack Operations (PHA/PLA) - Logic Testbench
`timescale 1ns / 1ps

module tb_cpu;
    logic clk;
    logic rst_n;
    logic pc_enable;
    logic [7:0] data_in;
`ifdef TB_CPU_HAS_BUS_IF
    logic [7:0] data_out;
    logic write_en;
`endif
    logic [15:0] address_bus;
    logic [15:0] debug_pc;
`ifdef TB_CPU_HAS_BUS_IF
    logic [7:0] debug_s;
`endif
    logic [7:0] debug_a, debug_x, debug_y, debug_p;

    // Memory model
    logic [7:0] mem[65536];
    assign data_in = mem[address_bus];

`ifdef TB_CPU_HAS_BUS_IF
    // RAM write logic
    always @(posedge clk) begin
        if (write_en) mem[address_bus] <= data_out;
    end
`endif

    // Instance of CPU
    // Note: the completed CPU has the memory-bus interface (data_out/write_en)
    // and the stack pointer debug output. The Day 10 starter skeleton does not
    // have them yet (see day10/README.md), so those ports are connected only
    // when TB_CPU_HAS_BUS_IF is defined (set by day10_completed/Makefile).
    cpu dut (
        .clk(clk),
        .rst_n(rst_n),
        .pc_enable(pc_enable),
        .data_in(data_in),
`ifdef TB_CPU_HAS_BUS_IF
        .data_out(data_out),
        .write_en(write_en),
`endif
        .address_bus(address_bus),
        .debug_pc(debug_pc),
        .debug_a(debug_a),
        .debug_x(debug_x),
        .debug_y(debug_y),
        .debug_p(debug_p)
`ifdef TB_CPU_HAS_BUS_IF,
        .debug_s(debug_s)
`endif
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
        $display("=== Day 10: Stack Operations Test ===");

        // Memory setup
        // $0200: LDA #$42
        // $0202: PHA (Push A to Stack)
        // $0203: LDA #$00
        // $0205: PLA (Pull A from Stack)
        // $0206: HLT
        mem[16'h0200] = 8'hA9;
        mem[16'h0201] = 8'h42;
        mem[16'h0202] = 8'h48;  // PHA
        mem[16'h0203] = 8'hA9;
        mem[16'h0204] = 8'h00;
        mem[16'h0205] = 8'h68;  // PLA
        mem[16'h0206] = 8'hEF;  // HLT

        clk = 0;
        rst_n = 0;
        pc_enable = 1;

`ifdef TB_CPU_HAS_BUS_IF
        // Reset state check
        @(posedge clk);
        #1;
        check8("debug_s (reset)", debug_s, 8'hFF);
`endif

        // Release reset on negedge
        @(negedge clk);
        rst_n = 1;

        // 1. LDA #$42: A=0x42, S stays 0xFF
        wait_pc(16'h0202, 10, "LDA #$42");
        check8("debug_a after LDA #$42", debug_a, 8'h42);
`ifdef TB_CPU_HAS_BUS_IF
        check8("debug_s after LDA #$42", debug_s, 8'hFF);
`endif

        // 2. PHA: push 0x42 to $01FF, S -> 0xFE
        wait_pc(16'h0203, 10, "PHA");
`ifdef TB_CPU_HAS_BUS_IF
        check8("debug_s after PHA", debug_s, 8'hFE);
`endif
        // Unguarded on purpose: without the bus interface + PHA the push never
        // happens, so the starter build must fail here until Day 10 is done.
        check8("mem[0x01FF] after PHA", mem[16'h01FF], 8'h42);

        // 3. LDA #$00: A cleared
        wait_pc(16'h0205, 10, "LDA #$00");
        check8("debug_a after LDA #$00", debug_a, 8'h00);

        // 4. PLA: pull 0x42 back, S -> 0xFF
        wait_pc(16'h0206, 10, "PLA");
        check8("debug_a after PLA", debug_a, 8'h42);
`ifdef TB_CPU_HAS_BUS_IF
        check8("debug_s after PLA", debug_s, 8'hFF);
`endif

        // 5. HLT: PC must stay at 0x0206 (post-posedge stability)
        repeat (3) begin
            @(posedge clk);
            #1;
        end
        if (debug_pc !== 16'h0206) begin
            $display("FAIL: debug_pc after HLT = 0x%04h (expected 0x0206)", debug_pc);
            error_count++;
        end else begin
            $display("PASS: debug_pc stays at 0x0206 after HLT");
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
