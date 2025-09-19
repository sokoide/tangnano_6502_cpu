// Complete 6502 ALU Implementation
// Supports all 6502 arithmetic and logical operations

module cpu_alu (
    input  logic [7:0]  operand_a,
    input  logic [7:0]  operand_b,
    input  logic [3:0]  operation,
    input  logic        carry_in,

    output logic [7:0]  result,
    output logic        carry_out,
    output logic        overflow,
    output logic        negative,
    output logic        zero
);

    logic [8:0] temp_result;
    logic [7:0] shift_result;

    always_comb begin
        // Default values
        temp_result = 9'b000000000;
        shift_result = 8'b00000000;
        overflow = 1'b0;

        case (operation)
            4'b0000: begin // ADD (ADC)
                temp_result = {1'b0, operand_a} + {1'b0, operand_b} + {8'b0, carry_in};
                // Overflow detection for signed arithmetic
                overflow = (operand_a[7] == operand_b[7]) &&
                          (operand_a[7] != temp_result[7]);
            end

            4'b0001: begin // SUB (SBC)
                temp_result = {1'b0, operand_a} - {1'b0, operand_b} - {8'b0, ~carry_in};
                // Overflow detection for signed subtraction
                overflow = (operand_a[7] != operand_b[7]) &&
                          (operand_a[7] != temp_result[7]);
            end

            4'b0010: begin // AND
                temp_result = {1'b0, operand_a & operand_b};
            end

            4'b0011: begin // OR (ORA)
                temp_result = {1'b0, operand_a | operand_b};
            end

            4'b0100: begin // XOR (EOR)
                temp_result = {1'b0, operand_a ^ operand_b};
            end

            4'b0101: begin // ASL (Arithmetic Shift Left)
                shift_result = {operand_a[6:0], 1'b0};
                temp_result = {operand_a[7], shift_result};
            end

            4'b0110: begin // LSR (Logical Shift Right)
                shift_result = {1'b0, operand_a[7:1]};
                temp_result = {operand_a[0], shift_result};
            end

            4'b0111: begin // ROL (Rotate Left)
                shift_result = {operand_a[6:0], carry_in};
                temp_result = {operand_a[7], shift_result};
            end

            4'b1000: begin // ROR (Rotate Right)
                shift_result = {carry_in, operand_a[7:1]};
                temp_result = {operand_a[0], shift_result};
            end

            4'b1001: begin // INC (Increment)
                temp_result = {1'b0, operand_a} + 9'b000000001;
                // INC does not affect carry flag on 6502
                temp_result[8] = 1'b0;
            end

            4'b1010: begin // DEC (Decrement)
                temp_result = {1'b0, operand_a} - 9'b000000001;
                // DEC does not affect carry flag on 6502
                temp_result[8] = 1'b0;
            end

            4'b1011: begin // PASS A (Transfer A)
                temp_result = {1'b0, operand_a};
            end

            4'b1100: begin // PASS B (Load from memory)
                temp_result = {1'b0, operand_b};
            end

            4'b1101: begin // CMP (Compare - same as SUB but doesn't store result)
                temp_result = {1'b0, operand_a} - {1'b0, operand_b};
            end

            4'b1110: begin // CPX (Compare X - same as SUB)
                temp_result = {1'b0, operand_a} - {1'b0, operand_b};
            end

            4'b1111: begin // CPY (Compare Y - same as SUB)
                temp_result = {1'b0, operand_a} - {1'b0, operand_b};
            end

            default: begin
                temp_result = {1'b0, operand_a};
            end
        endcase

        // Output assignments
        result = temp_result[7:0];
        carry_out = temp_result[8];
        negative = temp_result[7];
        zero = (temp_result[7:0] == 8'h00);
    end

endmodule