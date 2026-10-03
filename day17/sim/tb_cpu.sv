// Day 17: Indirect Addressing ((zp,X), (zp),Y, JMP (abs)) - Logic Testbench
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
        #400000;  // 20000 cycles
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
        $display("=== Day 17: Indirect Addressing Test ===");

        // Main program at $0200:
        // $0200: LDX #$03
        // $0202: LDA ($40,X)  ; ptr = $40+3 = $43 -> $1234 -> A = 99
        // $0204: LDX #$05
        // $0206: LDA ($FE,X)  ; ptr = $FE+5 wraps to $03 -> $1250 -> A = AA
        // $0208: LDY #$04
        // $020A: LDA ($60),Y  ; ptr $60 -> base $1140, +Y=4 -> $1144 -> A = BB
        // $020C: LDY #$00
        // $020E: LDA ($FF),Y  ; ptr $FF: low@$FF, high@$00 (ZP wrap) -> $1360 -> A = CC
        // $0210: JSR $0250    ; subroutine: LDA #$42 / RTS (return to $0213)
        // $0213: JMP ($2000)  ; pointer at $2000 -> $0230
        // Subroutine at $0250: LDA #$42 / RTS
        // Landing at $0230: LDA #$DD / HLT
        mem[16'h0200] = 8'hA2;  // LDX imm
        mem[16'h0201] = 8'h03;
        mem[16'h0202] = 8'hA1;  // LDA (zp,X)
        mem[16'h0203] = 8'h40;
        mem[16'h0204] = 8'hA2;  // LDX imm
        mem[16'h0205] = 8'h05;
        mem[16'h0206] = 8'hA1;  // LDA (zp,X)
        mem[16'h0207] = 8'hFE;
        mem[16'h0208] = 8'hA0;  // LDY imm
        mem[16'h0209] = 8'h04;
        mem[16'h020A] = 8'hB1;  // LDA (zp),Y
        mem[16'h020B] = 8'h60;
        mem[16'h020C] = 8'hA0;  // LDY imm
        mem[16'h020D] = 8'h00;
        mem[16'h020E] = 8'hB1;  // LDA (zp),Y
        mem[16'h020F] = 8'hFF;
        mem[16'h0210] = 8'h20;  // JSR $0250
        mem[16'h0211] = 8'h50;  // low
        mem[16'h0212] = 8'h02;  // high (0x02: RAM program space, not 0x80)
        mem[16'h0213] = 8'h6C;  // JMP (abs)
        mem[16'h0214] = 8'h00;  // low
        mem[16'h0215] = 8'h20;  // high
        mem[16'h0230] = 8'hA9;  // LDA imm (JMP (abs) landing)
        mem[16'h0231] = 8'hDD;
        mem[16'h0232] = 8'hEF;  // HLT
        mem[16'h0250] = 8'hA9;  // LDA imm (subroutine)
        mem[16'h0251] = 8'h42;
        mem[16'h0252] = 8'h60;  // RTS

        // Seeded pointer tables and data
        mem[16'h0043] = 8'h34;  // (zp,X) pointer low  for ($40,X), X=3
        mem[16'h0044] = 8'h12;  // (zp,X) pointer high
        mem[16'h1234] = 8'h99;  // (zp,X) data
        mem[16'h0003] = 8'h50;  // (zp,X) pointer low  for ($FE,X), X=5 (ZP wrap: FE+5=03)
        mem[16'h0004] = 8'h12;  // (zp,X) pointer high (ZP wrap: 03+1=04)
        mem[16'h1250] = 8'hAA;  // (zp,X) data
        mem[16'h0060] = 8'h40;  // (zp),Y pointer low  for ($60),Y
        mem[16'h0061] = 8'h11;  // (zp),Y pointer high
        mem[16'h1144] = 8'hBB;  // (zp),Y data (base $1140 + Y=4)
        mem[16'h00FF] = 8'h60;  // (zp),Y pointer low  at $FF (ZP wrap: high read from $00)
        mem[16'h0000] = 8'h13;  // (zp),Y pointer high (wraps to $0000)
        mem[16'h1360] = 8'hCC;  // (zp),Y data
        mem[16'h2000] = 8'h30;  // JMP (abs) pointer low
        mem[16'h2001] = 8'h02;  // JMP (abs) pointer high -> $0230

        clk = 0;
        rst_n = 0;
        pc_enable = 1;

        // Release reset on negedge
        @(negedge clk);
        rst_n = 1;

        // 1. LDX #$03
        wait_pc(16'h0202, 10, "LDX #$03");
        check8("debug_x after LDX #$03", debug_x, 8'h03);

        // 2. LDA ($40,X): pointer at $0043 -> $1234
        wait_pc(16'h0204, 15, "LDA ($40,X)");
        check8("debug_a after LDA ($40,X)", debug_a, 8'h99);

        // 3. LDX #$05
        wait_pc(16'h0206, 10, "LDX #$05");
        check8("debug_x after LDX #$05", debug_x, 8'h05);

        // 4. LDA ($FE,X): zp+X wraps to $03, pointer high wraps $03+1 -> $04 (ZP wrap)
        wait_pc(16'h0208, 15, "LDA ($FE,X)");
        check8("debug_a after LDA ($FE,X) (ZP wrap)", debug_a, 8'hAA);

        // 5. LDY #$04
        wait_pc(16'h020A, 10, "LDY #$04");
        check8("debug_y after LDY #$04", debug_y, 8'h04);

        // 6. LDA ($60),Y: base $1140 + 4 = $1144
        wait_pc(16'h020C, 15, "LDA ($60),Y");
        check8("debug_a after LDA ($60),Y", debug_a, 8'hBB);

        // 7. LDY #$00
        wait_pc(16'h020E, 10, "LDY #$00");
        check8("debug_y after LDY #$00", debug_y, 8'h00);

        // 8. LDA ($FF),Y: pointer low at $FF, high wraps to $00 -> $1360
        wait_pc(16'h0210, 15, "LDA ($FF),Y");
        check8("debug_a after LDA ($FF),Y (ZP wrap)", debug_a, 8'hCC);

        // 9. JSR $0250: subroutine executes LDA #$42, RTS returns to $0213
        wait_pc(16'h0250, 15, "JSR $0250");
        check8("debug_s after JSR", debug_s, 8'hFD);
        check8("mem[0x01FF] after JSR (PCH)", mem[16'h01FF], 8'h02);
        check8("mem[0x01FE] after JSR (PCL)", mem[16'h01FE], 8'h12);
        wait_pc(16'h0213, 15, "RTS");
        check8("debug_a after subroutine LDA #$42", debug_a, 8'h42);
        check8("debug_s after RTS", debug_s, 8'hFF);

        // 10. JMP ($2000): PC must be loaded from pointer at $2000 -> $0230
        wait_pc(16'h0230, 15, "JMP ($2000)");

        // 11. LDA #$DD at the JMP landing
        wait_pc(16'h0232, 10, "LDA #$DD");
        check8("debug_a after LDA #$DD", debug_a, 8'hDD);

        // 12. HLT: PC must stay at 0x0232 (post-posedge stability)
        repeat (3) begin
            @(posedge clk);
            #1;
        end
        if (debug_pc !== 16'h0232) begin
            $display("FAIL: debug_pc after HLT = 0x%04h (expected 0x0232)", debug_pc);
            error_count++;
        end else begin
            $display("PASS: debug_pc stays at 0x0232 after HLT");
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
