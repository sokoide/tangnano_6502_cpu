// Day 04 Completed: Simple Instruction Decoder / 簡易命令デコーダ
//
// This module classifies 6502 opcodes into functional categories.
// Classifying opcodes is the first step toward building the CPU Control Unit.
// 6502のオペコードを機能的なカテゴリに分類します。
// これはCPU制御ユニット(Control Unit)を構築するための第一歩です。

module simple_decoder (
    input logic [7:0] opcode,  // 8-bit Instruction Opcode / 8ビット命令オペコード

    // Category output flags / カテゴリ出力フラグ
    output logic is_load,        // LDA, LDX, LDY
    output logic is_store,       // STA, STX, STY
    output logic is_transfer,    // TAX, TAY, TSX, TXA, TXS, TYA
    output logic is_arithmetic,  // ADC, SBC
    output logic is_logical,     // AND, ORA, EOR
    output logic is_shift,       // ASL, LSR, ROL, ROR
    output logic is_branch,      // BCC, BCS, BEQ, BMI, BNE, BPL, BVC, BVS
    output logic is_jump,        // JMP, JSR, RTS
    output logic is_compare,     // CMP, CPX, CPY
    output logic is_flag,        // CLC, SEC, CLI, SEI, CLV, CLD, SED
    output logic is_stack,       // PHA, PHP, PLA, PLP
    output logic is_nop          // NOP (No Operation)
);

    always_comb begin
        // Default all flags to 0 to avoid unintended latches.
        // ラッチの発生を防ぐため、すべてのフラグを0に初期化します。
        {is_load, is_store, is_transfer, is_arithmetic} = 4'b0000;
        {is_logical, is_shift, is_branch, is_jump} = 4'b0000;
        {is_compare, is_flag, is_stack, is_nop} = 4'b0000;

        // In a real 6502, opcodes can often be decoded by looking at specific bit
        // patterns (e.g., bit [1:0] defines the instruction group).
        // Here, we use a case statement for maximum clarity and ease of learning.
        // 実際の6502では、特定のビットパターン(例: bit[1:0]で命令グループを定義)を見て
        // デコードすることが多いですが、ここでは学習のしやすさと明快さを優先し、
        // case文を使用しています。

        case (opcode)
            // LDA: Load Accumulator / アキュムレータにロード
            8'hA9, 8'hA5, 8'hB5, 8'hAD, 8'hBD, 8'hB9, 8'hA1, 8'hB1: is_load = 1'b1;

            // LDX: Load X Register / Xレジスタにロード
            8'hA2, 8'hA6, 8'hB6, 8'hAE, 8'hBE: is_load = 1'b1;

            // LDY: Load Y Register / Yレジスタにロード
            8'hA0, 8'hA4, 8'hB4, 8'hAC, 8'hBC: is_load = 1'b1;

            // STA: Store Accumulator / アキュムレータを保存
            8'h85, 8'h95, 8'h8D, 8'h9D, 8'h99, 8'h81, 8'h91: is_store = 1'b1;

            // STX: Store X Register / Xレジスタを保存
            8'h86, 8'h96, 8'h8E: is_store = 1'b1;

            // STY: Store Y Register / Yレジスタを保存
            8'h84, 8'h94, 8'h8C: is_store = 1'b1;

            // Transfer: Registers to Registers / レジスタ間転送
            8'hAA, 8'hA8, 8'h8A, 8'h98, 8'hBA, 8'h9A: is_transfer = 1'b1;

            // ADC: Add with Carry / キャリー付き加算
            8'h69, 8'h65, 8'h75, 8'h6D, 8'h7D, 8'h79, 8'h61, 8'h71: is_arithmetic = 1'b1;

            // SBC: Subtract with Carry / キャリー付き減算
            8'hE9, 8'hE5, 8'hF5, 8'hED, 8'hFD, 8'hF9, 8'hE1, 8'hF1: is_arithmetic = 1'b1;

            // Logical: AND, ORA, EOR / 論理演算
            8'h29, 8'h25, 8'h35, 8'h2D, 8'h3D, 8'h39, 8'h21, 8'h31: is_logical = 1'b1;
            8'h09, 8'h05, 8'h15, 8'h0D, 8'h1D, 8'h19, 8'h01, 8'h11: is_logical = 1'b1;
            8'h49, 8'h45, 8'h55, 8'h4D, 8'h5D, 8'h59, 8'h41, 8'h51: is_logical = 1'b1;

            // Shift/Rotate: Bit manipulations / シフト・回転演算
            8'h0A, 8'h06, 8'h16, 8'h0E, 8'h1E: is_shift = 1'b1;  // ASL
            8'h4A, 8'h46, 8'h56, 8'h4E, 8'h5E: is_shift = 1'b1;  // LSR
            8'h2A, 8'h26, 8'h36, 8'h2E, 8'h3E: is_shift = 1'b1;  // ROL
            8'h6A, 8'h66, 8'h76, 8'h6E, 8'h7E: is_shift = 1'b1;  // ROR

            // Branch: Relative jumps / 条件分岐
            8'h10, 8'h30, 8'h50, 8'h70, 8'h90, 8'hB0, 8'hD0, 8'hF0: is_branch = 1'b1;

            // Jump: Absolute and Subroutine / ジャンプ・サブルーチン
            8'h4C, 8'h6C, 8'h20, 8'h60: is_jump = 1'b1;

            // Compare: A, X, Y against memory / メモリとの比較
            8'hC9, 8'hC5, 8'hD5, 8'hCD, 8'hDD, 8'hD9, 8'hC1, 8'hD1: is_compare = 1'b1;  // CMP
            8'hE0, 8'hE4, 8'hEC: is_compare = 1'b1;  // CPX
            8'hC0, 8'hC4, 8'hCC: is_compare = 1'b1;  // CPY

            // Flag: Processor state control / フラグ操作
            8'h18, 8'h38, 8'h58, 8'h78, 8'hB8, 8'hD8, 8'hF8: is_flag = 1'b1;

            // Stack: Push and Pull / スタック操作
            8'h48, 8'h68, 8'h08, 8'h28: is_stack = 1'b1;

            // NOP: No Operation / 何もしない
            8'hEA: is_nop = 1'b1;

            default: is_nop = 1'b1;  // Treat unknown opcodes as NOP
        endcase
    end

endmodule
