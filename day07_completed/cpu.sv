`include "include/opcodes.svh"

module cpu (
    input  logic        clk,
    input  logic        rst_n,        // Active-low reset
    input  logic        pc_enable,    // Enable signal for PC update (used for manual stepping)
    output logic [15:0] address_bus,
    input  logic [ 7:0] data_in,
    input  logic [15:0] debug_pc,
    output logic [ 7:0] debug_a,
    output logic [ 7:0] debug_x,
    output logic [ 7:0] debug_y
);

    logic [15:0] pc;
    logic [ 7:0] a;  // Accumulator
    logic [7:0] x, y;  // Index registers

    // State Machine for Instruction Timing
    typedef enum logic [1:0] {
        STATE_FETCH_OPCODE,
        STATE_FETCH_OPERAND
    } state_t;

    state_t state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc    <= 16'h8000;
            a     <= 8'h00;
            x     <= 8'h00;
            y     <= 8'h00;
            state <= STATE_FETCH_OPCODE;
        end else if (pc_enable) begin
            case (state)
                STATE_FETCH_OPCODE: begin
                    case (data_in)
                        OP_LDA_IMM: begin
                            pc    <= pc + 1;
                            state <= STATE_FETCH_OPERAND;
                        end
                        // Day 07 instructions (1-byte instructions)
                        OP_TAX: begin
                            x     <= a;
                            pc    <= pc + 1;
                            state <= STATE_FETCH_OPCODE;
                        end
                        OP_TAY: begin
                            y     <= a;
                            pc    <= pc + 1;
                            state <= STATE_FETCH_OPCODE;
                        end
                        OP_TXA: begin
                            a     <= x;
                            pc    <= pc + 1;
                            state <= STATE_FETCH_OPCODE;
                        end
                        OP_TYA: begin
                            a     <= y;
                            pc    <= pc + 1;
                            state <= STATE_FETCH_OPCODE;
                        end
                        OP_INX: begin
                            x     <= x + 1;
                            pc    <= pc + 1;
                            state <= STATE_FETCH_OPCODE;
                        end
                        OP_INY: begin
                            y     <= y + 1;
                            pc    <= pc + 1;
                            state <= STATE_FETCH_OPCODE;
                        end
                        default: begin
                            // Default behavior for 1-byte instructions (e.g. NOP)
                            pc    <= pc + 1;
                            state <= STATE_FETCH_OPCODE;
                        end
                    endcase
                end

                STATE_FETCH_OPERAND: begin
                    // Load the immediate value into Accumulator
                    a     <= data_in;
                    pc    <= pc + 1;
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

endmodule
