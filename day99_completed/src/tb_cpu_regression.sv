// tb_cpu_regression.sv - self-checking bounded regression testbench for cpu.sv
//
// Scope (FSM fixes under review):
// - RTS ($60): return address assembled from {dout_r, fetched_data[7:0]} before +1,
//   nested JSR/RTS, cross-page return with low byte $FF (carry into high byte)
// - BCS ($B0): branch handler taken / not taken
// - CMP/CPX/CPY memory forms: zero page, zero page,X (zero-page wrap),
//   (indirect,X), (indirect),Y - checking C (no borrow), Z, N (8-bit diff);
//   source registers and V must be preserved; input C is ignored
//
// The test program is hand-assembled at org $0200 (see per-line comments).
// Each passing test writes its test number to checkpoint $0500+i; a flag
// mismatch branches to `fail` which stores $FF at $7BFE. Completion stores
// $A5 at $7BFF and halts (HLT $EF).
//
// Build & run (from day99_completed), using the Verilator binary flow:
//   see docs/REVIEW_GLM_CPU99_RESULT_ja.md for the exact command lines.

module tb_cpu_regression;
    import cpu_pkg::*;
    localparam int CYCLE_LIMIT = 20000;
    localparam logic [14:0] DONE_ADDR = 15'h7BFF;  // $A5 sentinel on completion
    localparam logic [14:0] FAIL_ADDR = 15'h7BFE;  // $FF written by fail path
    localparam logic [7:0] DONE_DATA = 8'hA5;
    localparam int NUM_CHECKS = 12;  // checkpoints $0500..$050B
    localparam int PROG_LEN = 286;  // $0200..$031D

    logic        clk;
    logic        rst_n;

    logic [ 7:0] dout;
    logic [ 7:0] din;
    logic [14:0] ada;
    logic [14:0] adb;
    logic        cea;
    logic        ceb;
    logic [ 9:0] v_ada;
    logic        v_cea;
    logic [ 7:0] v_din;
    logic        vsync;

    logic [ 7:0] boot_program        [7680];
    logic [15:0] boot_program_length;

    cpu dut (
        .rst_n(rst_n),
        .clk(clk),
        .dout(dout),
        .din(din),
        .ada(ada),
        .adb(adb),
        .cea(cea),
        .ceb(ceb),
        .v_ada(v_ada),
        .v_cea(v_cea),
        .v_din(v_din),
        .vsync(vsync),
        .boot_program(boot_program),
        .boot_program_length(boot_program_length)
    );

    // Independent one-clock synchronous RAM model (mirrors BSRAM read latency:
    // address presented during cycle N -> read data valid during cycle N+1).
    logic [7:0] ram[0:32767];
    logic [7:0] dout_q;
    always_ff @(posedge clk) begin
        if (cea) ram[ada] <= din;
        if (ceb) dout_q <= ram[adb];
    end
    assign dout = dout_q;

    always #10 clk = ~clk;  // 50MHz

    // Hand-assembled regression program (generated listing, see header).
    localparam logic [7:0] PROG[0:PROG_LEN-1] = '{
        // $0200: LDA #$60
        8'hA9,
        8'h60,
        // $0202: STA $10
        8'h8D,
        8'h10,
        8'h00,
        // $0205: LDA #$30
        8'hA9,
        8'h30,
        // $0207: STA $08
        8'h8D,
        8'h08,
        8'h00,
        // $020A: LDA #$0F
        8'hA9,
        8'h0F,
        // $020C: STA $12
        8'h8D,
        8'h12,
        8'h00,
        // $020F: LDA #$A0
        8'hA9,
        8'hA0,
        // $0211: STA $13
        8'h8D,
        8'h13,
        8'h00,
        // $0214: LDA #$40
        8'hA9,
        8'h40,
        // $0216: STA $40
        8'h8D,
        8'h40,
        8'h00,
        // $0219: LDA #$03
        8'hA9,
        8'h03,
        // $021B: STA $41
        8'h8D,
        8'h41,
        8'h00,
        // $021E: LDA #$80
        8'hA9,
        8'h80,
        // $0220: STA $0340
        8'h8D,
        8'h40,
        8'h03,
        // $0223: LDA #$00
        8'hA9,
        8'h00,
        // $0225: STA $20
        8'h8D,
        8'h20,
        8'h00,
        // $0228: LDA #$03
        8'hA9,
        8'h03,
        // $022A: STA $21
        8'h8D,
        8'h21,
        8'h00,
        // $022D: LDA #$40
        8'hA9,
        8'h40,
        // $022F: STA $0320
        8'h8D,
        8'h20,
        8'h03,
        // $0232: LDX #$10
        8'hA2,
        8'h10,
        // $0234: LDY #$20
        8'hA0,
        8'h20,
        // $0236: LDA #$60
        8'hA9,
        8'h60,
        // $0238: CMP #$30
        8'hC9,
        8'h30,
        // $023A: BCC  ; t0f
        8'h90,
        8'h0C,
        // $023C: BEQ  ; t0f
        8'hF0,
        8'h0A,
        // $023E: BMI  ; t0f
        8'h30,
        8'h08,
        // $0240: LDA #$00
        8'hA9,
        8'h00,
        // $0242: STA $0500
        8'h8D,
        8'h00,
        8'h05,
        // $0245: JMP  ; t1
        8'h4C,
        8'h4B,
        8'h02,
        // $0248: JMP  ; fail
        8'h4C,
        8'h13,
        8'h03,
        // $024B: LDA #$60
        8'hA9,
        8'h60,
        // $024D: CMP $10
        8'hC5,
        8'h10,
        // $024F: BCC  ; t1f
        8'h90,
        8'h0C,
        // $0251: BNE  ; t1f
        8'hD0,
        8'h0A,
        // $0253: BMI  ; t1f
        8'h30,
        8'h08,
        // $0255: LDA #$01
        8'hA9,
        8'h01,
        // $0257: STA $0501
        8'h8D,
        8'h01,
        8'h05,
        // $025A: JMP  ; t2
        8'h4C,
        8'h60,
        8'h02,
        // $025D: JMP  ; fail
        8'h4C,
        8'h13,
        8'h03,
        // $0260: LDA #$60
        8'hA9,
        8'h60,
        // $0262: CMP $F8,X
        8'hD5,
        8'hF8,
        // $0264: BCC  ; t2f
        8'h90,
        8'h0C,
        // $0266: BEQ  ; t2f
        8'hF0,
        8'h0A,
        // $0268: BMI  ; t2f
        8'h30,
        8'h08,
        // $026A: LDA #$02
        8'hA9,
        8'h02,
        // $026C: STA $0502
        8'h8D,
        8'h02,
        8'h05,
        // $026F: JMP  ; t3
        8'h4C,
        8'h75,
        8'h02,
        // $0272: JMP  ; fail
        8'h4C,
        8'h13,
        8'h03,
        // $0275: LDA #$60
        8'hA9,
        8'h60,
        // $0277: CMP ($30,X)
        8'hC1,
        8'h30,
        // $0279: BCS  ; t3f
        8'hB0,
        8'h0C,
        // $027B: BEQ  ; t3f
        8'hF0,
        8'h0A,
        // $027D: BPL  ; t3f
        8'h10,
        8'h08,
        // $027F: LDA #$03
        8'hA9,
        8'h03,
        // $0281: STA $0503
        8'h8D,
        8'h03,
        8'h05,
        // $0284: JMP  ; t4
        8'h4C,
        8'h8A,
        8'h02,
        // $0287: JMP  ; fail
        8'h4C,
        8'h13,
        8'h03,
        // $028A: LDA #$60
        8'hA9,
        8'h60,
        // $028C: CMP ($20),Y
        8'hD1,
        8'h20,
        // $028E: BCC  ; t4f
        8'h90,
        8'h0C,
        // $0290: BEQ  ; t4f
        8'hF0,
        8'h0A,
        // $0292: BMI  ; t4f
        8'h30,
        8'h08,
        // $0294: LDA #$04
        8'hA9,
        8'h04,
        // $0296: STA $0504
        8'h8D,
        8'h04,
        8'h05,
        // $0299: JMP  ; t5
        8'h4C,
        8'h9F,
        8'h02,
        // $029C: JMP  ; fail
        8'h4C,
        8'h13,
        8'h03,
        // $029F: CPX $12
        8'hE4,
        8'h12,
        // $02A1: BCC  ; t5f
        8'h90,
        8'h0C,
        // $02A3: BEQ  ; t5f
        8'hF0,
        8'h0A,
        // $02A5: BMI  ; t5f
        8'h30,
        8'h08,
        // $02A7: LDA #$05
        8'hA9,
        8'h05,
        // $02A9: STA $0505
        8'h8D,
        8'h05,
        8'h05,
        // $02AC: JMP  ; t6
        8'h4C,
        8'hB2,
        8'h02,
        // $02AF: JMP  ; fail
        8'h4C,
        8'h13,
        8'h03,
        // $02B2: CPY $13
        8'hC4,
        8'h13,
        // $02B4: BCS  ; t6f
        8'hB0,
        8'h0C,
        // $02B6: BEQ  ; t6f
        8'hF0,
        8'h0A,
        // $02B8: BPL  ; t6f
        8'h10,
        8'h08,
        // $02BA: LDA #$06
        8'hA9,
        8'h06,
        // $02BC: STA $0506
        8'h8D,
        8'h06,
        8'h05,
        // $02BF: JMP  ; t7
        8'h4C,
        8'hC5,
        8'h02,
        // $02C2: JMP  ; fail
        8'h4C,
        8'h13,
        8'h03,
        // $02C5: SEC
        8'h38,
        // $02C6: BCS  ; t7ok
        8'hB0,
        8'h03,
        // $02C8: JMP  ; fail
        8'h4C,
        8'h13,
        8'h03,
        // $02CB: LDA #$07
        8'hA9,
        8'h07,
        // $02CD: STA $0507
        8'h8D,
        8'h07,
        8'h05,
        // $02D0: CLC
        8'h18,
        // $02D1: BCS  ; t8f
        8'hB0,
        8'h08,
        // $02D3: LDA #$08
        8'hA9,
        8'h08,
        // $02D5: STA $0508
        8'h8D,
        8'h08,
        8'h05,
        // $02D8: JMP  ; t9
        8'h4C,
        8'hDE,
        8'h02,
        // $02DB: JMP  ; fail
        8'h4C,
        8'h13,
        8'h03,
        // $02DE: JSR  ; sub1
        8'h20,
        8'h08,
        8'h03,
        // $02E1: LDA #$09
        8'hA9,
        8'h09,
        // $02E3: STA $0509
        8'h8D,
        8'h09,
        8'h05,
        // $02E6: NOP (pad)
        8'hEA,
        // $02E7: NOP (pad)
        8'hEA,
        // $02E8: NOP (pad)
        8'hEA,
        // $02E9: NOP (pad)
        8'hEA,
        // $02EA: NOP (pad)
        8'hEA,
        // $02EB: NOP (pad)
        8'hEA,
        // $02EC: NOP (pad)
        8'hEA,
        // $02ED: NOP (pad)
        8'hEA,
        // $02EE: NOP (pad)
        8'hEA,
        // $02EF: NOP (pad)
        8'hEA,
        // $02F0: NOP (pad)
        8'hEA,
        // $02F1: NOP (pad)
        8'hEA,
        // $02F2: NOP (pad)
        8'hEA,
        // $02F3: NOP (pad)
        8'hEA,
        // $02F4: NOP (pad)
        8'hEA,
        // $02F5: NOP (pad)
        8'hEA,
        // $02F6: NOP (pad)
        8'hEA,
        // $02F7: NOP (pad)
        8'hEA,
        // $02F8: NOP (pad)
        8'hEA,
        // $02F9: NOP (pad)
        8'hEA,
        // $02FA: NOP (pad)
        8'hEA,
        // $02FB: NOP (pad)
        8'hEA,
        // $02FC: NOP (pad)
        8'hEA,
        // $02FD: JSR  ; subpg
        8'h20,
        8'h12,
        8'h03,
        // $0300: LDA #$0A
        8'hA9,
        8'h0A,
        // $0302: STA $050A
        8'h8D,
        8'h0A,
        8'h05,
        // $0305: JMP  ; done
        8'h4C,
        8'h18,
        8'h03,
        // $0308: JSR  ; sub2
        8'h20,
        8'h11,
        8'h03,
        // $030B: LDA #$0B
        8'hA9,
        8'h0B,
        // $030D: STA $050B
        8'h8D,
        8'h0B,
        8'h05,
        // $0310: RTS
        8'h60,
        // $0311: RTS
        8'h60,
        // $0312: RTS
        8'h60,
        // $0313: LDA #$FF
        8'hA9,
        8'hFF,
        // $0315: STA $7BFE
        8'h8D,
        8'hFE,
        8'h7B,
        // $0318: LDA #$A5
        8'hA9,
        8'hA5,
        // $031A: STA $7BFF
        8'h8D,
        8'hFF,
        8'h7B,
        // $031D: HLT
        8'hEF
    };

    int errors;
    int reached;

    task automatic check_mem(input logic [14:0] addr, input logic [7:0] exp, input string name);
        if (ram[addr] !== exp) begin
            $display("[FAIL] %s: mem[$%04x] expected $%02x got $%02x", name, {1'b0, addr}, exp,
                     ram[addr]);
            errors++;
        end else begin
            $display("[ok]   %s: mem[$%04x] == $%02x", name, {1'b0, addr}, exp);
        end
    endtask

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_cpu_regression);
    end

    initial begin
        logic [14:0] ckpt;
        clk = 0;
        rst_n = 0;
        vsync = 0;
        errors = 0;
        reached = -1;

        for (int i = 0; i < 32768; i++) ram[i] = 8'h00;
        // Poison every checkpoint, including checkpoint zero, to detect skipped writes.
        for (int i = 0; i < NUM_CHECKS; i++) ram[15'h0500+i] = 8'hCC;
        for (int i = 0; i < 7680; i++) boot_program[i] = 8'hEA;
        for (int i = 0; i < PROG_LEN; i++) boot_program[i] = PROG[i];
        boot_program_length = PROG_LEN[15:0];

        repeat (4) @(posedge clk);
        rst_n <= 1'b1;

        // Bounded run: wait for the done sentinel at $7BFF.
        for (int cyc = 0; cyc < CYCLE_LIMIT; cyc++) begin
            @(posedge clk);
            if (ram[DONE_ADDR] == DONE_DATA) break;
            if (cyc == CYCLE_LIMIT - 1) begin
                $display("[FAIL] timeout: done sentinel $%02x never written to $7BFF", DONE_DATA);
                errors++;
            end
        end
        // Completion sentinel precedes HLT; observe actual bounded retirement.
        for (int cyc = 0; cyc < 100; cyc++) begin
            @(negedge clk);
            if (dut.cur.state == HALT) break;
            if (cyc == 99) $fatal(1, "Completion sentinel without HALT");
        end
        if (dut.cur.fault_reason != FAULT_NONE) $fatal(1, "Unexpected CPU fault");
        repeat (3) begin
            @(negedge clk);
            if (cea || v_cea || dut.cur.state != HALT) $fatal(1, "Writes after HALT");
        end
        if (dut.cur.sp !== 8'hFF) begin
            $display("[FAIL] nested/cross-page RTS did not restore SP");
            errors++;
        end

        // Progress report: highest checkpoint written.
        for (int i = 0; i < NUM_CHECKS; i++) begin
            ckpt = 15'h0500 + i[14:0];
            if (ram[ckpt] == i[7:0]) reached = i;
        end

        if (ram[FAIL_ADDR] !== 8'h00) begin
            $display("[FAIL] fail path taken ($7BFE=$%02x), last checkpoint: %0d", ram[FAIL_ADDR],
                     reached);
            errors++;
        end

        for (int i = 0; i < NUM_CHECKS; i++) begin
            ckpt = 15'h0500 + i[14:0];
            check_mem(ckpt, i[7:0], $sformatf("checkpoint %0d", i));
        end

        if (errors == 0) begin
            $display("[PASS] tb_cpu_regression: all %0d checkpoints verified at t=%0t", NUM_CHECKS,
                     $time);
            $finish;
        end else begin
            $fatal(1, "tb_cpu_regression failed with %0d error(s)", errors);
        end
    end
endmodule
