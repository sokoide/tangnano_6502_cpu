// 4bit ALU Implementation
// 4-bit Arithmetic Logic Unit

module alu_4bit (
    input  logic [3:0] a,
    input  logic [3:0] b,
    input  logic [1:0] op,
    output logic [3:0] result,
    output logic zero,
    output logic carry
);

    logic [4:0] temp_result;  // For carry calculation

    always_comb begin
        case (op)
            2'b00: begin  // Addition
                temp_result = {1'b0, a} + {1'b0, b};
                result = temp_result[3:0];
                carry = temp_result[4];
            end

            2'b01: begin  // Subtraction
                temp_result = {1'b0, a} - {1'b0, b};
                result = temp_result[3:0];
                carry = temp_result[4];  // Borrow
            end

            2'b10: begin  // AND
                result = a & b;
                carry = 1'b0;
            end

            2'b11: begin  // OR
                result = a | b;
                carry = 1'b0;
            end

            default: begin
                result = 4'b0000;
                carry = 1'b0;
            end
        endcase

        zero = (result == 4'b0000);
    end

endmodule