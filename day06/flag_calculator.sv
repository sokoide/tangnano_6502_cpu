// 6502 Flag Calculator - Skeleton
// Calculate status flags (N, Z, C, V) based on the operation result.
// 演算結果に基づいてステータスフラグ (N, Z, C, V) を計算します。

module flag_calculator (
    input logic [7:0] result,
    input logic [7:0] operand_a,
    input logic [7:0] operand_b,
    input logic       operation,  // 0:ADD, 1:SUB
    input logic       carry_in,

    output logic flag_n,
    output logic flag_z,
    output logic flag_c,
    output logic flag_v
);

    // -------------------------------------------------------------------------
    // TODO: Implement the status flag calculation logic using combinational logic (always_comb).
    // TODO: ステータスフラグの計算論理を組合せ回路 (always_comb) で実装してください。
    // -------------------------------------------------------------------------
    //
    // N (Negative): Reflect the most significant bit (bit 7) of the result as is.
    // N (Negative): 結果の最上位ビット (ビット7) をそのまま反映します。
    //
    // Z (Zero): Becomes 1 when the result is 0x00.
    // Z (Zero): 結果 (result) が 0x00 のときに 1 となります。
    //
    // C (Carry): Becomes 1 when an overflow occurs in addition (ADC), or when there is no borrow in subtraction (SBC).
    // C (Carry): 加算(ADC)で桁溢れが発生したとき、または減算(SBC)で借位がないときに 1 となります。
    //   Hint: Use a 9-bit intermediate variable and treat the 9th bit (bit 8) as the carry.
    //   ヒント: 9ビットの中間変数を使用して、9番目のビット (ビット8) をキャリーとして扱います。
    //
    // V (Overflow): Becomes 1 when the result of a signed operation exceeds the 8-bit representation range (-128 to 127).
    // V (Overflow): 符号付き演算の結果が、8ビットの表現範囲 (-128〜127) を超えたときに 1 となります。
    //   Hint: Consider the condition "Input A and input B have the same sign, and the result has a different sign" (during addition).
    //   ヒント: 「入力Aと入力Bの符号が同じで、結果の符号がそれと異なる」条件（加算時）を考えてみましょう。
    //   In the case of subtraction (SBC), it can be thought of as addition by inverting the sign of B.
    //   減算(SBC)の場合は、Bの符号を反転させて加算として考えることができます。

endmodule
