// 6502 Flag Calculator
// Calculate processor status flags

module flag_calculator (
    input  logic [7:0] result,
    input  logic [7:0] operand_a,
    input  logic [7:0] operand_b,
    input  logic       operation,     // 0:ADD, 1:SUB
    input  logic       carry_in,

    output logic flag_n,              // Negative
    output logic flag_z,              // Zero
    output logic flag_c,              // Carry
    output logic flag_v               // Overflow
);

    logic [8:0] temp_result;

    always_comb begin
        // Calculate 9-bit result to detect carry
        if (operation) begin
            // Subtraction (SBC uses inverted carry)
            temp_result = {1'b0, operand_a} - {1'b0, operand_b} - {8'b0, ~carry_in};
        end else begin
            // Addition (ADC)
            temp_result = {1'b0, operand_a} + {1'b0, operand_b} + {8'b0, carry_in};
        end

        // Flag calculations
        flag_n = result[7];                    // Negative: MSB of result
        flag_z = (result == 8'h00);            // Zero: result is zero
        flag_c = temp_result[8];               // Carry: 9th bit

        // Overflow: signed arithmetic overflow
        // Occurs when signs of operands are same but result sign differs
        if (operation) begin
            // For subtraction: A - B, check A and ~B
            flag_v = (operand_a[7] == (~operand_b)[7]) &&
                     (operand_a[7] != result[7]);
        end else begin
            // For addition: A + B
            flag_v = (operand_a[7] == operand_b[7]) &&
                     (operand_a[7] != result[7]);
        end
    end

endmodule