// Day 07: Data Movement (Register Transfers) - Logic Testbench
`timescale 1ns / 1ps

module tb_cpu;
    logic clk;
    logic rst_n;
    logic pc_enable;
    logic [7:0] data_in;
    logic [15:0] address_bus;
    logic [7:0] debug_a, debug_x, debug_y;
    logic [15:0] debug_pc;

    // Simple memory model
    logic [7:0] mem[65536];
    assign data_in = mem[address_bus];

    // Instance of CPU
    cpu dut (
        .clk(clk),
        .rst_n(rst_n),
        .pc_enable(pc_enable),
        .data_in(data_in),
        .address_bus(address_bus),
        .debug_a(debug_a),
        .debug_x(debug_x),
        .debug_y(debug_y),
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

    initial begin
        $display("=== Day 07: Register Transfer Test ===");

        // Test program:
        // $0200: LDA #$42 / $0202: TAX / $0203: INX / $0204: TAY
        // $0205: INY / $0206: TXA / $0207: TYA / $0208: NOP (end boundary)
        mem[16'h0200] = 8'hA9;  // LDA imm
        mem[16'h0201] = 8'h42;
        mem[16'h0202] = 8'hAA;  // TAX
        mem[16'h0203] = 8'hE8;  // INX
        mem[16'h0204] = 8'hA8;  // TAY
        mem[16'h0205] = 8'hC8;  // INY
        mem[16'h0206] = 8'h8A;  // TXA
        mem[16'h0207] = 8'h98;  // TYA
        mem[16'h0208] = 8'hEA;  // NOP

        clk = 0;
        rst_n = 0;
        pc_enable = 1;

        // Reset state check
        @(posedge clk);
        #1;
        check8("debug_a (reset)", debug_a, 8'h00);
        check8("debug_x (reset)", debug_x, 8'h00);
        check8("debug_y (reset)", debug_y, 8'h00);

        // Release reset on negedge
        @(negedge clk);
        rst_n = 1;

        // LDA #$42 (2 cycles)
        wait_pc(16'h0202, 10, "LDA #$42");
        check8("debug_a after LDA #$42", debug_a, 8'h42);

        // TAX (1 cycle)
        wait_pc(16'h0203, 5, "TAX");
        check8("debug_x after TAX", debug_x, 8'h42);

        // INX (1 cycle)
        wait_pc(16'h0204, 5, "INX");
        check8("debug_x after INX", debug_x, 8'h43);

        // TAY (1 cycle)
        wait_pc(16'h0205, 5, "TAY");
        check8("debug_y after TAY", debug_y, 8'h42);

        // INY (1 cycle)
        wait_pc(16'h0206, 5, "INY");
        check8("debug_y after INY", debug_y, 8'h43);

        // TXA (1 cycle): A = X = 0x43
        wait_pc(16'h0207, 5, "TXA");
        check8("debug_a after TXA", debug_a, 8'h43);

        // TYA (1 cycle): A = Y = 0x43
        wait_pc(16'h0208, 5, "TYA");
        check8("debug_a after TYA", debug_a, 8'h43);

        // Trailing NOP: known PC boundary instead of HLT
        wait_pc(16'h0209, 5, "final NOP");

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
