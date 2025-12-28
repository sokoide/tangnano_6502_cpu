// Day 02: 4-bit ALU Testbench Template
// Goal: Verify your ALU implementation using simulation.

module tb_alu_4bit;

    logic [3:0] a, b;
    logic [1:0] op;
    logic [3:0] result;
    logic zero, carry;

    // Instantiate the Design Under Test (DUT)
    alu_4bit dut (
        .a(a), .b(b), .op(op),
        .result(result), .zero(zero), .carry(carry)
    );

    initial begin
        // Waveform generation
        $dumpfile("tb_alu_4bit.vcd");
        $dumpvars(0, tb_alu_4bit);

        $display("Starting ALU 4-bit tests...");

        // Test case 1: 5 + 3 = 8
        a  = 4'd5;
        b  = 4'd3;
        op = 2'b00;
        #10;
        assert (result == 4'd8) else $error("Addition failed");
        $display("Test 1 passed: 5 + 3 = %d", result);

        // TODO: Add more test cases for Subtraction, AND, and OR

        $display("All tests completed!");
        $finish;
    end

endmodule
