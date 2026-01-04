// Day 16: Stack Operations (Stack Pointer & PHA/PLA) - Skeleton
//
// Learning Goals: / 学習目標:
// 1. Role and implementation of Stack Pointer (SP) / スタックポインタ (SP) の役割と実装
// 2. Access to stack area ($0100 - $01FF) / スタック領域 ($0100 - $01FF) へのアクセス
// 3. Push and Pull operations / プッシュ (Push) とプル (Pull) の動作

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
        S_FETCH_OPCODE,
        S_PUSH_LOW,
        S_PULL_LOW,
        S_EXECUTE
    } state_t;
    state_t state;
    logic [7:0] current_opcode;

    // -------------------------------------------------------------------------
    // TODO: Implementation of stack operation instructions
    // TODO: スタック操作命令の実装
    // -------------------------------------------------------------------------
    // Please implement PHA (0x48) and PLA (0x68).
    // PHA (0x48) および PLA (0x68) を実装してください。
    //
    // 1. The 6502 stack is fixed from address $0100 to $01FF.
    // 1. 6502 のスタックは $0100 番地から $01FF 番地に固定されています。
    // 2. PHA (Push): write A to address_bus = 0x0100 + s, and decrement s (-1).
    // 2. PHA (Push): address_bus = 0x0100 + s に a を書き込み、s をデクリメント (-1)。
    // 3. PLA (Pull): increment s (+1), and load into A from address_bus = 0x0100 + s.
    // 3. PLA (Pull): s をインクリメント (+1) し、address_bus = 0x0100 + s から a にロード。

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
            state <= S_FETCH_OPCODE;
            write_en <= 1'b0;
        end else if (pc_enable) begin
            write_en <= 1'b0;
            case (state)
                S_FETCH_OPCODE: begin
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
