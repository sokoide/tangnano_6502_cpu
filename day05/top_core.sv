// Day 05: CPU Core with PC - Skeleton
//
// Learning Goals: / 学習目標:
// 1. Instantiation of CPU module / CPUモジュールのインスタンス化
// 2. Signal connection between modules / モジュール間の信号接続
// 3. Wiring to display the PC value on the LCD / PCの値をLCDに表示するための配線

module top_core (
    input logic       clk,
    input logic       rst_n,
    input logic [3:0] switches,

    // Debug outputs for LCD
    output logic [15:0] debug_pc,
    output logic [ 7:0] unused_flags
);

    // -------------------------------------------------------------------------
    // TODO: Instantiate the CPU module.
    // TODO: CPU モジュールをインスタンス化してください。
    // -------------------------------------------------------------------------
    // - Use "u_cpu" as the instance name. / - インスタンス名は "u_cpu" としてください。
    // - Connect each port (clk, rst_n, pc_enable, address_bus, debug_pc). / - 各ポート (clk, rst_n, pc_enable, address_bus, debug_pc) を接続します。
    // - Supply an appropriate enable signal to pc_enable. / - pc_enable には、適切なイネーブル信号を供給してください。

    logic [15:0] cpu_pc;
    logic        pc_enable;

    // TODO: Instantiate the cpu module / TODO: cpu モジュールのインスタンス化
    /*
    cpu u_cpu (
        .clk(clk),
        .rst_n(rst_n),
        .pc_enable(pc_enable),
        .address_bus(),
        .debug_pc(cpu_pc)
    );
    */

    // --- Debug enable signal generation (already implemented) ---
    // --- デバッグ用のイネーブル信号生成 (実装済み) ---
    // Divide the clock to make it easier to see the changes in numerical values on the LCD display.
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

    // Output connections
    // 出力接続
    assign debug_pc = cpu_pc;
    assign unused_flags = 8'h00;

endmodule
