// Day 15: Comparison (CMP/CPX/CPY), Memory Inc/Dec (INC/DEC) & Register Decrement (DEX/DEY) - Logic Testbench
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
        $display("=== Day 15: CMP/CPX/CPY, INC/DEC & DEX/DEY Test ===");

        // Memory setup
        // $0200: LDA #$50
        // $0202: CMP #$50   ; equal:      C=1 Z=1 N=0, A unchanged
        // $0204: CMP #$51   ; 50 < 51:    C=0 Z=0 N=1
        // $0206: LDX #$05
        // $0208: CPX #$03   ; 05 > 03:    C=1 Z=0 N=0
        // $020A: LDY #$07
        // $020C: CPY #$09   ; 07 < 09:    C=0 Z=0 N=1
        // $020E: INC $30    ; 0F -> 10:   Z=0 N=0
        // $0210: INC $31    ; FF -> 00:   Z=1 N=0 (wrap)
        // $0212: DEC $32    ; 00 -> FF:   Z=0 N=1 (wrap)
        // $0214: DEC $30    ; 10 -> 0F:   Z=0 N=0
        // $0216: DEX        ; X 05 -> 04: Z=0 N=0
        // $0217: DEY        ; Y 07 -> 06: Z=0 N=0
        // $0218: LDX #$01
        // $021A: DEX        ; 01 -> 00:   Z=1 N=0
        // $021B: LDY #$00
        // $021D: DEY        ; 00 -> FF:   Z=0 N=1 (wrap)
        // $021E: HLT
        mem[16'h0200] = 8'hA9;
        mem[16'h0201] = 8'h50;
        mem[16'h0202] = 8'hC9;  // CMP imm
        mem[16'h0203] = 8'h50;
        mem[16'h0204] = 8'hC9;  // CMP imm
        mem[16'h0205] = 8'h51;
        mem[16'h0206] = 8'hA2;  // LDX imm
        mem[16'h0207] = 8'h05;
        mem[16'h0208] = 8'hE0;  // CPX imm
        mem[16'h0209] = 8'h03;
        mem[16'h020A] = 8'hA0;  // LDY imm
        mem[16'h020B] = 8'h07;
        mem[16'h020C] = 8'hC0;  // CPY imm
        mem[16'h020D] = 8'h09;
        mem[16'h020E] = 8'hE6;  // INC zp
        mem[16'h020F] = 8'h30;
        mem[16'h0210] = 8'hE6;  // INC zp
        mem[16'h0211] = 8'h31;
        mem[16'h0212] = 8'hC6;  // DEC zp
        mem[16'h0213] = 8'h32;
        mem[16'h0214] = 8'hC6;  // DEC zp
        mem[16'h0215] = 8'h30;
        mem[16'h0216] = 8'hCA;  // DEX
        mem[16'h0217] = 8'h88;  // DEY
        mem[16'h0218] = 8'hA2;  // LDX imm
        mem[16'h0219] = 8'h01;
        mem[16'h021A] = 8'hCA;  // DEX (01 -> 00)
        mem[16'h021B] = 8'hA0;  // LDY imm
        mem[16'h021C] = 8'h00;
        mem[16'h021D] = 8'h88;  // DEY (00 -> FF)
        mem[16'h021E] = 8'hEF;  // HLT
        mem[16'h0030] = 8'h0F;
        mem[16'h0031] = 8'hFF;
        mem[16'h0032] = 8'h00;

        clk = 0;
        rst_n = 0;
        pc_enable = 1;

        // Release reset on negedge
        @(negedge clk);
        rst_n = 1;

        // 1. LDA #$50
        wait_pc(16'h0202, 10, "LDA #$50");
        check8("debug_a after LDA #$50", debug_a, 8'h50);

        // 2. CMP #$50 (equal)
        wait_pc(16'h0204, 10, "CMP #$50");
        check8("debug_a after CMP #$50 (A unchanged)", debug_a, 8'h50);
        check_p("after CMP #$50 (C=1 Z=1 N=0)", 8'h3F);

        // 3. CMP #$51 (A < operand: borrow)
        wait_pc(16'h0206, 10, "CMP #$51");
        check_p("after CMP #$51 (C=0 Z=0 N=1)", 8'hBC);

        // 4. LDX #$05
        wait_pc(16'h0208, 10, "LDX #$05");
        check8("debug_x after LDX #$05", debug_x, 8'h05);

        // 5. CPX #$03 (X > operand)
        wait_pc(16'h020A, 10, "CPX #$03");
        check_p("after CPX #$03 (C=1 Z=0 N=0)", 8'h3D);

        // 6. LDY #$07
        wait_pc(16'h020C, 10, "LDY #$07");
        check8("debug_y after LDY #$07", debug_y, 8'h07);

        // 7. CPY #$09 (Y < operand: borrow)
        wait_pc(16'h020E, 10, "CPY #$09");
        check_p("after CPY #$09 (C=0 Z=0 N=1)", 8'hBC);

        // 8. INC $30: 0x0F -> 0x10
        wait_pc(16'h0210, 10, "INC $30");
        check8("mem[0x0030] after INC $30", mem[16'h0030], 8'h10);
        check_p("after INC $30 (Z=0 N=0)", 8'h3C);

        // 9. INC $31: 0xFF -> 0x00 (wrap)
        wait_pc(16'h0212, 10, "INC $31");
        check8("mem[0x0031] after INC $31", mem[16'h0031], 8'h00);
        check_p("after INC $31 (Z=1 N=0)", 8'h3E);

        // 10. DEC $32: 0x00 -> 0xFF (wrap)
        wait_pc(16'h0214, 10, "DEC $32");
        check8("mem[0x0032] after DEC $32", mem[16'h0032], 8'hFF);
        check_p("after DEC $32 (Z=0 N=1)", 8'hBC);

        // 11. DEC $30: 0x10 -> 0x0F
        wait_pc(16'h0216, 10, "DEC $30");
        check8("mem[0x0030] after DEC $30", mem[16'h0030], 8'h0F);
        check_p("after DEC $30 (Z=0 N=0)", 8'h3C);

        // 12. DEX: X 05 -> 04 (C=0 carried over from CPY #$09)
        wait_pc(16'h0217, 10, "DEX");
        check8("debug_x after DEX", debug_x, 8'h04);
        check_p("after DEX (Z=0 N=0)", 8'h3C);

        // 13. DEY: Y 07 -> 06
        wait_pc(16'h0218, 10, "DEY");
        check8("debug_y after DEY", debug_y, 8'h06);
        check_p("after DEY (Z=0 N=0)", 8'h3C);

        // 14. LDX #$01 / DEX: 01 -> 00 (Z=1)
        wait_pc(16'h021A, 10, "LDX #$01");
        check8("debug_x after LDX #$01", debug_x, 8'h01);
        wait_pc(16'h021B, 10, "DEX wrap-to-zero");
        check8("debug_x after DEX (01 -> 00)", debug_x, 8'h00);
        check_p("after DEX 01 -> 00 (Z=1 N=0)", 8'h3E);

        // 15. LDY #$00 / DEY: 00 -> FF (wrap, N=1)
        wait_pc(16'h021D, 10, "LDY #$00");
        check8("debug_y after LDY #$00", debug_y, 8'h00);
        wait_pc(16'h021E, 10, "DEY wrap");
        check8("debug_y after DEY (00 -> FF)", debug_y, 8'hFF);
        check_p("after DEY 00 -> FF (Z=0 N=1)", 8'hBC);

        // 16. HLT: PC must stay at 0x021E (post-posedge stability)
        repeat (3) begin
            @(posedge clk);
            #1;
        end
        if (debug_pc !== 16'h021E) begin
            $display("FAIL: debug_pc after HLT = 0x%04h (expected 0x021E)", debug_pc);
            error_count++;
        end else begin
            $display("PASS: debug_pc stays at 0x021E after HLT");
        end

        // Exercise preservation with both C and V set, not only their reset values.
        @(negedge clk);
        rst_n = 0;
        mem[16'h0200] = 8'hA9;
        mem[16'h0201] = 8'h7F;  // LDA #$7F
        mem[16'h0202] = 8'h18;  // CLC
        mem[16'h0203] = 8'h69;
        mem[16'h0204] = 8'h01;  // ADC #1: A=$80 V=1
        mem[16'h0205] = 8'h38;  // SEC: C=1
        mem[16'h0206] = 8'hA2;
        mem[16'h0207] = 8'h01;  // LDX #1
        mem[16'h0208] = 8'hA0;
        mem[16'h0209] = 8'h00;  // LDY #0
        mem[16'h020A] = 8'hCA;  // DEX: X=0, Z=1, C/V retained
        mem[16'h020B] = 8'h88;  // DEY: Y=$FF, N=1, C/V retained
        mem[16'h020C] = 8'hEF;  // HLT
        repeat (2) @(negedge clk);
        rst_n = 1;
        wait_pc(16'h020A, 80, "prepare C=1 V=1");
        check_p("before DEX C=1 V=1", 8'h7F);
        wait_pc(16'h020B, 10, "DEX preserves set C/V");
        check8("DEX X=0", debug_x, 8'h00);
        check_p("DEX retains C=1 V=1", 8'h7F);
        wait_pc(16'h020C, 10, "DEY preserves set C/V");
        check8("DEY Y=FF", debug_y, 8'hFF);
        check8("DEX/DEY leave A unchanged", debug_a, 8'h80);
        check_p("DEY retains C=1 V=1", 8'hFD);

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
