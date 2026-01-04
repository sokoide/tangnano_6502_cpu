// Day 07: Data Movement (Register Transfers) - Skeleton
//
// Learning Goals: / 学習目標:
// 1. Inter-register transfer instructions (TAX, TAY, TXA, TYA) / レジスタ間転送命令 (TAX, TAY, TXA, TYA)
// 2. Implementation of index registers (X, Y) / インデックスレジスタ (X, Y) の実装
// 3. Increment instructions (INX, INY) / インクリメント命令 (INX, INY)

`include "include/opcodes.svh"

module cpu (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        pc_enable,
    output logic [15:0] address_bus,
    input  logic [ 7:0] data_in,
    output logic [ 7:0] debug_a,
    output logic [ 7:0] debug_x,
    output logic [ 7:0] debug_y,
    output logic [15:0] debug_pc
);

    logic [15:0] pc;
    logic [7:0] a, x, y;

    typedef enum logic [1:0] {
        STATE_FETCH_OPCODE,
        STATE_FETCH_OPERAND
    } state_t;
    state_t state;

    // -------------------------------------------------------------------------
    // TODO: Implementation of inter-register transfer instructions and index registers
    // TODO: レジスタ間転送命令とインデックスレジスタの実装
    // -------------------------------------------------------------------------
    // Add the following instructions inside the case statement:
    // 以下の命令を case 文の中に追加してください：
    // - TAX (0xAA): Copy the value of A to X / a の値を x にコピー
    // - TAY (0xA8): Copy the value of A to Y / a の値を y にコピー
    // - TXA (0x8A): Copy the value of X to A / x の値を a にコピー
    // - TYA (0x98): Copy the value of Y to A / y の値を a にコピー
    // - INX (0xE8): X = X + 1 / x を +1
    // - INY (0xC8): Y = Y + 1 / y を +1
    //
    // Since these are all 1-byte instructions, increment PC by 1 after execution,
    // and the state remains (or returns to) STATE_FETCH_OPCODE.
    // すべて 1 バイト命令なので、実行後に pc を +1 し、
    // state は STATE_FETCH_OPCODE のまま（または戻る）になります。

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= 16'h0200;
            a <= 8'h00;
            x <= 8'h00;
            y <= 8'h00;
            state <= STATE_FETCH_OPCODE;
        end else if (pc_enable) begin
            case (state)
                STATE_FETCH_OPCODE: begin
                    case (data_in)
                        OP_LDA_IMM: begin
                            pc    <= pc + 1;
                            state <= STATE_FETCH_OPERAND;
                        end
                        // TODO: Add TAX, TAY, TXA, TYA, INX, INY here
                        // TODO: ここに TAX, TAY, TXA, TYA, INX, INY を追加

                        default: begin
                            pc <= pc + 1;
                            state <= STATE_FETCH_OPCODE;
                        end
                    endcase
                end
                STATE_FETCH_OPERAND: begin
                    a <= data_in;
                    pc <= pc + 1;
                    state <= STATE_FETCH_OPCODE;
                end
            endcase
        end
    end

    assign address_bus = pc;
    assign debug_a = a;
    assign debug_x = x;
    assign debug_y = y;
    assign debug_pc = pc;

endmodule
