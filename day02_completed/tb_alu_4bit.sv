// Testbench for 4-bit ALU
// Think of this as a "Unit Test" for your hardware design.
// This code is ONLY for simulation and will not be programmed into the FPGA.

module tb_alu_4bit;

    // 1. Local signals to connect to the Design Under Test (DUT)
    // These act like variables that hold input values and capture outputs.
    logic [3:0] a, b;
    logic [1:0] op;
    logic [3:0] result;
    logic zero, carry;

    // 2. Instantiate the Design Under Test (DUT)
    // This is like creating an instance of a class: ALU dut = new ALU();
    alu_4bit dut (
        .a(a),
        .b(b),
        .op(op),
        .result(result),
        .zero(zero),
        .carry(carry)
    );

    // 3. Test scenario (Initial block runs once at the start of simulation)
    initial begin
        // Waveform generation: enables viewing signal changes in GTKWave
        $dumpfile("tb_alu_4bit.vcd");
        $dumpvars(0, tb_alu_4bit);

        $display("Starting ALU 4-bit tests...");

        // Test case 1: 5 + 3 = 8
        a  = 4'd5;
        b  = 4'd3;
        op = 2'b00;
        #10;  // Wait for 10 time units for the signals to propagate through the logic
        assert (result == 4'd8)
        else $error("Test 1 failed: 5+3 should be 8, got %d", result);
        assert (zero == 1'b0)
        else $error("Test 1 failed: zero flag should be 0");
        assert (carry == 1'b0)
        else $error("Test 1 failed: carry flag should be 0");
        $display("Test 1 passed: 5 + 3 = %d", result);

        // Test case 2: 15 + 1'b1 = 16 (overflow)
        a  = 4'd15;
        b  = 4'd1;
        op = 2'b00;
        #10;
        assert (result == 4'd0)
        else $error("Test 2 failed: 15+1 should overflow to 0, got %d", result);
        assert (zero == 1'b1)
        else $error("Test 2 failed: zero flag should be 1");
        assert (carry == 1'b1)
        else $error("Test 2 failed: carry flag should be 1");
        $display("Test 2 passed: 15 + 1'b1 = %d (carry=%b)", result, carry);

        // Test case 3: 8 - 3 = 5
        a  = 4'd8;
        b  = 4'd3;
        op = 2'b01;
        #10;
        assert (result == 4'd5)
        else $error("Test 3 failed: 8-3 should be 5, got %d", result);
        assert (zero == 1'b0)
        else $error("Test 3 failed: zero flag should be 0");
        $display("Test 3 passed: 8 - 3 = %d", result);

        // Test case 4: 5 - 5 = 0
        a  = 4'd5;
        b  = 4'd5;
        op = 2'b01;
        #10;
        assert (result == 4'd0)
        else $error("Test 4 failed: 5-5 should be 0, got %d", result);
        assert (zero == 1'b1)
        else $error("Test 4 failed: zero flag should be 1");
        $display("Test 4 passed: 5 - 5 = %d (zero=%b)", result, zero);

        // Test case 5: 12 & 10 = 8 (AND)
        a  = 4'b1100;  // 12
        b  = 4'b1010;  // 10
        op = 2'b10;
        #10;
        assert (result == 4'b1000)
        else $error("Test 5 failed: 12&10 should be 8, got %d", result);
        $display("Test 5 passed: 12 & 10 = %d", result);

        // Test case 6: 12 | 10 = 14 (OR)
        a  = 4'b1100;  // 12
        b  = 4'b1010;  // 10
        op = 2'b11;
        #10;
        assert (result == 4'b1110)
        else $error("Test 6 failed: 12|10 should be 14, got %d", result);
        $display("Test 6 passed: 12 | 10 = %d", result);

        $display("All ALU tests completed successfully!");
        $finish;  // End the simulation
    end

endmodule
