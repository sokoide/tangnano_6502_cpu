// Day 05: CPU Heart (Program Counter & NOP) - Skeleton
//
// 学習目標:
// 1. プログラムカウンタ (PC) の役割と実装
// 2. クロック同期によるレジスタの更新
// 3. リセット時の初期化動作

module cpu (
    input  logic        clk,
    input  logic        rst_n,        // Active-low reset
    input  logic        pc_enable,    // Enable signal for PC update (visual debugging)
    output logic [15:0] address_bus,
    output logic [15:0] debug_pc
);

    logic [15:0] pc;

    // -------------------------------------------------------------------------
    // TODO: プログラムカウンタ (PC) を順序回路 (always_ff) で実装してください。
    // -------------------------------------------------------------------------
    // 1. リセット時の動作 (rst_n == 0):
    //    PC を 16'h8000 に初期化してください。
    //    (6502の本来の開始アドレスは 0xFFFC ですが、本プロジェクトでは 0x8000 を使用します)
    //
    // 2. 通常時の動作 (clk 立ち上がり時):
    //    pc_enable が '1' のときに、PC を 1 増加させてください (PC <= PC + 1)。
    //    pc_enable が '0' のときは、現在の値を保持してください。

    // デフォルトの実装（TODO: 以下のブロックを自分で書き換えてください）
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= 16'h8000;
        end else begin
            // ここに PC 更新ロジックを記述
        end
    end

    // アドレスバスとデバッグ出力への接続
    assign address_bus = pc;
    assign debug_pc = pc;

endmodule
