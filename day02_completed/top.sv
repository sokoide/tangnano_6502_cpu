// Day 02 Completed: SystemVerilog Combinational Circuits
// Integrated test module for combinational circuits

module top (
    input  wire clk,
    input  wire [3:0] switches,    // Input switches (virtual)
    output wire [6:0] segments,    // 7-segment output
    output wire led_zero,          // Zero flag
    output wire led_carry,         // Carry flag
    output wire mux_out            // Multiplexer output
);

    // Internal signals
    logic [3:0] alu_result;
    logic zero_flag, carry_flag;

    // Fixed values for testing
    logic [3:0] operand_a = 4'h5;  // Fixed value A = 5
    logic [3:0] operand_b = 4'h3;  // Fixed value B = 3
    logic [1:0] alu_op = 2'b00;    // Addition operation

    // 7-segment decoder
    seven_seg_decoder seg_decoder (
        .digit(alu_result),
        .segments(segments)
    );

    // 4bit ALU
    alu_4bit alu (
        .a(operand_a),
        .b(operand_b),
        .op(alu_op),
        .result(alu_result),
        .zero(zero_flag),
        .carry(carry_flag)
    );

    // 8-to-1 multiplexer
    mux_8to1 mux (
        .data_in(8'b10101010),     // Test pattern
        .select(switches[2:0]),    // Select with switches
        .data_out(mux_out)
    );

    // LED output
    assign led_zero = zero_flag;
    assign led_carry = carry_flag;

endmodule