// Day 17: Stack Operations (JSR & RTS) - Skeleton
//
// 学習目標:
// 1. サブルーチン (Subroutine) の概念
// 2. リターンアドレスの退避と復元
// 3. 複雑なステート遷移の制御

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
    logic [ 7:0] a, x, y, s;
    logic n, v, z, c;

    typedef enum logic [3:0] {
        STATE_FETCH_OPCODE,
        STATE_FETCH_LOW,
        STATE_FETCH_HIGH,
        STATE_PUSH_HIGH,
        STATE_PUSH_LOW,
        STATE_PULL_LOW,
        STATE_PULL_HIGH,
        STATE_EXECUTE
    } state_t;
    state_t state;
    logic [7:0] current_opcode;
    logic [15:0] temp_addr;

    // -------------------------------------------------------------------------
    // TODO: JSR (0x20) および RTS (0x60) 命令の実装
    // -------------------------------------------------------------------------
    // 1. JSR:
    //    - ターゲットアドレスを取得。
    //    - 現在の PC（戻り先アドレス）をスタックにプッシュ。
    //    - PC をターゲットアドレスに更新。
    // 2. RTS:
    //    - スタックからリターンアドレスをプル。
    //    - PC をそのアドレスに更新。

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= 16'h8000;
            a <= 8'h00; x <= 8'h00; y <= 8'h00; s <= 8'hFF;
            n <= 1'b0; v <= 1'b0; z <= 1'b0; c <= 1'b0;
            state <= STATE_FETCH_OPCODE;
            write_en <= 1'b0;
        end else if (pc_enable) begin
            write_en <= 1'b0;
            case (state)
                STATE_FETCH_OPCODE: begin
                    current_opcode <= data_in;
                    // ...
                    pc <= pc + 1;
                end
                // ...
            endcase
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