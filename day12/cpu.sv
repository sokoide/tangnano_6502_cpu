// Day 12: Control Flow & Basic Memory (Absolute Addressing) - Skeleton
//
// 学習目標:
// 1. アブソリュート・アドレッシング (Absolute Addressing) の実装
// 2. 3 バイト命令のフェッチフロー
// 3. リトルエンディアン (Little Endian) の扱い

`include "include/opcodes.svh"

module cpu (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        pc_enable,
    output logic [15:0] address_bus,
    input  logic [ 7:0] data_in,
    output logic [ 7:0] data_out,
    output logic        write_en,
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

    typedef enum logic [2:0] {
        STATE_FETCH_OPCODE,
        STATE_FETCH_LOW,  // アドレス下位 8 ビットを取得
        STATE_FETCH_HIGH,  // アドレス上位 8 ビットを取得
        STATE_EXECUTE
    } state_t;
    state_t state;
    logic [7:0] current_opcode;
    logic [15:0] target_addr;

    // -------------------------------------------------------------------------
    // TODO: アブソリュート・アドレッシングの実装
    // -------------------------------------------------------------------------
    // LDA abs (0xAD) および STA abs (0x8D) を実装してください。
    //
    // 1. STATE_FETCH_LOW でアドレスの下位 8 ビットを target_addr[7:0] に格納。
    // 2. STATE_FETCH_HIGH でアドレスの上位 8 ビットを target_addr[15:8] に格納。
    // 3. STATE_EXECUTE でメモリへのアクセス（読み書き）を実行。

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
            state <= STATE_FETCH_OPCODE;
            write_en <= 1'b0;
        end else if (pc_enable) begin
            write_en <= 1'b0;
            case (state)
                STATE_FETCH_OPCODE: begin
                    current_opcode <= data_in;
                    pc <= pc + 1;
                    state <= STATE_FETCH_LOW;
                end
                STATE_FETCH_LOW: begin
                    // TODO: 下位バイト取得
                    pc <= pc + 1;
                    state <= STATE_FETCH_HIGH;
                end
                STATE_FETCH_HIGH: begin
                    // TODO: 上位バイト取得
                    pc <= pc + 1;
                    state <= STATE_EXECUTE;
                end
                STATE_EXECUTE: begin
                    // TODO: アクセス実行
                    state <= STATE_FETCH_OPCODE;
                end
            endcase
        end
    end

    assign address_bus = pc;  // TODO: 切り替え
    assign debug_pc = pc;
    assign debug_a = a;
    assign debug_x = x;
    assign debug_y = y;
    assign debug_p = {n, v, 1'b1, 1'b1, 1'b1, 1'b1, z, c};
    assign debug_s = s;

endmodule
