// 6502 Flag Calculator - Skeleton
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
    // TODO: ステータスフラグの計算論理を組合せ回路 (always_comb) で実装してください。
    // -------------------------------------------------------------------------
    //
    // N (Negative): 結果の最上位ビット (ビット7) をそのまま反映します。
    //
    // Z (Zero): 結果 (result) が 0x00 のときに 1 となります。
    //
    // C (Carry): 加算(ADC)で桁溢れが発生したとき、または減算(SBC)で借位がないときに 1 となります。
    //   ヒント: 9ビットの中間変数を使用して、9番目のビット (ビット8) をキャリーとして扱います。
    //
    // V (Overflow): 符号付き演算の結果が、8ビットの表現範囲 (-128〜127) を超えたときに 1 となります。
    //   ヒント: 「入力Aと入力Bの符号が同じで、結果の符号がそれと異なる」条件（加算時）を考えてみましょう。
    //   減算(SBC)の場合は、Bの符号を反転させて加算として考えることができます。

endmodule
