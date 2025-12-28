// Day 04 Completed: 6502 Register Set / 6502 レジスタセット
//
// This module implements the internal memory elements of the 6502 CPU.
// In FPGA design, these are typically mapped to Flip-Flops.
// 6502 CPUの内部記憶素子（レジスタ）を実装します。
// FPGA設計では、これらは通常フリップフロップとして構成されます。

module cpu_registers (
    input logic clk,   // System Clock / システムクロック
    input logic rst_n, // Active-low Reset / 非アクティブ低レベル・リセット

    // Register write enables / レジスタ書き込み有効化信号
    input logic a_write,   // Accumulator (A) / アキュムレータ
    input logic x_write,   // X Index Register (X) / Xインデックスレジスタ
    input logic y_write,   // Y Index Register (Y) / Yインデックスレジスタ
    input logic sp_write,  // Stack Pointer (SP) / スタックポインタ
    input logic pc_write,  // Program Counter (PC) / プログラムカウンタ
    input logic p_write,   // Processor Status (P) / プロセッサステータス

    // Data inputs / データ入力
    input logic [ 7:0] data_in,  // 8-bit data input / 8ビットデータ入力
    input logic [15:0] addr_in,  // 16-bit address for PC / PC用16ビットアドレス入力

    // Register outputs (for monitoring and ALU use) / レジスタ出力（監視およびALU用）
    output logic [ 7:0] reg_a,   // Accumulator: Primary register for arithmetic/logic / A: 算術演算・論理演算の主要レジスタ
    output logic [ 7:0] reg_x,   // X Index: Used for addressing and counters / X: アドレス修飾やカウンタに使用
    output logic [ 7:0] reg_y,   // Y Index: Used for addressing and counters / Y: アドレス修飾やカウンタに使用
    output logic [ 7:0] reg_sp,  // Stack Pointer: Points to next available stack slot / SP: スタックの空き位置を指す
    output logic [15:0] reg_pc,  // Program Counter: Address of current instruction / PC: 現在実行中の命令アドレス
    output logic [ 7:0] reg_p    // Processor Status: Holds flags (N, V, Z, C, etc.) / P: フラグ状態を保持
);

    // Sequential logic for register updates / レジスタ更新用の順序回路
    // All register changes occur on the rising edge of 'clk'.
    // すべてのレジスタ変更は'clk'の立ち上がりエッジで発生します。
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Initial states after reset / リセット直後の初期状態
            reg_a <= 8'h00;
            reg_x <= 8'h00;
            reg_y <= 8'h00;
            reg_sp <= 8'hFF;     // Stack pointer typically resets to 0xFF (top of page 1) / SPは通常0xFF(ページ1の最上部)にリセット
            reg_pc <= 16'h0200;  // Standard reset vector start for this training / この演習用プログラムの開始位置
            reg_p  <= 8'h34;     // Default status (Break=0, Unused=1, IRQ=1) / 初期ステータスフラグの状態
        end else begin
            // Synchronous writes on clock edge / クロック同期での書き込み
            // Note: Multiple registers can be updated simultaneously if their 'write' flags are set.
            // 注: 複数の'write'フラグがセットされていれば、複数のレジスタを同時に更新可能です。
            if (a_write) reg_a <= data_in;
            if (x_write) reg_x <= data_in;
            if (y_write) reg_y <= data_in;
            if (sp_write) reg_sp <= data_in;
            if (pc_write) reg_pc <= addr_in;
            if (p_write) reg_p <= data_in;
        end
    end

endmodule
