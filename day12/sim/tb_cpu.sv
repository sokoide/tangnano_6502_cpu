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
        $display("=== Day 12: Absolute Addressing Test ===");

        // Memory setup
        // $0200: LDA #$55
        // $0202: STA $1234 (Absolute)
        // $0205: LDA #$00
        // $0207: LDA $1234 (Absolute)
        // $020A: HLT
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
        mem[16'h020A] = 8'hEF;  // HLT

        clk = 0;
        rst_n = 0;
        pc_enable = 1;

        // Release reset on negedge
        @(negedge clk);
        rst_n = 1;

        // 1. LDA #$55
        wait_pc(16'h0202, 10, "LDA #$55");
        check8("debug_a after LDA #$55", debug_a, 8'h55);

        // 2. STA $1234: absolute write
        wait_pc(16'h0205, 10, "STA $1234");
        check8("mem[0x1234] after STA $1234", mem[16'h1234], 8'h55);

        // 3. LDA #$00: A cleared
        wait_pc(16'h0207, 10, "LDA #$00");
        check8("debug_a after LDA #$00", debug_a, 8'h00);

        // 4. LDA $1234: absolute read
        wait_pc(16'h020A, 10, "LDA $1234");
        check8("debug_a after LDA $1234", debug_a, 8'h55);

        // 5. HLT: PC must stay at 0x020A (post-posedge stability)
        repeat (3) begin
            @(posedge clk);
            #1;
        end
        if (debug_pc !== 16'h020A) begin
            $display("FAIL: debug_pc after HLT = 0x%04h (expected 0x020A)", debug_pc);
            error_count++;
        end else begin
            $display("PASS: debug_pc stays at 0x020A after HLT");
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
