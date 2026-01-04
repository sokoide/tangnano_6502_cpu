/* verilator lint_off WIDTHEXPAND */
/* verilator lint_off WIDTHTRUNC */
/* verilator lint_off CASEINCOMPLETE */
/* verilator lint_off UNUSEDSIGNAL */
// day17_completed/cpu.sv
`include "include/opcodes.svh"

module cpu (
    input  logic        clk,
    input  logic        rst_n,        // Active-low reset
    input  logic        pc_enable,    // Enable signal for PC update (used for manual stepping)
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
        STATE_EXECUTE,
        STATE_WRITE_BACK,
        STATE_FETCH_IND_LOW,
        STATE_FETCH_IND_HIGH,
        STATE_IND_ACCESS
    } state_t;

    state_t state;
    logic [7:0] current_opcode;
    logic [15:0] temp_addr;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc             <= 16'h8000;
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
            address_bus    <= 16'h8000;
        end else if (pc_enable) begin
            write_en <= 1'b0;
            case (state)
                STATE_FETCH_OPCODE: begin
                    current_opcode <= data_in;
                    if (data_in == OP_HLT) begin
                        address_bus <= pc;
                        state <= STATE_EXECUTE;
                    end else begin
                        address_bus <= pc + 1;
                        case (data_in)
                            OP_LDA_IMM, OP_LDX_IMM, OP_LDY_IMM,
                            OP_ADC_IMM, OP_SBC_IMM,
                            OP_BNE, OP_BEQ, OP_BPL, OP_BMI,
                            OP_AND_IMM, OP_ORA_IMM, OP_EOR_IMM,
                            OP_CMP_IMM, OP_CPX_IMM, OP_CPY_IMM,
                            OP_LDA_IZX, OP_LDA_IZY,
                            OP_LDA_ZP, OP_STA_ZP, OP_LDX_ZP, OP_STX_ZP, OP_LDY_ZP, OP_STY_ZP, OP_BIT_ZP,
                            OP_INC_ZP, OP_DEC_ZP: begin
                                pc    <= pc + 1;
                                address_bus <= pc + 1;
                                state <= STATE_FETCH_OPERAND;
                            end
                            OP_JSR, OP_JMP_ABS, OP_JMP_IND, OP_LDA_ABS, OP_STA_ABS,
                                                                                    OP_LDA_ABX, OP_LDA_ABY, OP_STA_ABX: begin
                                pc    <= pc + 1;
                                address_bus <= pc + 1;
                                state <= STATE_FETCH_LOW;
                            end
                            OP_RTS: begin
                                state <= STATE_PULL_LOW;
                                address_bus <= 16'h0100 + (s + 8'd1);
                            end
                            OP_PHA, OP_PHP: begin
                                state <= STATE_PUSH_LOW;
                                write_en <= 1'b1;
                                address_bus <= 16'h0100 + s;
                                data_out <= (data_in == OP_PHA) ? a : {n, v, 1'b1, 1'b1, 1'b1, 1'b1, z, c};
                            end
                            OP_PLA, OP_PLP: begin
                                state <= STATE_PULL_LOW;
                                address_bus <= 16'h0100 + (s + 8'd1);
                            end
                            // Day 07 instructions (1-byte instructions)
                            OP_TAX: begin
                                x <= a;
                                z <= (a == 8'h00);
                                n <= a[7];
                                pc <= pc + 1;
                                address_bus <= pc + 1;
                                state <= STATE_FETCH_OPCODE;
                            end
                            OP_TAY: begin
                                y <= a;
                                z <= (a == 8'h00);
                                n <= a[7];
                                pc <= pc + 1;
                                address_bus <= pc + 1;
                                state <= STATE_FETCH_OPCODE;
                            end
                            OP_TXA: begin
                                a <= x;
                                z <= (x == 8'h00);
                                n <= x[7];
                                pc <= pc + 1;
                                address_bus <= pc + 1;
                                state <= STATE_FETCH_OPCODE;
                            end
                            OP_TYA: begin
                                a <= y;
                                z <= (y == 8'h00);
                                n <= y[7];
                                pc <= pc + 1;
                                address_bus <= pc + 1;
                                state <= STATE_FETCH_OPCODE;
                            end
                            OP_INX: begin
                                x <= x + 1;
                                z <= ((x + 8'h01) == 8'h00);
                                n <= (x + 8'h01) >> 7;
                                pc <= pc + 1;
                                address_bus <= pc + 1;
                                state <= STATE_FETCH_OPCODE;
                            end
                            OP_INY: begin
                                y <= y + 1;
                                z <= ((y + 8'h01) == 8'h00);
                                n <= (y + 8'h01) >> 7;
                                pc <= pc + 1;
                                address_bus <= pc + 1;
                                state <= STATE_FETCH_OPCODE;
                            end
                            OP_DEX: begin
                                x <= x - 1;
                                z <= ((x - 8'h01) == 8'h00);
                                n <= (x - 8'h01) >> 7;
                                pc <= pc + 1;
                                address_bus <= pc + 1;
                                state <= STATE_FETCH_OPCODE;
                            end
                            OP_DEY: begin
                                y <= y - 1;
                                z <= ((y - 8'h01) == 8'h00);
                                n <= (y - 8'h01) >> 7;
                                pc <= pc + 1;
                                address_bus <= pc + 1;
                                state <= STATE_FETCH_OPCODE;
                            end
                            OP_CLC: begin
                                c <= 1'b0;
                                pc <= pc + 1;
                                address_bus <= pc + 1;
                                state <= STATE_FETCH_OPCODE;
                            end
                            OP_SEC: begin
                                c <= 1'b1;
                                pc <= pc + 1;
                                address_bus <= pc + 1;
                                state <= STATE_FETCH_OPCODE;
                            end
                            OP_ASL_A: begin
                                c <= a[7];
                                a <= {a[6:0], 1'b0};
                                z <= ({a[6:0], 1'b0} == 8'h00);
                                n <= a[6];
                                pc <= pc + 1;
                                address_bus <= pc + 1;
                                state <= STATE_FETCH_OPCODE;
                            end
                            OP_LSR_A: begin
                                c <= a[0];
                                a <= {1'b0, a[7:1]};
                                z <= ({1'b0, a[7:1]} == 8'h00);
                                n <= 1'b0;
                                pc <= pc + 1;
                                address_bus <= pc + 1;
                                state <= STATE_FETCH_OPCODE;
                            end
                            OP_ROL_A: begin
                                automatic logic old_c;
                                old_c = c;
                                c <= a[7];
                                a <= {a[6:0], old_c};
                                z <= ({a[6:0], old_c} == 8'h00);
                                n <= a[6];
                                pc <= pc + 1;
                                address_bus <= pc + 1;
                                state <= STATE_FETCH_OPCODE;
                            end
                            OP_ROR_A: begin
                                automatic logic old_c;
                                old_c = c;
                                c <= a[0];
                                a <= {old_c, a[7:1]};
                                z <= ({old_c, a[7:1]} == 8'h00);
                                n <= old_c;
                                pc <= pc + 1;
                                address_bus <= pc + 1;
                                state <= STATE_FETCH_OPCODE;
                            end
                            default: begin
                                pc <= pc + 1;
                                address_bus <= pc + 1;
                                state <= STATE_FETCH_OPCODE;
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
                        OP_LDX_IMM: begin
                            x <= data_in;
                            z <= (data_in == 8'h00);
                            n <= data_in[7];
                        end
                        OP_LDY_IMM: begin
                            y <= data_in;
                            z <= (data_in == 8'h00);
                            n <= data_in[7];
                        end
                        OP_ADC_IMM: begin
                            logic [8:0] sum;
                            sum = {1'b0, a} + {1'b0, data_in} + {8'd0, c};
                            a <= sum[7:0];
                            c <= sum[8];
                            z <= (sum[7:0] == 8'h00);
                            n <= sum[7];
                            v <= (a[7] == data_in[7]) && (a[7] != sum[7]);
                        end
                        OP_AND_IMM: begin
                            logic [7:0] res;
                            res = a & data_in;
                            a <= res;
                            z <= (res == 8'h00);
                            n <= res[7];
                        end
                        OP_ORA_IMM: begin
                            logic [7:0] res;
                            res = a | data_in;
                            a <= res;
                            z <= (res == 8'h00);
                            n <= res[7];
                        end
                        OP_EOR_IMM: begin
                            logic [7:0] res;
                            res = a ^ data_in;
                            a <= res;
                            z <= (res == 8'h00);
                            n <= res[7];
                        end
                        OP_SBC_IMM: begin
                            logic [8:0] diff;
                            diff = {1'b0, a} - {1'b0, data_in} - (c ? 9'h0 : 9'h1);
                            a <= diff[7:0];
                            c <= !diff[8];
                            z <= (diff[7:0] == 8'h00);
                            n <= diff[7];
                            v <= (a[7] != data_in[7]) && (a[7] != diff[7]);
                        end
                        OP_CMP_IMM: begin
                            logic [8:0] diff;
                            diff = {1'b0, a} - {1'b0, data_in};
                            c <= !diff[8];
                            z <= (diff[7:0] == 8'h00);
                            n <= diff[7];
                        end
                        OP_CPX_IMM: begin
                            logic [8:0] diff;
                            diff = {1'b0, x} - {1'b0, data_in};
                            c <= !diff[8];
                            z <= (diff[7:0] == 8'h00);
                            n <= diff[7];
                        end
                        OP_CPY_IMM: begin
                            logic [8:0] diff;
                            diff = {1'b0, y} - {1'b0, data_in};
                            c <= !diff[8];
                            z <= (diff[7:0] == 8'h00);
                            n <= diff[7];
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
                                pc <= (pc + 16'd1) + 16'($signed(data_in));
                                address_bus <= (pc + 16'd1) + 16'($signed(data_in));
                            end else begin
                                pc <= pc + 1;
                                address_bus <= pc + 1;
                            end
                        end
                        OP_LDA_ZP, OP_LDX_ZP, OP_LDY_ZP, OP_BIT_ZP, OP_INC_ZP, OP_DEC_ZP: begin
                            address_bus <= {8'h00, data_in};
                        end
                        OP_LDA_IZX: begin
                            address_bus <= {8'h00, data_in + x};
                        end
                        OP_LDA_IZY: begin
                            address_bus <= {8'h00, data_in};
                        end
                        OP_STA_ZP, OP_STX_ZP, OP_STY_ZP: begin
                            address_bus <= {8'h00, data_in};
                            write_en <= 1'b1;
                            if (current_opcode == OP_STA_ZP) data_out <= a;
                            else if (current_opcode == OP_STX_ZP) data_out <= x;
                            else data_out <= y;
                        end
                        default: ;
                    endcase

                    case (current_opcode)
                        OP_LDA_IMM, OP_LDX_IMM, OP_LDY_IMM,
                        OP_ADC_IMM, OP_SBC_IMM, OP_AND_IMM, OP_ORA_IMM, OP_EOR_IMM,
                        OP_CMP_IMM, OP_CPX_IMM, OP_CPY_IMM, OP_BNE, OP_BEQ, OP_BPL, OP_BMI: begin
                            if (current_opcode != OP_BNE && current_opcode != OP_BEQ &&
                                current_opcode != OP_BPL && current_opcode != OP_BMI) begin
                                pc <= pc + 1;
                                address_bus <= pc + 1;
                            end
                            state <= STATE_FETCH_OPCODE;
                        end
                        OP_LDA_ZP, OP_LDX_ZP, OP_LDY_ZP, OP_BIT_ZP, OP_STA_ZP, OP_STX_ZP, OP_STY_ZP,
                        OP_INC_ZP, OP_DEC_ZP: begin
                            state <= STATE_EXECUTE;
                        end
                        OP_LDA_IZX, OP_LDA_IZY: begin
                            state <= STATE_FETCH_IND_LOW;
                        end
                        default: begin
                            pc <= pc + 1;
                            address_bus <= pc + 1;
                            state <= STATE_FETCH_OPCODE;
                        end
                    endcase
                end

                STATE_FETCH_LOW: begin
                    temp_addr[7:0] <= data_in;
                    pc <= pc + 1;
                    address_bus <= pc + 1;
                    state <= STATE_FETCH_HIGH;
                end

                STATE_FETCH_HIGH: begin
                    temp_addr[15:8] <= data_in;
                    if (current_opcode == OP_JSR) begin
                        state <= STATE_PUSH_HIGH;
                        write_en <= 1'b1;
                        address_bus <= 16'h0100 + s;
                        data_out <= pc[15:8];  // Push High byte (PCH)
                    end else if (current_opcode == OP_JMP_ABS) begin
                        pc <= {data_in, temp_addr[7:0]};
                        address_bus <= {data_in, temp_addr[7:0]};
                        state <= STATE_FETCH_OPCODE;
                    end else if (current_opcode == OP_JMP_IND) begin
                        address_bus <= {data_in, temp_addr[7:0]};
                        state <= STATE_FETCH_IND_LOW;
                    end else if (current_opcode == OP_LDA_ABS || current_opcode == OP_LDA_ABX || current_opcode == OP_LDA_ABY) begin
                        address_bus <= {data_in, temp_addr[7:0]} + 
                                       ((current_opcode == OP_LDA_ABX) ? {8'h00, x} :
                                        (current_opcode == OP_LDA_ABY) ? {8'h00, y} : 16'h0000);
                        state <= STATE_EXECUTE;
                    end else if (current_opcode == OP_STA_ABS || current_opcode == OP_STA_ABX) begin
                        address_bus <= {data_in, temp_addr[7:0]} + 
                                       ((current_opcode == OP_STA_ABX) ? {8'h00, x} : 16'h0000);
                        write_en <= 1'b1;
                        data_out <= a;
                        state <= STATE_EXECUTE;
                    end else if (current_opcode == OP_LDA_ABS || current_opcode == OP_LDA_ABX || current_opcode == OP_LDA_ABY) begin
                        address_bus <= {data_in, temp_addr[7:0]} + 
                                       ((current_opcode == OP_LDA_ABX) ? {8'h00, x} :
                                        (current_opcode == OP_LDA_ABY) ? {8'h00, y} : 16'h0000);
                        state <= STATE_EXECUTE;
                    end else if (current_opcode == OP_STA_ABS || current_opcode == OP_STA_ABX) begin
                        address_bus <= {data_in, temp_addr[7:0]} + 
                                       ((current_opcode == OP_STA_ABX) ? {8'h00, x} : 16'h0000);
                        write_en <= 1'b1;
                        data_out <= a;
                        state <= STATE_EXECUTE;
                    end
                end

                STATE_PUSH_HIGH: begin
                    s <= s - 1;
                    state <= STATE_PUSH_LOW;
                    write_en <= 1'b1;
                    address_bus <= 16'h0100 + (s - 8'd1);
                    data_out <= pc[7:0];  // Push Low byte (PCL)
                end

                STATE_PUSH_LOW: begin
                    s <= s - 1;
                    if (current_opcode == OP_JSR) begin
                        pc <= temp_addr;
                        address_bus <= temp_addr;
                    end else begin
                        pc <= pc + 1;
                        address_bus <= pc + 1;
                    end
                    state <= STATE_FETCH_OPCODE;
                end

                STATE_PULL_LOW: begin
                    s <= s + 1;
                    temp_addr[7:0] <= data_in;
                    if (current_opcode == OP_RTS) begin
                        state <= STATE_PULL_HIGH;
                        address_bus <= 16'h0100 + (s + 8'd2);
                    end else if (current_opcode == OP_PLA) begin
                        a <= data_in;
                        z <= (data_in == 8'h00);
                        n <= data_in[7];
                        pc <= pc + 1;
                        address_bus <= pc + 1;
                        state <= STATE_FETCH_OPCODE;
                    end else if (current_opcode == OP_PLP) begin
                        {n, v, temp_addr[5:2], z, c} <= data_in;  // Reuse temp_addr bits
                        pc <= pc + 1;
                        address_bus <= pc + 1;
                        state <= STATE_FETCH_OPCODE;
                    end
                end

                STATE_PULL_HIGH: begin
                    s <= s + 1;
                    pc <= {data_in, temp_addr[7:0]} + 16'd1;
                    address_bus <= {data_in, temp_addr[7:0]} + 16'd1;
                    state <= STATE_FETCH_OPCODE;
                end

                STATE_EXECUTE: begin
                    case (current_opcode)
                        OP_LDA_ZP, OP_LDA_ABS, OP_LDA_ABX, OP_LDA_ABY, OP_LDA_IZX, OP_LDA_IZY: begin
                            a <= data_in;
                            z <= (data_in == 8'h00);
                            n <= data_in[7];
                        end
                        OP_LDX_ZP: begin
                            x <= data_in;
                            z <= (data_in == 8'h00);
                            n <= data_in[7];
                        end
                        OP_LDY_ZP: begin
                            y <= data_in;
                            z <= (data_in == 8'h00);
                            n <= data_in[7];
                        end
                        OP_BIT_ZP: begin
                            z <= ((a & data_in) == 8'h00);
                            n <= data_in[7];
                            v <= data_in[6];
                        end
                        OP_INC_ZP: begin
                            data_out <= data_in + 8'h01;
                            z <= ((data_in + 8'h01) == 8'h00);
                            n <= (data_in + 8'h01) >> 7;
                            write_en <= 1'b1;
                            state <= STATE_WRITE_BACK;
                        end
                        OP_DEC_ZP: begin
                            data_out <= data_in - 8'h01;
                            z <= ((data_in - 8'h01) == 8'h00);
                            n <= (data_in - 8'h01) >> 7;
                            write_en <= 1'b1;
                            state <= STATE_WRITE_BACK;
                        end
                        OP_STA_ZP, OP_STX_ZP, OP_STY_ZP, OP_STA_ABS, OP_STA_ABX: begin
                            write_en <= 1'b0;
                        end
                    endcase
                    // Stay here for HLT
                    if (current_opcode == OP_HLT) begin
                        address_bus <= pc;
                        state <= STATE_EXECUTE;
                    end else if (current_opcode != OP_INC_ZP && current_opcode != OP_DEC_ZP) begin
                        pc <= pc + 1;
                        address_bus <= pc + 1;
                        state <= STATE_FETCH_OPCODE;
                    end
                end

                STATE_WRITE_BACK: begin
                    write_en <= 1'b0;
                    pc <= pc + 1;
                    address_bus <= pc + 1;
                    state <= STATE_FETCH_OPCODE;
                end

                STATE_FETCH_IND_LOW: begin
                    temp_addr[7:0] <= data_in;
                    if (current_opcode == OP_JMP_IND) begin
                        address_bus <= address_bus + 1;
                    end else begin
                        // 6502 ZP wrapping behavior
                        address_bus <= {8'h00, address_bus[7:0] + 8'h01};
                    end
                    state <= STATE_FETCH_IND_HIGH;
                end

                STATE_FETCH_IND_HIGH: begin
                    temp_addr[15:8] <= data_in;
                    if (current_opcode == OP_JMP_IND) begin
                        state <= STATE_IND_ACCESS;
                    end else begin
                        state <= STATE_IND_ACCESS;
                    end
                end

                STATE_IND_ACCESS: begin
                    if (current_opcode == OP_JMP_IND) begin
                        pc <= temp_addr;
                        address_bus <= temp_addr;
                        state <= STATE_FETCH_OPCODE;
                    end else begin
                        case (current_opcode)
                            OP_LDA_IZX: address_bus <= temp_addr;
                            OP_LDA_IZY: address_bus <= temp_addr + {8'h00, y};
                            default: address_bus <= temp_addr;
                        endcase
                        state <= STATE_EXECUTE;
                    end
                end

                default: state <= STATE_FETCH_OPCODE;
            endcase
        end
    end

    assign debug_pc = pc;
    assign debug_a  = a;
    assign debug_x  = x;
    assign debug_y  = y;
    assign debug_p  = {n, v, 1'b1, 1'b1, 1'b1, 1'b1, z, c};
    assign debug_s  = s;

endmodule
