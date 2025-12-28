// Day 05: CPU Core with PC - Skeleton
//
// 学習目標:
// 1. CPUモジュールのインスタンス化
// 2. モジュール間の信号接続
// 3. PCの値をLCDに表示するための配線

module top_core (
    input logic       clk,
    input logic       rst_n,
    input logic [3:0] switches,

    // Debug outputs for LCD
    output logic [15:0] debug_pc,
    output logic [7:0]  unused_flags
);

    // -------------------------------------------------------------------------
    // TODO: CPU モジュールをインスタンス化してください。
    // -------------------------------------------------------------------------
    // - インスタンス名は "u_cpu" としてください。
    // - 各ポート (clk, rst_n, pc_enable, address_bus, debug_pc) を接続します。
    // - pc_enable には、適切なイネーブル信号を供給してください。

    logic [15:0] cpu_pc;
    logic        pc_enable;

    // TODO: cpu モジュールのインスタンス化
    /*
    cpu u_cpu (
        .clk(clk),
        .rst_n(rst_n),
        .pc_enable(pc_enable),
        .address_bus(),
        .debug_pc(cpu_pc)
    );
    */

    // --- デバッグ用のイネーブル信号生成 (実装済み) ---
    // LCD表示で数値の変化を確認しやすくするため、クロックを分周します。
    logic [23:0] counter;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 24'd0;
        end else begin
            counter <= counter + 1;
        end
    end
    assign pc_enable = (counter == 24'd0);

    // 出力接続
    assign debug_pc = cpu_pc;
    assign unused_flags = 8'h00;

endmodule
