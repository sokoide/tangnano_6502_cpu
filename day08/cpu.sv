// Day 08: Arithmetic Operations & Status Flags (ADC/SBC) - Skeleton
//
// Learning Goals: / 学習目標:
// 1. Implementation of ADC and SBC instructions / ADC・SBC 命令の実装
// 2. Handling of Carry (C), Zero (Z), Negative (N), Overflow (V) flags / フラグ (C, Z, N, V) の更新
// 3. Status flag manipulation instructions (CLC, SEC) / フラグ操作命令 (CLC, SEC)
// 4. Inverted Borrow concept in 6502 subtraction / 6502における減算と反転ボローの概念

`include "include/opcodes.svh"

module cpu (
    input logic clk,
    input logic rst_n,  // Active-low reset
    input logic pc_enable,  // Enable signal for PC update (manual stepping or display enable)
    output logic [15:0] address_bus,
    input logic [7:0] data_in,
    output logic [15:0] debug_pc,
    output logic [7:0] debug_a,
    output logic [7:0] debug_x,
    output logic [7:0] debug_y,
    output logic [7:0] debug_p
);

    logic [15:0] pc;
    logic [ 7:0] a;  // Accumulator
    logic [7:0] x, y;  // Index registers
    logic n, v, z, c;  // Status flags

    // State Machine for Instruction Timing
    typedef enum logic [1:0] {
        STATE_FETCH_OPCODE,
        STATE_FETCH_OPERAND
    } state_t;

    state_t state;
    logic [7:0] current_opcode;

    // -------------------------------------------------------------------------
    // TODO: Implement ADC/SBC and Status Flags
    // TODO: ADC/SBC 命令とステータスフラグの実装
    // -------------------------------------------------------------------------
    // 1. In STATE_FETCH_OPCODE:
    //    - Add OP_ADC_IMM and OP_SBC_IMM to transition to STATE_FETCH_OPERAND.
    //    - Add OP_CLC (Clear Carry: c <= 0) and OP_SEC (Set Carry: c <= 1).
    //
    // 2. In STATE_FETCH_OPERAND:
    //    - Implement OP_ADC_IMM:
    //        Result = A + operand + C
    //        c <= carry out of bit 7 (sum[8])
    //        v <= signed overflow: (A[7] == operand[7]) && (A[7] != sum[7])
    //        z <= (sum[7:0] == 8'h00)
    //        n <= sum[7]
    //    - Implement OP_SBC_IMM:
    //        Result = A - operand - (1 - C)  (= A + ~operand + C)
    //        c <= !borrow (diff[8] == 0 when treated as 9-bit unsigned subtraction)
    //        v <= signed overflow: (A[7] != operand[7]) && (A[7] != diff[7])
    //        z <= (diff[7:0] == 8'h00)
    //        n <= diff[7]

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc             <= 16'h0200;
            a              <= 8'h00;
            x              <= 8'h00;
            y              <= 8'h00;
            n              <= 1'b0;
            v              <= 1'b0;
            z              <= 1'b0;
            c              <= 1'b0;
            state          <= STATE_FETCH_OPCODE;
            current_opcode <= 8'h00;
        end else if (pc_enable) begin
            case (state)
                STATE_FETCH_OPCODE: begin
                    current_opcode <= data_in;
                    case (data_in)
                        OP_LDA_IMM, OP_LDX_IMM, OP_LDY_IMM: begin
                            pc    <= pc + 1'b1;
                            state <= STATE_FETCH_OPERAND;
                        end
                        // TODO: Add OP_ADC_IMM, OP_SBC_IMM to fetch operand
                        // TODO: OP_ADC_IMM, OP_SBC_IMM のオペランドフェッチ遷移を追加

                        // Day 07 instructions (1-byte register transfers)
                        OP_TAX: begin
                            x     <= a;
                            z     <= (a == 8'h00);
                            n     <= a[7];
                            pc    <= pc + 1'b1;
                            state <= STATE_FETCH_OPCODE;
                        end
                        OP_TAY: begin
                            y     <= a;
                            z     <= (a == 8'h00);
                            n     <= a[7];
                            pc    <= pc + 1'b1;
                            state <= STATE_FETCH_OPCODE;
                        end
                        OP_TXA: begin
                            a     <= x;
                            z     <= (x == 8'h00);
                            n     <= x[7];
                            pc    <= pc + 1'b1;
                            state <= STATE_FETCH_OPCODE;
                        end
                        OP_TYA: begin
                            a     <= y;
                            z     <= (y == 8'h00);
                            n     <= y[7];
                            pc    <= pc + 1'b1;
                            state <= STATE_FETCH_OPCODE;
                        end
                        OP_INX: begin
                            x     <= x + 1'b1;
                            z     <= ((x + 8'h01) == 8'h00);
                            n     <= (x + 8'h01) >> 7;
                            pc    <= pc + 1'b1;
                            state <= STATE_FETCH_OPCODE;
                        end
                        OP_INY: begin
                            y     <= y + 1'b1;
                            z     <= ((y + 8'h01) == 8'h00);
                            n     <= (y + 8'h01) >> 7;
                            pc    <= pc + 1'b1;
                            state <= STATE_FETCH_OPCODE;
                        end

                        // TODO: Add OP_CLC, OP_SEC flag operations
                        // TODO: OP_CLC, OP_SEC フラグ操作を追加

                        default: begin
                            pc    <= pc + 1'b1;
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

                        // TODO: Implement OP_ADC_IMM calculation and flag updates
                        // TODO: OP_ADC_IMM の計算とフラグ更新を実装

                        // TODO: Implement OP_SBC_IMM calculation and flag updates
                        // TODO: OP_SBC_IMM の計算とフラグ更新を実装

                        default: ;
                    endcase
                    pc    <= pc + 1'b1;
                    state <= STATE_FETCH_OPCODE;
                end

                default: state <= STATE_FETCH_OPCODE;
            endcase
        end
    end

    assign address_bus = pc;
    assign debug_pc    = pc;
    assign debug_a     = a;
    assign debug_x     = x;
    assign debug_y     = y;
    assign debug_p     = {n, v, 1'b1, 1'b1, 1'b1, 1'b1, z, c};

endmodule
