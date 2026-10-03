// Day 10: Stack Operations & Subroutines (PHA/PLA/JSR/RTS) - Skeleton
//
// Learning Goals: / 学習目標:
// 1. Role and implementation of Stack Pointer (SP / S register) / スタックポインタ (S) の役割と実装
// 2. Access to stack area ($0100 - $01FF) in RAM / RAM上のスタック領域 ($0100 - $01FF) へのアクセス
// 3. Push and Pull operations (PHA, PLA) / プッシュ (PHA) とプル (PLA) の動作
// 4. Synchronous RAM interface with memory_ready settle / 同期RAM対応と memory_ready による1サイクルのセトル

`include "include/opcodes.svh"

module cpu (
    input logic clk,
    input logic rst_n,  // Active-low reset
    input logic pc_enable,  // Enable signal for PC update (manual stepping or display enable)
    output logic [15:0] address_bus,
    input logic [7:0] data_in,
    output logic [7:0] data_out,
    output logic write_en,
    output logic [15:0] debug_pc,
    output logic [7:0] debug_a,
    output logic [7:0] debug_x,
    output logic [7:0] debug_y,
    output logic [7:0] debug_p,
    output logic [7:0] debug_s
);

    logic [15:0] pc;
    logic [ 7:0] a;  // Accumulator
    logic [7:0] x, y;  // Index registers
    logic [7:0] s;  // Stack pointer
    logic n, v, z, c;  // Status flags

    // State Machine for Instruction Timing
    typedef enum logic [3:0] {
        STATE_FETCH_OPCODE,
        STATE_FETCH_OPERAND,
        STATE_FETCH_LOW,
        STATE_FETCH_HIGH,
        STATE_PUSH_HIGH,
        STATE_PUSH_LOW,
        STATE_PULL_LOW,
        STATE_PULL_HIGH,
        STATE_EXECUTE
    } state_t;

    state_t state;
    logic [7:0] current_opcode;
    logic [15:0] temp_addr;

    // Settle progresses at the memory clock, independently of manual stepping.
    logic memory_ready, step_pending;

    // -------------------------------------------------------------------------
    // TODO: Implement Stack Operations (PHA, PLA) and Bus Interface
    // TODO: スタック操作 (PHA, PLA) とバスインターフェースの実装
    // -------------------------------------------------------------------------
    // 1. In STATE_FETCH_OPCODE:
    //    - OP_PHA:
    //        state <= STATE_PUSH_LOW;
    //        write_en <= 1'b1;
    //        address_bus <= 16'h0100 + s;
    //        data_out <= a;
    //    - OP_PLA:
    //        state <= STATE_PULL_LOW;
    //        address_bus <= 16'h0100 + (s + 1'b1);
    //    - OP_HLT:
    //        state <= STATE_EXECUTE;
    //
    // 2. In STATE_PUSH_LOW:
    //    - Decrement stack pointer: s <= s - 1'b1;
    //    - Advance PC and return to STATE_FETCH_OPCODE.
    //
    // 3. In STATE_PULL_LOW:
    //    - Increment stack pointer: s <= s + 1'b1;
    //    - Load data_in into target register (for PLA: a <= data_in, update Z and N);
    //    - Advance PC and return to STATE_FETCH_OPCODE.

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            memory_ready   <= 1'b0;
            step_pending   <= 1'b0;
            pc             <= 16'h0200;
            a              <= 8'h00;
            x              <= 8'h00;
            y              <= 8'h00;
            s              <= 8'hFF;
            n              <= 1'b0;
            v              <= 1'b0;
            z              <= 1'b0;
            c              <= 1'b0;
            state          <= STATE_FETCH_OPCODE;
            current_opcode <= 8'h00;
            write_en       <= 1'b0;
            data_out       <= 8'h00;
            address_bus    <= 16'h0200;
        end else begin
            write_en <= 1'b0;  // One accepted memory edge per issued write.
            if (!memory_ready) begin
                memory_ready <= 1'b1;
                step_pending <= step_pending | pc_enable;
            end else if (pc_enable || step_pending) begin
                memory_ready <= 1'b0;
                step_pending <= 1'b0;
                write_en     <= 1'b0;
                case (state)
                    STATE_FETCH_OPCODE: begin
                        current_opcode <= data_in;
                        if (data_in == OP_HLT) begin
                            address_bus <= pc;
                            state       <= STATE_EXECUTE;
                        end else begin
                            address_bus <= pc + 1'b1;
                            case (data_in)
                                OP_LDA_IMM, OP_LDX_IMM, OP_LDY_IMM, OP_ADC_IMM, OP_SBC_IMM,
                                OP_BNE, OP_BEQ, OP_BPL, OP_BMI: begin
                                    pc    <= pc + 1'b1;
                                    state <= STATE_FETCH_OPERAND;
                                end

                                // TODO: Add OP_PHA and OP_PLA decode and setup
                                // TODO: OP_PHA, OP_PLA のデコードと遷移を追加

                                // Register transfers
                                OP_TAX: begin
                                    x           <= a;
                                    z           <= (a == 8'h00);
                                    n           <= a[7];
                                    pc          <= pc + 1'b1;
                                    address_bus <= pc + 1'b1;
                                    state       <= STATE_FETCH_OPCODE;
                                end
                                OP_TAY: begin
                                    y           <= a;
                                    z           <= (a == 8'h00);
                                    n           <= a[7];
                                    pc          <= pc + 1'b1;
                                    address_bus <= pc + 1'b1;
                                    state       <= STATE_FETCH_OPCODE;
                                end
                                OP_TXA: begin
                                    a           <= x;
                                    z           <= (x == 8'h00);
                                    n           <= x[7];
                                    pc          <= pc + 1'b1;
                                    address_bus <= pc + 1'b1;
                                    state       <= STATE_FETCH_OPCODE;
                                end
                                OP_TYA: begin
                                    a           <= y;
                                    z           <= (y == 8'h00);
                                    n           <= y[7];
                                    pc          <= pc + 1'b1;
                                    address_bus <= pc + 1'b1;
                                    state       <= STATE_FETCH_OPCODE;
                                end
                                OP_INX: begin
                                    x           <= x + 1'b1;
                                    z           <= ((x + 8'h01) == 8'h00);
                                    n           <= (x + 8'h01) >> 7;
                                    pc          <= pc + 1'b1;
                                    address_bus <= pc + 1'b1;
                                    state       <= STATE_FETCH_OPCODE;
                                end
                                OP_INY: begin
                                    y           <= y + 1'b1;
                                    z           <= ((y + 8'h01) == 8'h00);
                                    n           <= (y + 8'h01) >> 7;
                                    pc          <= pc + 1'b1;
                                    address_bus <= pc + 1'b1;
                                    state       <= STATE_FETCH_OPCODE;
                                end

                                // Flag operations
                                OP_CLC: begin
                                    c           <= 1'b0;
                                    pc          <= pc + 1'b1;
                                    address_bus <= pc + 1'b1;
                                    state       <= STATE_FETCH_OPCODE;
                                end
                                OP_SEC: begin
                                    c           <= 1'b1;
                                    pc          <= pc + 1'b1;
                                    address_bus <= pc + 1'b1;
                                    state       <= STATE_FETCH_OPCODE;
                                end

                                default: begin
                                    pc          <= pc + 1'b1;
                                    address_bus <= pc + 1'b1;
                                    state       <= STATE_FETCH_OPCODE;
                                end
                            endcase
                        end
                    end

                    STATE_FETCH_OPERAND: begin
                        case (current_opcode)
                            OP_LDA_IMM: begin
                                a <= data_in;
                                z <= (data_in == 8'h00);
                                n <= data_in[7];
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
                            end
                            OP_BNE, OP_BEQ, OP_BPL, OP_BMI: begin
                                automatic logic take_branch;
                                case (current_opcode)
                                    OP_BNE:  take_branch = !z;
                                    OP_BEQ:  take_branch = z;
                                    OP_BPL:  take_branch = !n;
                                    OP_BMI:  take_branch = n;
                                    default: take_branch = 1'b0;
                                endcase
                                if (take_branch) begin
                                    pc <= (pc + 1'b1) + 16'($signed(data_in));
                                end else begin
                                    pc <= pc + 1'b1;
                                end
                            end
                            default: pc <= pc + 1'b1;
                        endcase
                        if (current_opcode != OP_BNE && current_opcode != OP_BEQ &&
                            current_opcode != OP_BPL && current_opcode != OP_BMI) begin
                            pc <= pc + 1'b1;
                        end
                        state <= STATE_FETCH_OPCODE;
                        address_bus <= (current_opcode == OP_BNE || current_opcode == OP_BEQ ||
                                        current_opcode == OP_BPL || current_opcode == OP_BMI) ?
                                       (((!z && current_opcode == OP_BNE) || (z && current_opcode == OP_BEQ) ||
                                         (!n && current_opcode == OP_BPL) || (n && current_opcode == OP_BMI)) ?
                                        ((pc + 1'b1) + 16'($signed(
                            data_in
                        ))) : (pc + 1'b1)) : (pc + 1'b1);
                    end

                    // TODO: Implement STATE_PUSH_LOW and STATE_PULL_LOW for PHA/PLA
                    // TODO: PHA/PLA のための STATE_PUSH_LOW と STATE_PULL_LOW を実装

                    STATE_EXECUTE: begin
                        // Stay here for HLT
                        state <= STATE_EXECUTE;
                    end

                    default: state <= STATE_FETCH_OPCODE;
                endcase
            end
        end
    end

    assign debug_pc = pc;
    assign debug_a  = a;
    assign debug_x  = x;
    assign debug_y  = y;
    assign debug_p  = {n, v, 1'b1, 1'b1, 1'b1, 1'b1, z, c};
    assign debug_s  = s;

endmodule
