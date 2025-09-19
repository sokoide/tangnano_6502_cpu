// Complete 6502 CPU Decoder
// Generates all control signals for CPU operation

module cpu_decoder (
    input  logic [7:0] opcode,
    input  logic [7:0] status_reg,

    // ALU control
    output logic [3:0] alu_op,
    output logic       alu_carry_in,

    // Register control
    output logic reg_a_write,
    output logic reg_x_write,
    output logic reg_y_write,
    output logic reg_sp_write,
    output logic reg_pc_write,

    // Memory control
    output logic mem_read,
    output logic mem_write,

    // Flag control
    output logic update_nz,
    output logic update_c,
    output logic update_v,

    // Data path control
    output logic [2:0] reg_src_sel,    // Register input source select
    output logic [1:0] alu_a_sel,     // ALU A input select
    output logic [1:0] alu_b_sel,     // ALU B input select

    // Addressing mode
    output logic [2:0] addr_mode,
    output logic [1:0] instruction_length,

    // Special control
    output logic is_branch,
    output logic is_jump,
    output logic stack_push,
    output logic stack_pop
);

    // ALU operation definitions
    localparam ALU_ADD = 4'b0000;
    localparam ALU_SUB = 4'b0001;
    localparam ALU_AND = 4'b0010;
    localparam ALU_OR  = 4'b0011;
    localparam ALU_XOR = 4'b0100;
    localparam ALU_ASL = 4'b0101;
    localparam ALU_LSR = 4'b0110;
    localparam ALU_ROL = 4'b0111;
    localparam ALU_ROR = 4'b1000;
    localparam ALU_INC = 4'b1001;
    localparam ALU_DEC = 4'b1010;
    localparam ALU_PASS_A = 4'b1011;
    localparam ALU_PASS_B = 4'b1100;

    // Register source select
    localparam REG_SRC_ALU = 3'b000;
    localparam REG_SRC_MEM = 3'b001;
    localparam REG_SRC_REG = 3'b010;

    // ALU input select
    localparam ALU_A_REG_A = 2'b00;
    localparam ALU_A_REG_X = 2'b01;
    localparam ALU_A_REG_Y = 2'b10;
    localparam ALU_A_ZERO  = 2'b11;

    localparam ALU_B_MEM   = 2'b00;
    localparam ALU_B_REG_A = 2'b01;
    localparam ALU_B_REG_X = 2'b10;
    localparam ALU_B_REG_Y = 2'b11;

    always_comb begin
        // Default values
        alu_op = ALU_PASS_A;
        alu_carry_in = 1'b0;

        {reg_a_write, reg_x_write, reg_y_write} = 3'b000;
        {reg_sp_write, reg_pc_write} = 2'b00;

        {mem_read, mem_write} = 2'b00;
        {update_nz, update_c, update_v} = 3'b000;

        reg_src_sel = REG_SRC_ALU;
        alu_a_sel = ALU_A_REG_A;
        alu_b_sel = ALU_B_MEM;

        addr_mode = 3'b000;
        instruction_length = 2'd1;

        {is_branch, is_jump, stack_push, stack_pop} = 4'b0000;

        case (opcode)
            // LDA Immediate
            8'hA9: begin
                reg_a_write = 1'b1;
                mem_read = 1'b1;
                update_nz = 1'b1;
                alu_op = ALU_PASS_B;
                alu_b_sel = ALU_B_MEM;
                reg_src_sel = REG_SRC_ALU;
                addr_mode = 3'b000;    // Immediate
                instruction_length = 2'd2;
            end

            // LDA Zero Page
            8'hA5: begin
                reg_a_write = 1'b1;
                mem_read = 1'b1;
                update_nz = 1'b1;
                alu_op = ALU_PASS_B;
                alu_b_sel = ALU_B_MEM;
                reg_src_sel = REG_SRC_ALU;
                addr_mode = 3'b001;    // Zero page
                instruction_length = 2'd2;
            end

            // LDA Absolute
            8'hAD: begin
                reg_a_write = 1'b1;
                mem_read = 1'b1;
                update_nz = 1'b1;
                alu_op = ALU_PASS_B;
                alu_b_sel = ALU_B_MEM;
                reg_src_sel = REG_SRC_ALU;
                addr_mode = 3'b011;    // Absolute
                instruction_length = 2'd3;
            end

            // LDX Immediate
            8'hA2: begin
                reg_x_write = 1'b1;
                mem_read = 1'b1;
                update_nz = 1'b1;
                alu_op = ALU_PASS_B;
                alu_b_sel = ALU_B_MEM;
                reg_src_sel = REG_SRC_ALU;
                addr_mode = 3'b000;
                instruction_length = 2'd2;
            end

            // LDY Immediate
            8'hA0: begin
                reg_y_write = 1'b1;
                mem_read = 1'b1;
                update_nz = 1'b1;
                alu_op = ALU_PASS_B;
                alu_b_sel = ALU_B_MEM;
                reg_src_sel = REG_SRC_ALU;
                addr_mode = 3'b000;
                instruction_length = 2'd2;
            end

            // STA Zero Page
            8'h85: begin
                mem_write = 1'b1;
                alu_op = ALU_PASS_A;
                alu_a_sel = ALU_A_REG_A;
                addr_mode = 3'b001;
                instruction_length = 2'd2;
            end

            // STA Absolute
            8'h8D: begin
                mem_write = 1'b1;
                alu_op = ALU_PASS_A;
                alu_a_sel = ALU_A_REG_A;
                addr_mode = 3'b011;
                instruction_length = 2'd3;
            end

            // ADC Immediate
            8'h69: begin
                reg_a_write = 1'b1;
                mem_read = 1'b1;
                update_nz = 1'b1;
                update_c = 1'b1;
                update_v = 1'b1;
                alu_op = ALU_ADD;
                alu_carry_in = status_reg[0];  // C flag
                alu_a_sel = ALU_A_REG_A;
                alu_b_sel = ALU_B_MEM;
                reg_src_sel = REG_SRC_ALU;
                addr_mode = 3'b000;
                instruction_length = 2'd2;
            end

            // SBC Immediate
            8'hE9: begin
                reg_a_write = 1'b1;
                mem_read = 1'b1;
                update_nz = 1'b1;
                update_c = 1'b1;
                update_v = 1'b1;
                alu_op = ALU_SUB;
                alu_carry_in = status_reg[0];  // C flag (inverted for SBC)
                alu_a_sel = ALU_A_REG_A;
                alu_b_sel = ALU_B_MEM;
                reg_src_sel = REG_SRC_ALU;
                addr_mode = 3'b000;
                instruction_length = 2'd2;
            end

            // AND Immediate
            8'h29: begin
                reg_a_write = 1'b1;
                mem_read = 1'b1;
                update_nz = 1'b1;
                alu_op = ALU_AND;
                alu_a_sel = ALU_A_REG_A;
                alu_b_sel = ALU_B_MEM;
                reg_src_sel = REG_SRC_ALU;
                addr_mode = 3'b000;
                instruction_length = 2'd2;
            end

            // ORA Immediate
            8'h09: begin
                reg_a_write = 1'b1;
                mem_read = 1'b1;
                update_nz = 1'b1;
                alu_op = ALU_OR;
                alu_a_sel = ALU_A_REG_A;
                alu_b_sel = ALU_B_MEM;
                reg_src_sel = REG_SRC_ALU;
                addr_mode = 3'b000;
                instruction_length = 2'd2;
            end

            // EOR Immediate
            8'h49: begin
                reg_a_write = 1'b1;
                mem_read = 1'b1;
                update_nz = 1'b1;
                alu_op = ALU_XOR;
                alu_a_sel = ALU_A_REG_A;
                alu_b_sel = ALU_B_MEM;
                reg_src_sel = REG_SRC_ALU;
                addr_mode = 3'b000;
                instruction_length = 2'd2;
            end

            // TAX
            8'hAA: begin
                reg_x_write = 1'b1;
                update_nz = 1'b1;
                alu_op = ALU_PASS_A;
                alu_a_sel = ALU_A_REG_A;
                reg_src_sel = REG_SRC_ALU;
                instruction_length = 2'd1;
            end

            // TAY
            8'hA8: begin
                reg_y_write = 1'b1;
                update_nz = 1'b1;
                alu_op = ALU_PASS_A;
                alu_a_sel = ALU_A_REG_A;
                reg_src_sel = REG_SRC_ALU;
                instruction_length = 2'd1;
            end

            // TXA
            8'h8A: begin
                reg_a_write = 1'b1;
                update_nz = 1'b1;
                alu_op = ALU_PASS_A;
                alu_a_sel = ALU_A_REG_X;
                reg_src_sel = REG_SRC_ALU;
                instruction_length = 2'd1;
            end

            // TYA
            8'h98: begin
                reg_a_write = 1'b1;
                update_nz = 1'b1;
                alu_op = ALU_PASS_A;
                alu_a_sel = ALU_A_REG_Y;
                reg_src_sel = REG_SRC_ALU;
                instruction_length = 2'd1;
            end

            // ASL Accumulator
            8'h0A: begin
                reg_a_write = 1'b1;
                update_nz = 1'b1;
                update_c = 1'b1;
                alu_op = ALU_ASL;
                alu_a_sel = ALU_A_REG_A;
                reg_src_sel = REG_SRC_ALU;
                instruction_length = 2'd1;
            end

            // LSR Accumulator
            8'h4A: begin
                reg_a_write = 1'b1;
                update_nz = 1'b1;
                update_c = 1'b1;
                alu_op = ALU_LSR;
                alu_a_sel = ALU_A_REG_A;
                reg_src_sel = REG_SRC_ALU;
                instruction_length = 2'd1;
            end

            // CMP Immediate
            8'hC9: begin
                mem_read = 1'b1;
                update_nz = 1'b1;
                update_c = 1'b1;
                alu_op = ALU_SUB;
                alu_a_sel = ALU_A_REG_A;
                alu_b_sel = ALU_B_MEM;
                addr_mode = 3'b000;
                instruction_length = 2'd2;
            end

            // Branch instructions
            8'h10, 8'h30, 8'h50, 8'h70, 8'h90, 8'hB0, 8'hD0, 8'hF0: begin
                is_branch = 1'b1;
                mem_read = 1'b1;  // Read branch offset
                addr_mode = 3'b000;  // Relative addressing
                instruction_length = 2'd2;
            end

            // JMP Absolute
            8'h4C: begin
                is_jump = 1'b1;
                reg_pc_write = 1'b1;
                mem_read = 1'b1;
                addr_mode = 3'b011;
                instruction_length = 2'd3;
            end

            // JSR
            8'h20: begin
                is_jump = 1'b1;
                reg_pc_write = 1'b1;
                stack_push = 1'b1;
                mem_read = 1'b1;
                mem_write = 1'b1;
                addr_mode = 3'b011;
                instruction_length = 2'd3;
            end

            // RTS
            8'h60: begin
                is_jump = 1'b1;
                reg_pc_write = 1'b1;
                stack_pop = 1'b1;
                mem_read = 1'b1;
                instruction_length = 2'd1;
            end

            // PHA
            8'h48: begin
                stack_push = 1'b1;
                mem_write = 1'b1;
                alu_op = ALU_PASS_A;
                alu_a_sel = ALU_A_REG_A;
                instruction_length = 2'd1;
            end

            // PLA
            8'h68: begin
                reg_a_write = 1'b1;
                stack_pop = 1'b1;
                mem_read = 1'b1;
                update_nz = 1'b1;
                alu_op = ALU_PASS_B;
                alu_b_sel = ALU_B_MEM;
                reg_src_sel = REG_SRC_ALU;
                instruction_length = 2'd1;
            end

            // SEC
            8'h38: begin
                update_c = 1'b1;
                instruction_length = 2'd1;
            end

            // CLC
            8'h18: begin
                update_c = 1'b1;
                instruction_length = 2'd1;
            end

            // NOP
            8'hEA: begin
                instruction_length = 2'd1;
            end

            default: begin
                // Unknown instruction - treat as NOP
                instruction_length = 2'd1;
            end
        endcase
    end

endmodule