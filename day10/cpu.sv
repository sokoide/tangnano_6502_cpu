// Day 10: Arithmetic & Flags (SBC & Inverted Borrow) - Skeleton
//
// Learning Goals: / 学習目標:
// 1. Implementation of SBC instruction / SBC 命令の実装
// 2. Concept of "Inverted Borrow" in 6502 / 6502 の「Inverted Borrow (反転したボロー)」の概念
// 3. Handling of the carry flag during subtraction / 減算時のキャリーフラグの扱い

`include "include/opcodes.svh"

module cpu (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        pc_enable,
    output logic [15:0] address_bus,
    input  logic [ 7:0] data_in,
    output logic [15:0] debug_pc,
    output logic [ 7:0] debug_a,
    output logic [ 7:0] debug_x,
    output logic [ 7:0] debug_y,
    output logic [ 7:0] debug_p
);

    logic [15:0] pc;
    logic [7:0] a, x, y;
    logic n, v, z, c;

    typedef enum logic [1:0] {
        STATE_FETCH_OPCODE,
        STATE_FETCH_OPERAND
    } state_t;
    state_t state;
    logic [7:0] current_opcode;

    // -------------------------------------------------------------------------
    // TODO: Implementation of SBC instruction
    // TODO: SBC 命令の実装
    // -------------------------------------------------------------------------
    // Please implement SBC Immediate (0xE9).
    // SBC Immediate (0xE9) を実装してください。
    // SBC in 6502 is A - operand - (1 - C).
    // 6502のSBCは A - operand - (1 - C) です。
    // Hint: It can be calculated as A + (~operand) + C.
    // ヒント: A + (~operand) + C として計算できます。

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= 16'h8000;
            a <= 8'h00;
            x <= 8'h00;
            y <= 8'h00;
            n <= 1'b0;
            v <= 1'b0;
            z <= 1'b0;
            c <= 1'b0;
            state <= STATE_FETCH_OPCODE;
        end else if (pc_enable) begin
            case (state)
                STATE_FETCH_OPCODE: begin
                    current_opcode <= data_in;
                    case (data_in)
                        OP_LDA_IMM, OP_ADC_IMM, OP_SBC_IMM: begin
                            pc <= pc + 1;
                            state <= STATE_FETCH_OPERAND;
                        end
                        OP_SEC: begin
                            c  <= 1'b1;
                            pc <= pc + 1;
                        end
                        OP_CLC: begin
                            c  <= 1'b0;
                            pc <= pc + 1;
                        end
                        default: pc <= pc + 1;
                    endcase
                end
                STATE_FETCH_OPERAND: begin
                    case (current_opcode)
                        OP_SBC_IMM: begin
                            // TODO: SBC logic
                            // TODO: SBC ロジック
                        end
                        // ... Other instructions / ... 他の命令
                    endcase
                    pc <= pc + 1;
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

endmodule
