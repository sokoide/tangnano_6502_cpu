// Simple 6502 Instruction Decoder - Skeleton
// オペコード (opcode) を読み取り、その命令がどの種類に属するかを判定します。

module simple_decoder (
    input  logic [7:0] opcode,
    output logic       is_load,
    output logic       is_store,
    output logic       is_transfer,
    output logic       is_arithmetic,
    output logic       is_logical,
    output logic       is_shift,
    output logic       is_branch,
    output logic       is_jump,
    output logic       is_compare,
    output logic       is_flag,
    output logic       is_stack,
    output logic       is_nop
);

    // -------------------------------------------------------------------------
    // TODO: オペコードに基づき、命令のカテゴリを判定してください。
    // -------------------------------------------------------------------------
    // case文を使用して、各オペコードに対して適切な出力フラグ (is_load等) を 1 に設定します。
    //
    // 主な命令の例:
    // - Load (LDA, LDX, LDY): 0xA9, 0xA2, 0xA0 等
    // - Store (STA, STX, STY): 0x85, 0x86, 0x84 等
    // - Arithmetic (ADC, SBC): 0x69, 0xE9 等
    // - Branch (BPL, BMI, BNE, BEQ): 0x10, 0x30, 0xD0, 0xF0 等
    //
    // 全ての命令を網羅する必要はありませんが、Day 04のテストシーケンスで
    // 使用されている命令を中心に実装してみましょう。
    // 詳細な表は README_ja.md を参照してください。

    always_comb begin
        // デフォルト値の設定（ラッチ防止）
        {is_load, is_store, is_transfer, is_arithmetic} = 4'b0;
        {is_logical, is_shift, is_branch, is_jump} = 4'b0;
        {is_compare, is_flag, is_stack, is_nop} = 4'b0;

        case (opcode)
            // 実装例: LDA (Immediate)
            8'hA9: is_load = 1'b1;

            // 演習: ここに他の命令を追加してください

            default: is_nop = 1'b1;  // 未知のオペコードは NOP として扱う
        endcase
    end

endmodule
