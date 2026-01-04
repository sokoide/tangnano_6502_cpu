// 6502 CPU Register Set - Skeleton
// Implement the internal register set of the 6502 processor.
// 6502プロセッサの内部レジスタセットを実装します。

module cpu_registers (
    input logic clk,
    input logic rst_n,

    // Register write enables / 書き込み有効化信号
    input logic a_write,
    input logic x_write,
    input logic y_write,
    input logic sp_write,
    input logic pc_write,
    input logic p_write,

    // Data inputs / データ入力
    input logic [ 7:0] data_in,
    input logic [15:0] addr_in,

    // Register outputs / レジスタ出力
    output logic [ 7:0] reg_a,
    output logic [ 7:0] reg_x,
    output logic [ 7:0] reg_y,
    output logic [ 7:0] reg_sp,
    output logic [15:0] reg_pc,
    output logic [ 7:0] reg_p
);

    // -------------------------------------------------------------------------
    // TODO: Implement the 6502 internal registers using sequential logic (always_ff).
    // TODO: 6502の内部レジスタを順序回路 (always_ff) で実装してください。
    // -------------------------------------------------------------------------
    // 1. Operation during reset (rst_n == 0): / リセット時の動作 (rst_n == 0):
    //    Initialize each register. / 各レジスタを初期化します。
    //    A, X, Y = 8'h00
    //    SP (Stack Pointer) = 8'hFF (top of stack) / SP (Stack Pointer) = 8'hFF (スタックの最上位)
    //    PC (Program Counter) = 16'h0200 (program start address) / PC (Program Counter) = 16'h0200 (プログラム開始アドレス)
    //    P (Processor Status) = 8'h34 (Break=0, Unused=1, IRQ=1)
    //
    // 2. Normal operation (at rising edge of clk): / 通常時の動作 (clk 立ち上がり時):
    //    Store the corresponding input signal (data_in or addr_in) in the register 
    //    when each write enable signal (a_write, x_write, y_write, sp_write, pc_write, p_write) is '1'.
    //    各書き込み有効信号 (a_write, x_write, y_write, sp_write, pc_write, p_write) 
    //    が '1' のときに、対応する入力信号 (data_in または addr_in) をレジスタに格納します。
    //    Configure it so that multiple registers can be updated simultaneously.
    //    複数のレジスタを同時に更新できる構成にしてください。

endmodule
