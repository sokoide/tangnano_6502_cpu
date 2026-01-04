// Day 08: Data Movement (Zero Page Addressing) - Skeleton
//
// Learning Goals: / 学習目標:
// 1. Concept of Zero Page Addressing / ゼロページ・アドレッシング (Zero Page Addressing) の概念
// 2. Data read flow from memory / メモリからのデータ読み出しフロー
// 3. Expansion of state machine / ステートマシンの拡張

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
        S_FETCH_ADDR,      // Fetch zero page address / ゼロページアドレスを取得
        S_READ_MEM,        // Read data from that address / そのアドレスからデータを読み出す
        S_EXECUTE_LDA_IMM
    } state_t;
    state_t state;

    // -------------------------------------------------------------------------
    // TODO: Implementation of zero page addressing
    // TODO: ゼロページ・アドレッシングの実装
    // -------------------------------------------------------------------------
    // Please support the LDA Zero Page (0xA5) instruction.
    // LDA Zero Page (0xA5) 命令をサポートしてください。
    // 1. Detect OP_LDA_ZP in S_FETCH_OPCODE.
    // 1. S_FETCH_OPCODE で OP_LDA_ZP を検出。
    // 2. In S_FETCH_ADDR, hold data_in as the address (lower 8 bits) and increment PC by 1.
    // 2. S_FETCH_ADDR で data_in をアドレス（下位8ビット）として保持し、PCを+1。
    // 3. In S_READ_MEM, output that address to address_bus and store data_in in A.
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
                        // TODO: Add processing for OP_LDA_ZP (0xA5)
                        // TODO: OP_LDA_ZP (0xA5) の処理を追加
                        default: pc <= pc + 1;
                    endcase
                end
                S_EXECUTE_LDA_IMM: begin
                    a <= data_in;
                    pc <= pc + 1;
                    state <= S_FETCH_OPCODE;
                end
                // TODO: Add processing for S_FETCH_ADDR, S_READ_MEM
                // TODO: S_FETCH_ADDR, S_READ_MEM の処理を追加
            endcase
        end
    end

    // Switch the output of address_bus depending on the state
    // address_bus の出力をステートに応じて切り替える
    assign address_bus = (state == S_READ_MEM) ? {8'h00, zp_addr} : pc;
    assign debug_a = a;
    assign debug_pc = pc;

endmodule
