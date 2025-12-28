// Day 07: Data Movement (Register Transfers) - Skeleton
//
// 学習目標:
// 1. レジスタ間転送命令 (TAX, TAY, TXA, TYA)
// 2. インデックスレジスタ (X, Y) の実装
// 3. インクリメント命令 (INX, INY)

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
    logic [ 7:0] a, x, y;

    typedef enum logic [1:0] {
        STATE_FETCH_OPCODE,
        STATE_FETCH_OPERAND
    } state_t;
    state_t state;

    // -------------------------------------------------------------------------
    // TODO: レジスタ間転送命令とインデックスレジスタの実装
    // -------------------------------------------------------------------------
    // 以下の命令を case 文の中に追加してください：
    // - TAX (0xAA): a の値を x にコピー
    // - TAY (0xA8): a の値を y にコピー
    // - TXA (0x8A): x の値を a にコピー
    // - TYA (0x98): y の値を a にコピー
    // - INX (0xE8): x を +1
    // - INY (0xC8): y を +1
    //
    // すべて 1 バイト命令なので、実行後に pc を +1 し、
    // state は STATE_FETCH_OPCODE のまま（または戻る）になります。

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= 16'h8000;
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