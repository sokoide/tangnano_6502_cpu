// Day 14: Shift & Rotate Instructions (ASL/LSR/ROL/ROR on A) - Logic Testbench
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
        $display("=== Day 14: Shift & Rotate (ASL/LSR/ROL/ROR) Test ===");

        // Memory setup
        // $0200: LDA #$45
        // $0202: ASL A    ; 45<<1 = 8A, C=0(A7 was 0), N=1, Z=0
        // $0203: LSR A    ; 8A>>1 = 45, C=0(A0 was 0), N=0, Z=0
        // $0204: SEC      ; C=1
        // $0205: ROL A    ; 45 rotated left with C=1 -> 8B, C=0(A7 was 0), N=1
        // $0206: ROR A    ; 8B rotated right with C=0 -> 45, C=1(A0 was 1), N=0
        // $0207: LDA #$80
        // $0209: ASL A    ; 80<<1 = 00, C=1, Z=1, N=0
        // $020A: HLT
        mem[16'h0200] = 8'hA9;
        mem[16'h0201] = 8'h45;
        mem[16'h0202] = 8'h0A;  // ASL A
        mem[16'h0203] = 8'h4A;  // LSR A
        mem[16'h0204] = 8'h38;  // SEC
        mem[16'h0205] = 8'h2A;  // ROL A
        mem[16'h0206] = 8'h6A;  // ROR A
        mem[16'h0207] = 8'hA9;  // LDA imm
        mem[16'h0208] = 8'h80;
        mem[16'h0209] = 8'h0A;  // ASL A
        mem[16'h020A] = 8'hEF;  // HLT

        clk = 0;
        rst_n = 0;
        pc_enable = 1;

        // Release reset on negedge
        @(negedge clk);
        rst_n = 1;

        // 1. LDA #$45
        wait_pc(16'h0202, 10, "LDA #$45");
        check8("debug_a after LDA #$45", debug_a, 8'h45);

        // 2. ASL A: 0x45 -> 0x8A, C=0 (MSB was 0), N=1
        wait_pc(16'h0203, 5, "ASL A (1st)");
        check8("debug_a after ASL A", debug_a, 8'h8A);
        check_p("after ASL A (C=0 Z=0 N=1)", 8'hBC);

        // 3. LSR A: 0x8A -> 0x45, C=0 (LSB was 0), N=0
        wait_pc(16'h0204, 5, "LSR A");
        check8("debug_a after LSR A", debug_a, 8'h45);
        check_p("after LSR A (C=0 Z=0 N=0)", 8'h3C);

        // 4. SEC: C=1
        wait_pc(16'h0205, 5, "SEC");
        check_p("after SEC (C=1)", 8'h3D);

        // 5. ROL A: 0x45 with C=1 -> 0x8B, C=0 (MSB was 0), N=1
        wait_pc(16'h0206, 5, "ROL A");
        check8("debug_a after ROL A", debug_a, 8'h8B);
        check_p("after ROL A (C=0 Z=0 N=1)", 8'hBC);

        // 6. ROR A: 0x8B with C=0 -> 0x45, C=1 (LSB was 1), N=0
        wait_pc(16'h0207, 5, "ROR A");
        check8("debug_a after ROR A", debug_a, 8'h45);
        check_p("after ROR A (C=1 Z=0 N=0)", 8'h3D);

        // 7. LDA #$80: N=1 (C keeps 1)
        wait_pc(16'h0209, 10, "LDA #$80");
        check8("debug_a after LDA #$80", debug_a, 8'h80);
        check_p("after LDA #$80 (C=1 Z=0 N=1)", 8'hBD);

        // 8. ASL A: 0x80 -> 0x00, C=1 (MSB was 1), Z=1, N=0
        wait_pc(16'h020A, 5, "ASL A (2nd)");
        check8("debug_a after ASL A (2nd)", debug_a, 8'h00);
        check_p("after ASL A (2nd) (C=1 Z=1 N=0)", 8'h3F);

        // 9. HLT: PC must stay at 0x020A (post-posedge stability)
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
