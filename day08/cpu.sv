// Day 08: Data Movement (Zero Page Addressing) - Skeleton
//
// 学習目標:
// 1. ゼロページ・アドレッシング (Zero Page Addressing) の概念
// 2. メモリからのデータ読み出しフロー
// 3. ステートマシンの拡張

`include "include/opcodes.svh"

module cpu (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        pc_enable,
    output logic [15:0] address_bus,
    input  logic [ 7:0] data_in,
    output logic [ 7:0] debug_a,
    output logic [15:0] debug_pc
);

    logic [15:0] pc;
    logic [ 7:0] a;

    typedef enum logic [2:0] {
        S_FETCH_OPCODE,
        S_FETCH_ADDR,     // ゼロページアドレスを取得
        S_READ_MEM,       // そのアドレスからデータを読み出す
        S_EXECUTE_LDA_IMM
    } state_t;
    state_t state;

    // -------------------------------------------------------------------------
    // TODO: ゼロページ・アドレッシングの実装
    // -------------------------------------------------------------------------
    // LDA Zero Page (0xA5) 命令をサポートしてください。
    // 1. S_FETCH_OPCODE で OP_LDA_ZP を検出。
    // 2. S_FETCH_ADDR で data_in をアドレス（下位8ビット）として保持し、PCを+1。
    // 3. S_READ_MEM で address_bus にそのアドレスを出力し、data_in を A に格納。
    
    logic [7:0] zp_addr;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= 16'h8000;
            a <= 8'h00;
            state <= S_FETCH_OPCODE;
        end else if (pc_enable) begin
            case (state)
                S_FETCH_OPCODE: begin
                    case (data_in)
                        OP_LDA_IMM: begin
                            pc <= pc + 1;
                            state <= S_EXECUTE_LDA_IMM;
                        end
                        // TODO: OP_LDA_ZP (0xA5) の処理を追加
                        default: pc <= pc + 1;
                    endcase
                end
                S_EXECUTE_LDA_IMM: begin
                    a <= data_in;
                    pc <= pc + 1;
                    state <= S_FETCH_OPCODE;
                end
                // TODO: S_FETCH_ADDR, S_READ_MEM の処理を追加
            endcase
        end
    end

    // address_bus の出力をステートに応じて切り替える
    assign address_bus = (state == S_READ_MEM) ? {8'h00, zp_addr} : pc;
    assign debug_a = a;
    assign debug_pc = pc;

endmodule