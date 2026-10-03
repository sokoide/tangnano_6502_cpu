// Day 09: Branch Instructions & Control Flow (BNE, BEQ, BPL, BMI) - Skeleton
//
// Learning Goals: / 学習目標:
// 1. Implementation of Relative Addressing / 相対アドレッシング (Relative Addressing) の実装
// 2. Handling of signed 8-bit offset ($signed) / 符号付き 8 ビットオフセットの扱い ($signed)
// 3. Conditional branch logic using status flags / フラグによる条件分岐ロジック (Z, N)

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
    // TODO: Implement Branch Instructions (BNE, BEQ, BPL, BMI)
    // TODO: 分岐命令 (BNE, BEQ, BPL, BMI) の実装
    // -------------------------------------------------------------------------
    // 1. In STATE_FETCH_OPCODE:
    //    - Add OP_BNE, OP_BEQ, OP_BPL, OP_BMI to transition to STATE_FETCH_OPERAND.
    //
    // 2. In STATE_FETCH_OPERAND:
    //    - Evaluate branch condition based on flags:
    //        BNE: !z (Zero flag is 0)
    //        BEQ:  z (Zero flag is 1)
    //        BPL: !n (Negative flag is 0 / Positive)
    //        BMI:  n (Negative flag is 1 / Negative)
    //    - If condition holds (taken):
    //        pc <= (pc + 1'b1) + 16'($signed(data_in));
    //    - If condition does NOT hold (not taken / fall-through):
    //        pc <= pc + 1'b1;

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
                        OP_LDA_IMM, OP_LDX_IMM, OP_LDY_IMM, OP_ADC_IMM, OP_SBC_IMM: begin
                            pc    <= pc + 1'b1;
                            state <= STATE_FETCH_OPERAND;
                        end

                        // TODO: Add OP_BNE, OP_BEQ, OP_BPL, OP_BMI to fetch operand
                        // TODO: OP_BNE, OP_BEQ, OP_BPL, OP_BMI のオペランドフェッチ遷移を追加

                        // Register transfers
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

                        // Flag operations
                        OP_CLC: begin
                            c     <= 1'b0;
                            pc    <= pc + 1'b1;
                            state <= STATE_FETCH_OPCODE;
                        end
                        OP_SEC: begin
                            c     <= 1'b1;
                            pc    <= pc + 1'b1;
                            state <= STATE_FETCH_OPCODE;
                        end

                        default: begin
                            pc    <= pc + 1'b1;
                            state <= STATE_FETCH_OPCODE;
                        end
                    endcase
                end

                STATE_FETCH_OPERAND: begin
                    case (current_opcode)
                        OP_LDA_IMM: begin
                            a  <= data_in;
                            z  <= (data_in == 8'h00);
                            n  <= data_in[7];
                            pc <= pc + 1'b1;
                        end
                        OP_ADC_IMM: begin
                            begin
                                logic [8:0] sum;
                                sum = {1'b0, a} + {1'b0, data_in} + {8'd0, c};
                                a <= sum[7:0];
                                c <= sum[8];
                                z <= (sum[7:0] == 8'h00);
                                n <= sum[7];
                                v <= (a[7] == data_in[7]) && (a[7] != sum[7]);
                            end
                            pc <= pc + 1'b1;
                        end
                        OP_SBC_IMM: begin
                            begin
                                logic [8:0] diff;
                                diff = {1'b0, a} - {1'b0, data_in} - (c ? 9'h0 : 9'h1);
                                a <= diff[7:0];
                                c <= !diff[8];
                                z <= (diff[7:0] == 8'h00);
                                n <= diff[7];
                                v <= (a[7] != data_in[7]) && (a[7] != diff[7]);
                            end
                            pc <= pc + 1'b1;
                        end

                        // TODO: Implement Branch instructions (OP_BNE, OP_BEQ, OP_BPL, OP_BMI)
                        // TODO: 分岐命令 (OP_BNE, OP_BEQ, OP_BPL, OP_BMI) の判定とPC更新を実装

                        default: pc <= pc + 1'b1;
                    endcase
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
