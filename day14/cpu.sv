// Day 14: Control Flow & Basic Memory (Branch Instructions) - Skeleton
//
// Learning Goals: / 学習目標:
// 1. Implementation of Relative Addressing / 相対アドレッシング (Relative Addressing) の実装
// 2. Handling of signed 8-bit offset ($signed) / 符号付き 8 ビットオフセットの扱い ($signed)
// 3. Conditional branch logic using flags / フラグによる条件分岐ロジック

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

    typedef enum logic [1:0] {
        STATE_FETCH_OPCODE,
        STATE_FETCH_OPERAND,
        STATE_EXECUTE
    } state_t;
    state_t state;
    logic [7:0] current_opcode;

    // -------------------------------------------------------------------------
    // TODO: Implementation of branch instructions
    // TODO: 分岐命令の実装
    // -------------------------------------------------------------------------
    // Please implement BNE (0xD0). (Branch if the Zero flag is 0)
    // BNE (0xD0) を実装してください。 (Zero フラグが 0 の時に分岐)
    //
    // 1. In STATE_FETCH_OPERAND, obtain the 8-bit relative offset.
    // 1. STATE_FETCH_OPERAND で 8 ビットの相対オフセットを取得。
    // 2. If the condition is met: pc <= (pc + 1) + offset
    // 2. 条件が成立する場合： pc <= (pc + 1) + offset
    // 3. If the condition is not met: pc <= pc + 1
    // 3. 条件が成立しない場合： pc <= pc + 1
    // * The offset must be treated as signed ($signed(data_in)).
    // ※ オフセットは符号付きとして扱う必要があります ($signed(data_in))。

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
                    // TODO: Branch logic / TODO: 分岐ロジック
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
