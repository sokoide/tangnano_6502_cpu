// Day 11: Zero Page Addressing & RAM - Skeleton
//
// Learning Goals: / 学習目標:
// 1. Implementation of zero page addressing / ゼロページ・アドレッシングの実装
// 2. Write logic to RAM (Random Access Memory) (STA) / RAM (Random Access Memory) への書き込みロジック (STA)
// 3. Basics of memory-mapped I/O / メモリマップド I/O の基礎

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
        STATE_FETCH_OPERAND,
        STATE_EXECUTE
    } state_t;
    state_t state;
    logic [7:0] current_opcode;

    // -------------------------------------------------------------------------
    // TODO: Implementation of zero page addressing and STA instruction
    // TODO: ゼロページ・アドレッシングと STA 命令の実装
    // -------------------------------------------------------------------------
    // Please implement LDA zp (0xA5) and STA zp (0x85).
    // LDA zp (0xA5) および STA zp (0x85) を実装してください。
    //
    // 1. In STATE_FETCH_OPERAND, obtain the zero page address (lower 8 bits).
    // 1. STATE_FETCH_OPERAND で、ゼロページのアドレス（下位8ビット）を取得します。
    // 2. In STATE_EXECUTE: / 2. STATE_EXECUTE で：
    //    - For LDA: Output the obtained address to address_bus and store data_in in A.
    //    - LDA の場合：address_bus に取得したアドレスを出力し、data_in を a に格納。
    //    - For STA: Output the obtained address to address_bus, output A to data_out, and set write_en to 1.
    //    - STA の場合：address_bus に取得したアドレスを出力し、data_out に a を出力、write_en を 1 に。

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
                    state <= STATE_FETCH_OPERAND;
                end
                STATE_FETCH_OPERAND: begin
                    // TODO
                    state <= STATE_EXECUTE;
                end
                STATE_EXECUTE: begin
                    // TODO
                    pc <= pc + 1;
                    state <= STATE_FETCH_OPCODE;
                end
            endcase
        end
    end

    assign address_bus = pc;  // TODO: Switch according to state / TODO: ステートに応じて切り替え
    assign debug_pc = pc;
    assign debug_a = a;
    assign debug_x = x;
    assign debug_y = y;
    assign debug_p = {n, v, 1'b1, 1'b1, 1'b1, 1'b1, z, c};
    assign debug_s = s;

endmodule
