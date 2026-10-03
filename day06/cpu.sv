/* verilator lint_off WIDTHEXPAND */
/* verilator lint_off WIDTHTRUNC */
/* verilator lint_off CASEINCOMPLETE */
/* verilator lint_off UNUSEDSIGNAL */
`include "include/opcodes.svh"

module cpu (
    input  logic        clk,
    input  logic        rst_n,        // Active-low reset
    input  logic        pc_enable,    // Enable signal for PC update (used for manual stepping)
    output logic [15:0] address_bus,
    input  logic [ 7:0] data_in,
    output logic [15:0] debug_pc,
    output logic [ 7:0] debug_a
);

    logic [15:0] pc;
    logic [ 7:0] a;  // Accumulator

    // State Machine for Instruction Timing
    typedef enum logic [1:0] {
        STATE_FETCH_OPCODE,
        STATE_FETCH_OPERAND
    } state_t;

    state_t state;

    // -------------------------------------------------------------------------
    // TODO: Implement Immediate LDA and Two-Stage Fetch
    // TODO: 即値 LDA 命令と 2 ステート・フェッチの実装
    // -------------------------------------------------------------------------
    // 1. In STATE_FETCH_OPCODE:
    //    - If data_in is OP_LDA_IMM (0xA9):
    //        Increment PC by 1 and transition to STATE_FETCH_OPERAND.
    //    - Default / NOP:
    //        Increment PC by 1 and remain in STATE_FETCH_OPCODE.
    //
    // 2. In STATE_FETCH_OPERAND:
    //    - Load the operand (data_in) into accumulator `a`.
    //    - Increment PC by 1 and transition back to STATE_FETCH_OPCODE.

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc    <= 16'h0200;
            a     <= 8'h00;
            state <= STATE_FETCH_OPCODE;
        end else if (pc_enable) begin
            case (state)
                STATE_FETCH_OPCODE: begin
                    // TODO: Detect OP_LDA_IMM and transition to STATE_FETCH_OPERAND
                    // TODO: OP_LDA_IMM を検出して STATE_FETCH_OPERAND へ遷移
                    pc    <= pc + 1'b1;
                    state <= STATE_FETCH_OPCODE;
                end

                STATE_FETCH_OPERAND: begin
                    // TODO: Load data_in into `a`, increment PC, and return to STATE_FETCH_OPCODE
                    // TODO: data_in を a に代入し、PC を進めて STATE_FETCH_OPCODE へ戻る
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

endmodule
