// Day 09: Arithmetic & Flags (ADC & Flags) - Skeleton
//
// Learning Goals: / 学習目標:
// 1. Implementation of ADC instruction / ADC 命令の実装
// 2. Carry flag (C) and Zero flag (Z) / キャリーフラグ (C) とゼロフラグ (Z)
// 3. Negative flag (N) and Overflow flag (V) / ネガティブフラグ (N) とオーバーフローフラグ (V)

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
    // TODO: Implementation of ADC instruction and flag updates
    // TODO: ADC 命令とフラグ更新の実装
    // -------------------------------------------------------------------------
    // Please implement ADC Immediate (0x69).
    // ADC Immediate (0x69) を実装してください。
    // Formula: A + operand + C / 計算式: A + operand + C
    // 
    // Also, update the following flags appropriately:
    // また、以下のフラグを適切に更新してください：
    // - Z: 1 when the result is 0 / 結果が 0 の時に 1
    // - N: 1 when bit 7 of the result is 1 / 結果のビット 7 が 1 の時に 1
    // - C: 1 when an unsigned overflow occurs / 符号なし演算で桁溢れした時に 1
    // - V: 1 when a signed overflow occurs / 符号付き演算でオーバーフローした時に 1

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= 16'h0200;
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
                        OP_LDA_IMM, OP_ADC_IMM: begin
                            pc <= pc + 1;
                            state <= STATE_FETCH_OPERAND;
                        end
                        // Day 08's CLC, SEC can also be added if necessary
                        // Day 08 の CLC, SEC も必要に応じて追加
                        default: begin
                            pc <= pc + 1;
                            state <= STATE_FETCH_OPCODE;
                        end
                    endcase
                end
                STATE_FETCH_OPERAND: begin
                    case (current_opcode)
                        OP_LDA_IMM: begin
                            a <= data_in;
                            z <= (data_in == 8'h00);
                            n <= data_in[7];
                        end
                        OP_ADC_IMM: begin
                            // TODO: ADC logic
                            // TODO: ADC ロジック
                        end
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
