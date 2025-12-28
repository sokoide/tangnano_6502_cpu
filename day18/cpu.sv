// Day 18: Stack Operations & Refinement (System Integration) - Skeleton
//
// 学習目標:
// 1. 全命令の統合と検証
// 2. 実機での複雑なプログラムの実行
// 3. 次のステップ（割り込み、周辺機器）への準備

`include "include/opcodes.svh"

module cpu (
    input  logic        clk,
    input  logic        rst_n,        // Active-low reset
    input  logic        pc_enable,    // Enable signal for PC update (used for manual stepping)
    output logic [15:0] address_bus,
    input  logic [ 7:0] data_in,
    output logic [ 7:0] data_out,
    output logic        write_en,
    input  logic        vsync,
    output logic        vram_clear,
    output logic        show_info,
    output logic [15:0] debug_pc,
    output logic [ 7:0] debug_a,
    output logic [ 7:0] debug_x,
    output logic [ 7:0] debug_y,
    output logic [ 7:0] debug_p,
    output logic [ 7:0] debug_s
);

    logic [15:0] pc;
    logic [7:0] a, x, y, s;
    logic n, v, z, c;

    // -------------------------------------------------------------------------
    // TODO: 6502 CPU の最終統合
    // -------------------------------------------------------------------------
    // これまでに学んだすべての命令と機能を統合し、システム全体を完成させてください。
    // Day 18 では、独自命令 (WVS, CVR, IFO) のサポートも含まれます。

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= 16'h8000;
            a <= 8'h00;
            x <= 8'h00;
            y <= 8'h00;
            s <= 8'hFF;
            n <= 1'b0;
            v <= 1'b0;
            z <= 1'b0;
            c <= 1'b0;
            write_en <= 1'b0;
            vram_clear <= 1'b0;
            show_info <= 1'b0;
        end else if (pc_enable) begin
            // ここにステートマシンと命令実行ロジックを統合
        end
    end

    assign address_bus = pc;
    assign debug_pc = pc;
    assign debug_a = a;
    assign debug_x = x;
    assign debug_y = y;
    assign debug_p = {n, v, 1'b1, 1'b1, 1'b1, 1'b1, z, c};
    assign debug_s = s;

endmodule
