// Day 02: 4-bit ALU Template
// Implementation goal: Complete the cases for subtraction, AND, and OR.

module alu_4bit (
    input  logic [3:0] a,       // 4-bit input A
    input  logic [3:0] b,       // 4-bit input B
    input  logic [1:0] op,      // 2-bit operation selector
    output logic [3:0] result,  // 4-bit computation result
    output logic       zero,    // Flag: set to 1 if result is 0
    output logic       carry    // Flag: set to 1 if addition has carry or subtraction has borrow
);

    logic [4:0] temp_result;

    always_comb begin
        // Important: Set default values to avoid inferred latches
        temp_result = 5'd0;
        result = 4'd0;
        carry = 1'b0;

        case (op)
            2'b00: begin  // Addition
                temp_result = {1'b0, a} + {1'b0, b};
                result = temp_result[3:0];
                carry = temp_result[4];
            end

            // TODO: Implement Subtraction (op = 2'b01)
            // TODO: Implement Logical AND (op = 2'b10)
            // TODO: Implement Logical OR  (op = 2'b11)

            default: begin
                // Keep defaults
            end
        endcase

        zero = (result == 4'b0000);
    end

endmodule
