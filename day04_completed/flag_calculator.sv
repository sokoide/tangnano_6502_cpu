// 6502 Flag Calculator / 6502 フラグ計算機
// Calculates processor status flags (N, Z, C, V) based on arithmetic results.
// 演算結果に基づいてプロセッサのステータスフラグ (N, Z, C, V) を計算します。

module flag_calculator (
    input logic [7:0] result,      // Result of operation / 演算結果
    input logic [7:0] operand_a,   // First operand (usually Accumulator) / 第1オペランド (通常はアキュムレータ)
    input logic [7:0] operand_b,   // Second operand (usually from Memory) / 第2オペランド (通常はメモリ)
    input logic       operation,   // 0:ADD (ADC), 1:SUB (SBC)
    input logic       carry_in,    // Incoming carry flag / 入力キャリーフラグ

    output logic flag_n,  // Negative / ネガティブ (負)
    output logic flag_z,  // Zero / ゼロ
    output logic flag_c,  // Carry / キャリー (桁上げ)
    output logic flag_v   // Overflow / オーバーフロー (溢れ)
);

    logic [8:0] temp_result;

    always_comb begin
        // 9-bit calculation to capture the carry out bit.
        // 桁上げビットをキャプチャするために9ビットで計算します。
        if (operation) begin
            // Subtraction / 減算 (SBC)
            // 6502 subtraction uses binary inversion: A - B - (1 - CarryIn)
            // 6502の減算はバイナリ反転を使用します: A - B - (1 - CarryIn)
            temp_result = {1'b0, operand_a} - {1'b0, operand_b} - {8'b0, ~carry_in};
        end else begin
            // Addition / 加算 (ADC)
            // Result = A + B + CarryIn
            temp_result = {1'b0, operand_a} + {1'b0, operand_b} + {8'b0, carry_in};
        end

        // Basic Flag logic / 基本的なフラグ論理
        flag_n = result[7];           // Negative: Copy of MSB / ネガティブ: 最上位ビットのコピー
        flag_z = (result == 8'h00);   // Zero: True if result is 0x00 / ゼロ: 結果が0x00なら真
        flag_c = temp_result[8];      // Carry: 9th bit of intermediate result / キャリー: 中間結果の9番目のビット

        // Signed Overflow calculation / 符号付きオーバーフローの計算
        // Detects if the signed result is out of -128 to 127 range.
        // This happens if (A and B have the same sign) but (result has a different sign).
        //
        // 符号付きの結果が-128から127の範囲外かどうかを検出します。
        // これは「AとBが同じ符号である」かつ「結果が異なる符号になった」場合に発生します。
        if (operation) begin
            // For subtraction: sign(A) != sign(B) AND sign(A) != sign(result)
            // (e.g., 127 - (-1) = 128 -> Overflow)
            // 減算の場合: AとBの符号が異なり、かつAと結果の符号が異なる場合に発生。
            flag_v = (operand_a[7] != operand_b[7]) && (operand_a[7] != result[7]);
        end else begin
            // For addition: sign(A) == sign(B) AND sign(A) != sign(result)
            // (e.g., 127 + 1 = -128 -> Overflow)
            // 加算の場合: AとBの符号が同じで、かつAと結果の符号が異なる場合に発生。
            flag_v = (operand_a[7] == operand_b[7]) && (operand_a[7] != result[7]);
        end
    end

endmodule