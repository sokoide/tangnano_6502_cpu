// Day 05: CPU Heart (Program Counter & NOP) - Skeleton
//
// Learning Goals: / 学習目標:
// 1. Role and implementation of Program Counter (PC) / プログラムカウンタ (PC) の役割と実装
// 2. Register update by clock synchronization / クロック同期によるレジスタの更新
// 3. Initialization operation during reset / リセット時の初期化動作

module cpu (
    input  logic        clk,
    input  logic        rst_n,        // Active-low reset
    input  logic        pc_enable,    // Enable signal for PC update (visual debugging)
    output logic [15:0] address_bus,
    output logic [15:0] debug_pc
);

    logic [15:0] pc;

    // -------------------------------------------------------------------------
    // TODO: Implement the Program Counter (PC) using sequential logic (always_ff).
    // TODO: プログラムカウンタ (PC) を順序回路 (always_ff) で実装してください。
    // -------------------------------------------------------------------------
    // 1. Operation during reset (rst_n == 0): / リセット時の動作 (rst_n == 0):
    //    Initialize PC to 16'h0200. / PC を 16'h0200 に初期化してください。
    //    (The original start address of 6502 is 0xFFFC, but this project uses 0x8000)
    //    (6502の本来の開始アドレスは 0xFFFC ですが、本プロジェクトでは 0x8000 を使用します)
    //
    // 2. Normal operation (at rising edge of clk): / 通常時の動作 (clk 立ち上がり時):
    //    When pc_enable is '1', increment PC by 1 (PC <= PC + 1).
    //    pc_enable が '1' のときに、PC を 1 増加させてください (PC <= PC + 1)。
    //    When pc_enable is '0', maintain the current value.
    //    pc_enable が '0' のときは、現在の値を保持してください。

    // Default implementation (TODO: Rewrite the block below yourself)
    // デフォルトの実装（TODO: 以下のブロックを自分で書き換えてください）
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= 16'h0200;
        end else begin
            // Describe PC update logic here
            // ここに PC 更新ロジックを記述
        end
    end

    // Connection to address bus and debug output
    // アドレスバスとデバッグ出力への接続
    assign address_bus = pc;
    assign debug_pc = pc;

endmodule
