// 4-bit Arithmetic Logic Unit (ALU)
// This module performs basic arithmetic and logic operations based on the 'op' input.

module alu_4bit (
    input  logic [3:0] a,       // 4-bit input A
    input  logic [3:0] b,       // 4-bit input B
    input  logic [1:0] op,      // 2-bit operation selector
    output logic [3:0] result,  // 4-bit computation result
    output logic       zero,    // Flag: set to 1 if result is 0
    output logic       carry    // Flag: set to 1 if addition has carry or subtraction has borrow
);

    // temp_result is 5 bits wide to capture the carry-out (5th bit)
    logic [4:0] temp_result;

    // Combinational logic block
    // always_comb ensures that outputs are updated instantly whenever any input changes.
    always_comb begin
        // Important: Set default values for all outputs at the beginning.
        // This prevents the tool from creating a "latch" (accidental memory).
        temp_result = 5'd0;
        result = 4'd0;
        carry = 1'b0;

        // Select operation based on 'op'
        // This 'case' statement is synthesized into a hardware multiplexer (MUX).
        case (op)
            2'b00: begin  // Addition
                temp_result = {1'b0, a} + {1'b0, b};
                result = temp_result[3:0];
                carry = temp_result[4];
            end

            2'b01: begin  // Subtraction
                // In hardware subtraction, temp_result[4] acts as a "borrow" bit.
                temp_result = {1'b0, a} - {1'b0, b};
                result = temp_result[3:0];
                carry = temp_result[4];
            end

            2'b10: begin  // Logical AND
                result = a & b;
                // carry remains 0 (default)
            end

            2'b11: begin  // Logical OR
                result = a | b;
                // carry remains 0 (default)
            end

            default: begin
                // No action needed; defaults are already set.
            end
        endcase

        // Zero flag calculation
        // This is updated continuously based on the 'result' signal.
        zero = (result == 4'b0000);
    end

endmodule
