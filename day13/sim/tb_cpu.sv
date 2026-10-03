// Day 13: Logical Operations (AND/ORA/EOR/BIT) - Logic Testbench
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

    initial begin
        $display("=== Day 13: Logical Operations (AND/ORA/EOR/BIT) Test ===");

        // Memory setup
        // $0200: LDA #$F0
        // $0202: AND #$3C    ; F0 & 3C = 30, Z=0 N=0
        // $0204: ORA #$03    ; 30 | 03 = 33, Z=0 N=0
        // $0206: EOR #$33    ; 33 ^ 33 = 00, Z=1 N=0
        // $0208: LDA #$0F
        // $020A: BIT $10     ; M=C3: A&M=03 -> Z=0, N=1, V=1, A unchanged
        // $020C: BIT $11     ; M=30: A&M=00 -> Z=1, N=0, V=0, A unchanged
        // $020E: HLT
        mem[16'h0200] = 8'hA9;
        mem[16'h0201] = 8'hF0;
        mem[16'h0202] = 8'h29;  // AND imm
        mem[16'h0203] = 8'h3C;
        mem[16'h0204] = 8'h09;  // ORA imm
        mem[16'h0205] = 8'h03;
        mem[16'h0206] = 8'h49;  // EOR imm
        mem[16'h0207] = 8'h33;
        mem[16'h0208] = 8'hA9;  // LDA imm
        mem[16'h0209] = 8'h0F;
        mem[16'h020A] = 8'h24;  // BIT zp
        mem[16'h020B] = 8'h10;
        mem[16'h020C] = 8'h24;  // BIT zp
        mem[16'h020D] = 8'h11;
        mem[16'h020E] = 8'hEF;  // HLT
        mem[16'h0010] = 8'hC3;  // BIT operand 1
        mem[16'h0011] = 8'h30;  // BIT operand 2

        clk = 0;
        rst_n = 0;
        pc_enable = 1;

        // Release reset on negedge
        @(negedge clk);
        rst_n = 1;

        // 1. LDA #$F0
        wait_pc(16'h0202, 10, "LDA #$F0");
        check8("debug_a after LDA #$F0", debug_a, 8'hF0);

        // 2. AND #$3C: 0xF0 & 0x3C = 0x30
        wait_pc(16'h0204, 10, "AND #$3C");
        check8("debug_a after AND #$3C", debug_a, 8'h30);
        check_p("after AND #$3C (N=0 V=0 Z=0)", 8'h3C);

        // 3. ORA #$03: 0x30 | 0x03 = 0x33
        wait_pc(16'h0206, 10, "ORA #$03");
        check8("debug_a after ORA #$03", debug_a, 8'h33);
        check_p("after ORA #$03 (N=0 V=0 Z=0)", 8'h3C);

        // 4. EOR #$33: 0x33 ^ 0x33 = 0x00 -> Z=1
        wait_pc(16'h0208, 10, "EOR #$33");
        check8("debug_a after EOR #$33", debug_a, 8'h00);
        check_p("after EOR #$33 (N=0 V=0 Z=1)", 8'h3E);

        // 5. LDA #$0F
        wait_pc(16'h020A, 10, "LDA #$0F");
        check8("debug_a after LDA #$0F", debug_a, 8'h0F);

        // 6. BIT $10 (M=0xC3): Z=0, N=M[7]=1, V=M[6]=1, A unchanged
        wait_pc(16'h020C, 10, "BIT $10");
        check8("debug_a after BIT $10 (A unchanged)", debug_a, 8'h0F);
        check_p("after BIT $10 (N=1 V=1 Z=0)", 8'hFC);

        // 7. BIT $11 (M=0x30): Z=1, N=0, V=0, A unchanged
        wait_pc(16'h020E, 10, "BIT $11");
        check8("debug_a after BIT $11 (A unchanged)", debug_a, 8'h0F);
        check_p("after BIT $11 (N=0 V=0 Z=1)", 8'h3E);

        // 8. HLT: PC must stay at 0x020E (post-posedge stability)
        repeat (3) begin
            @(posedge clk);
            #1;
        end
        if (debug_pc !== 16'h020E) begin
            $display("FAIL: debug_pc after HLT = 0x%04h (expected 0x020E)", debug_pc);
            error_count++;
        end else begin
            $display("PASS: debug_pc stays at 0x020E after HLT");
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
