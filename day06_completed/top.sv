// Day 06 Completed: CPU Decoder and ALU
// Test module for complete 6502 decoder and ALU implementation

module top (
    input  wire clk,
    input  wire rst_n,
    input  wire [3:0] switches,           // Control switches

    // Debug outputs for ALU
    output wire [7:0] debug_alu_result,   // ALU result
    output wire debug_alu_carry,          // ALU carry output
    output wire debug_alu_zero,           // ALU zero flag
    output wire debug_alu_negative,       // ALU negative flag
    output wire debug_alu_overflow,       // ALU overflow flag

    // Debug outputs for decoder
    output wire [3:0] debug_alu_op,       // ALU operation
    output wire debug_reg_a_write,        // A register write enable
    output wire debug_mem_read,           // Memory read enable
    output wire debug_mem_write,          // Memory write enable

    // Status register output
    output wire [7:0] debug_status_reg,   // Processor status

    // Instruction info
    output wire [7:0] debug_opcode,       // Current opcode
    output wire [1:0] debug_inst_length   // Instruction length
);

    // Test sequence control
    logic [26:0] test_counter;
    logic [4:0] test_instruction_index;

    // Test data
    logic [7:0] test_opcode;
    logic [7:0] test_operand;
    logic [7:0] test_reg_a, test_reg_x, test_reg_y;
    logic [7:0] test_status_reg;

    // Decoder outputs
    logic [3:0] alu_op;
    logic alu_carry_in;
    logic reg_a_write, reg_x_write, reg_y_write;
    logic mem_read, mem_write;
    logic update_nz, update_c, update_v;
    logic [2:0] reg_src_sel;
    logic [1:0] alu_a_sel, alu_b_sel;
    logic [1:0] instruction_length;

    // ALU signals
    logic [7:0] alu_operand_a, alu_operand_b;
    logic [7:0] alu_result;
    logic alu_carry_out, alu_overflow, alu_negative, alu_zero;

    // Status register signals
    logic [7:0] status_reg;

    // Test instruction set
    logic [7:0] test_opcodes [0:31];
    logic [7:0] test_operands [0:31];

    // Initialize test data
    initial begin
        // Load instructions
        test_opcodes[0]  = 8'hA9; test_operands[0]  = 8'h55; // LDA #$55
        test_opcodes[1]  = 8'hA2; test_operands[1]  = 8'hAA; // LDX #$AA
        test_opcodes[2]  = 8'hA0; test_operands[2]  = 8'h33; // LDY #$33

        // Store instructions
        test_opcodes[3]  = 8'h85; test_operands[3]  = 8'h80; // STA $80
        test_opcodes[4]  = 8'h8D; test_operands[4]  = 8'h00; // STA $1200

        // Arithmetic instructions
        test_opcodes[5]  = 8'h69; test_operands[5]  = 8'h10; // ADC #$10
        test_opcodes[6]  = 8'hE9; test_operands[6]  = 8'h05; // SBC #$05

        // Logical instructions
        test_opcodes[7]  = 8'h29; test_operands[7]  = 8'hF0; // AND #$F0
        test_opcodes[8]  = 8'h09; test_operands[8]  = 8'h0F; // ORA #$0F
        test_opcodes[9]  = 8'h49; test_operands[9]  = 8'hFF; // EOR #$FF

        // Transfer instructions
        test_opcodes[10] = 8'hAA; test_operands[10] = 8'h00; // TAX
        test_opcodes[11] = 8'hA8; test_operands[11] = 8'h00; // TAY
        test_opcodes[12] = 8'h8A; test_operands[12] = 8'h00; // TXA
        test_opcodes[13] = 8'h98; test_operands[13] = 8'h00; // TYA

        // Shift instructions
        test_opcodes[14] = 8'h0A; test_operands[14] = 8'h00; // ASL A
        test_opcodes[15] = 8'h4A; test_operands[15] = 8'h00; // LSR A

        // Compare instructions
        test_opcodes[16] = 8'hC9; test_operands[16] = 8'h55; // CMP #$55

        // Flag instructions
        test_opcodes[17] = 8'h38; test_operands[17] = 8'h00; // SEC
        test_opcodes[18] = 8'h18; test_operands[18] = 8'h00; // CLC

        // Stack instructions
        test_opcodes[19] = 8'h48; test_operands[19] = 8'h00; // PHA
        test_opcodes[20] = 8'h68; test_operands[20] = 8'h00; // PLA

        // Branch instructions
        test_opcodes[21] = 8'h10; test_operands[21] = 8'h05; // BPL +5
        test_opcodes[22] = 8'hF0; test_operands[22] = 8'hFB; // BEQ -5

        // Jump instructions
        test_opcodes[23] = 8'h4C; test_operands[23] = 8'h00; // JMP $3000
        test_opcodes[24] = 8'h20; test_operands[24] = 8'h00; // JSR $4000
        test_opcodes[25] = 8'h60; test_operands[25] = 8'h00; // RTS

        // NOP and undefined
        test_opcodes[26] = 8'hEA; test_operands[26] = 8'h00; // NOP

        // Fill remaining with NOP
        for (int i = 27; i < 32; i++) begin
            test_opcodes[i] = 8'hEA;
            test_operands[i] = 8'h00;
        end
    end

    // CPU Decoder
    cpu_decoder decoder (
        .opcode(test_opcode),
        .status_reg(status_reg),
        .alu_op(alu_op),
        .alu_carry_in(alu_carry_in),
        .reg_a_write(reg_a_write),
        .reg_x_write(reg_x_write),
        .reg_y_write(reg_y_write),
        .reg_sp_write(),
        .reg_pc_write(),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .update_nz(update_nz),
        .update_c(update_c),
        .update_v(update_v),
        .reg_src_sel(reg_src_sel),
        .alu_a_sel(alu_a_sel),
        .alu_b_sel(alu_b_sel),
        .addr_mode(),
        .instruction_length(instruction_length),
        .is_branch(),
        .is_jump(),
        .stack_push(),
        .stack_pop()
    );

    // ALU input multiplexers
    always_comb begin
        case (alu_a_sel)
            2'b00: alu_operand_a = test_reg_a;
            2'b01: alu_operand_a = test_reg_x;
            2'b10: alu_operand_a = test_reg_y;
            2'b11: alu_operand_a = 8'h00;
            default: alu_operand_a = test_reg_a;
        endcase

        case (alu_b_sel)
            2'b00: alu_operand_b = test_operand;  // Memory data
            2'b01: alu_operand_b = test_reg_a;
            2'b10: alu_operand_b = test_reg_x;
            2'b11: alu_operand_b = test_reg_y;
            default: alu_operand_b = test_operand;
        endcase
    end

    // CPU ALU
    cpu_alu alu (
        .operand_a(alu_operand_a),
        .operand_b(alu_operand_b),
        .operation(alu_op),
        .carry_in(alu_carry_in),
        .result(alu_result),
        .carry_out(alu_carry_out),
        .overflow(alu_overflow),
        .negative(alu_negative),
        .zero(alu_zero)
    );

    // Status Register
    status_register status_reg_inst (
        .clk(clk),
        .rst_n(rst_n),
        .update_n(update_nz),
        .update_z(update_nz),
        .update_c(update_c),
        .update_v(update_v),
        .new_n(alu_negative),
        .new_z(alu_zero),
        .new_c(alu_carry_out),
        .new_v(alu_overflow),
        .set_i(1'b0),
        .clear_i(1'b0),
        .set_d(1'b0),
        .clear_d(1'b0),
        .set_b(1'b0),
        .clear_b(1'b0),
        .manual_set_c(test_opcode == 8'h38),    // SEC
        .manual_clear_c(test_opcode == 8'h18),  // CLC
        .status_reg(status_reg)
    );

    // Test sequence controller
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            test_counter <= 27'b0;
            test_instruction_index <= 5'b00000;
            test_reg_a <= 8'h00;
            test_reg_x <= 8'h00;
            test_reg_y <= 8'h00;
        end else begin
            test_counter <= test_counter + 1;

            // Change instruction every ~0.5 seconds
            if (test_counter[25]) begin
                test_counter <= 27'b0;
                test_instruction_index <= test_instruction_index + 1;
            end

            // Manual control with switches
            if (switches[3]) begin
                test_instruction_index <= switches[2:0];
                test_counter <= 27'b0;
            end

            // Simulate register updates for demonstration
            if (reg_a_write && instruction_length != 2'd0) begin
                test_reg_a <= alu_result;
            end
            if (reg_x_write && instruction_length != 2'd0) begin
                test_reg_x <= alu_result;
            end
            if (reg_y_write && instruction_length != 2'd0) begin
                test_reg_y <= alu_result;
            end
        end
    end

    // Assign test data based on current index
    always_comb begin
        test_opcode = test_opcodes[test_instruction_index];
        test_operand = test_operands[test_instruction_index];
    end

    // Debug outputs
    assign debug_alu_result = alu_result;
    assign debug_alu_carry = alu_carry_out;
    assign debug_alu_zero = alu_zero;
    assign debug_alu_negative = alu_negative;
    assign debug_alu_overflow = alu_overflow;

    assign debug_alu_op = alu_op;
    assign debug_reg_a_write = reg_a_write;
    assign debug_mem_read = mem_read;
    assign debug_mem_write = mem_write;

    assign debug_status_reg = status_reg;
    assign debug_opcode = test_opcode;
    assign debug_inst_length = instruction_length;

endmodule