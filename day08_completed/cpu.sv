`include "include/opcodes.svh"

module cpu (
    input  logic        clk,
    input  logic        rst_n,      // Active-low reset
    input  logic        pc_enable,  // Enable signal for PC update (used for manual stepping)
    output logic [15:0] address_bus,
    input  logic [7:0]  data_in,
    output logic [15:0] debug_pc,
    output logic [7:0]  debug_a,
    output logic [7:0]  debug_x,
    output logic [7:0]  debug_y,
    output logic [7:0]  debug_p
);

    logic [15:0] pc;
    logic [7:0]  a;  // Accumulator
    logic [7:0]  x, y; // Index registers
    logic        n, v, z, c; // Status flags

    // State Machine for Instruction Timing
    typedef enum logic [1:0] {
        STATE_FETCH_OPCODE,
        STATE_FETCH_OPERAND
    } state_t;

    state_t state;
    logic [7:0] current_opcode;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc    <= 16'h8000;
            a     <= 8'h00;
            x     <= 8'h00;
            y     <= 8'h00;
            n     <= 1'b0;
            v     <= 1'b0;
            z     <= 1'b0;
            c     <= 1'b0;
            state <= STATE_FETCH_OPCODE;
            current_opcode <= 8'h00;
        end else if (pc_enable) begin
            case (state)
                STATE_FETCH_OPCODE: begin
                    current_opcode <= data_in;
                    case (data_in)
                        OP_LDA_IMM, OP_ADC_IMM, OP_SBC_IMM: begin
                            pc    <= pc + 1;
                            state <= STATE_FETCH_OPERAND;
                        end
                        // Day 07 instructions (1-byte instructions)
                        OP_TAX: begin x <= a; z <= (a == 8'h00); n <= a[7]; pc <= pc + 1; state <= STATE_FETCH_OPCODE; end
                        OP_TAY: begin y <= a; z <= (a == 8'h00); n <= a[7]; pc <= pc + 1; state <= STATE_FETCH_OPCODE; end
                        OP_TXA: begin a <= x; z <= (x == 8'h00); n <= x[7]; pc <= pc + 1; state <= STATE_FETCH_OPCODE; end
                        OP_TYA: begin a <= y; z <= (y == 8'h00); n <= y[7]; pc <= pc + 1; state <= STATE_FETCH_OPCODE; end
                        OP_INX: begin x <= x + 1; z <= ((x + 8'h01) == 8'h00); n <= (x + 8'h01) >> 7; pc <= pc + 1; state <= STATE_FETCH_OPCODE; end
                        OP_INY: begin y <= y + 1; z <= ((y + 8'h01) == 8'h00); n <= (y + 8'h01) >> 7; pc <= pc + 1; state <= STATE_FETCH_OPCODE; end
                        // Day 08 instructions (1-byte instructions)
                        OP_CLC: begin c <= 1'b0; pc <= pc + 1; state <= STATE_FETCH_OPCODE; end
                        OP_SEC: begin c <= 1'b1; pc <= pc + 1; state <= STATE_FETCH_OPCODE; end
                        default: begin pc <= pc + 1; state <= STATE_FETCH_OPCODE; end
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
                            // A + operand + C
                            // Using a 9-bit sum to easily get Carry and Overflow
                            begin
                                logic [8:0] sum;
                                sum = {1'b0, a} + {1'b0, data_in} + {8'd0, c};
                                a <= sum[7:0];
                                c <= sum[8];
                                z <= (sum[7:0] == 8'h00);
                                n <= sum[7];
                                v <= (a[7] == data_in[7]) && (a[7] != sum[7]);
                            end
                        end
                        OP_SBC_IMM: begin
                            // SBC is A - operand - (1 - C)
                            // In 6502, C=1 means no borrow, C=0 means borrow.
                            begin
                                logic [8:0] diff;
                                diff = {1'b0, a} - {1'b0, data_in} - (c ? 9'h0 : 9'h1);
                                a <= diff[7:0];
                                // Carry flag is inverted borrow
                                c <= !diff[8];
                                z <= (diff[7:0] == 8'h00);
                                n <= diff[7];
                                // Overflow: (A pos, M neg, Res neg) or (A neg, M pos, Res pos)
                                v <= (a[7] != data_in[7]) && (a[7] != diff[7]);
                            end
                        end
                        default: ;
                    endcase
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
    assign debug_p     = {n, v, 1'b1, 1'b1, 1'b1, 1'b1, z, c};

endmodule
