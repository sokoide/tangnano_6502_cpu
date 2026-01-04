// Day 13: Control Flow & Basic Memory (JMP Instruction) - Skeleton
//
// Learning Goals: / 学習目標:
// 1. Implementation of JMP instruction / JMP 命令の実装
// 2. Discontinuous update of Program Counter (PC) / プログラムカウンタ (PC) の不連続な更新
// 3. Creation of infinite loops / 無限ループの作成

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
        STATE_FETCH_LOW,
        STATE_FETCH_HIGH,
        STATE_EXECUTE
    } state_t;
    state_t state;
    logic [7:0] current_opcode;
    logic [15:0] target_addr;

    // -------------------------------------------------------------------------
    // TODO: Implementation of JMP instruction
    // TODO: JMP 命令の実装
    // -------------------------------------------------------------------------
    // Please implement JMP abs (0x4C).
    // JMP abs (0x4C) を実装してください。
    //
    // 1. Obtain the jump destination address in STATE_FETCH_LOW / HIGH.
    // 1. STATE_FETCH_LOW / HIGH で飛び先アドレスを取得。
    // 2. Update PC to that address in STATE_EXECUTE.
    // 2. STATE_EXECUTE で pc をそのアドレスに更新。
    // * JMP does not increment PC, but replaces it completely.
    // ※ JMP は PC をインクリメントするのではなく、完全に置き換えます。

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
                    target_addr[7:0] <= data_in;
                    pc <= pc + 1;
                    state <= STATE_FETCH_HIGH;
                end
                STATE_FETCH_HIGH: begin
                    target_addr[15:8] <= data_in;
                    // For JMP, PC can be updated here
                    // JMP の場合はここで PC を更新しても良い
                    state <= STATE_EXECUTE;
                end
                STATE_EXECUTE: begin
                    // TODO: JMP logic
                    // TODO: JMP ロジック
                    state <= STATE_FETCH_OPCODE;
                end
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
