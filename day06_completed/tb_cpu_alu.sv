// Testbench for 6502 CPU ALU
// Test all ALU operations with proper 6502 behavior

module tb_cpu_alu;

    logic [7:0] operand_a, operand_b;
    logic [3:0] operation;
    logic carry_in;
    logic [7:0] result;
    logic carry_out, overflow, negative, zero;

    // Test target instantiation
    cpu_alu uut (
        .operand_a(operand_a),
        .operand_b(operand_b),
        .operation(operation),
        .carry_in(carry_in),
        .result(result),
        .carry_out(carry_out),
        .overflow(overflow),
        .negative(negative),
        .zero(zero)
    );

    initial begin
        $display("Starting 6502 CPU ALU tests...");

        // Test 1: ADD without carry
        operand_a = 8'h50;  // 80 decimal
        operand_b = 8'h30;  // 48 decimal
        operation = 4'b0000; // ADD
        carry_in = 1'b0;
        #10;
        assert (result == 8'h80) else $error("Test 1 failed: ADD 0x50+0x30");
        assert (negative == 1'b1) else $error("Test 1 failed: negative flag should be set");
        assert (zero == 1'b0) else $error("Test 1 failed: zero flag should be clear");
        assert (carry_out == 1'b0) else $error("Test 1 failed: carry should be clear");
        assert (overflow == 1'b1) else $error("Test 1 failed: overflow should be set");
        $display("Test 1 passed: ADD 0x50+0x30 = 0x%02X (N=%b Z=%b C=%b V=%b)",
                 result, negative, zero, carry_out, overflow);

        // Test 2: ADD with carry
        operand_a = 8'hFF;
        operand_b = 8'h01;
        operation = 4'b0000; // ADD
        carry_in = 1'b0;
        #10;
        assert (result == 8'h00) else $error("Test 2 failed: ADD 0xFF+0x01");
        assert (zero == 1'b1) else $error("Test 2 failed: zero flag should be set");
        assert (carry_out == 1'b1) else $error("Test 2 failed: carry should be set");
        $display("Test 2 passed: ADD 0xFF+0x01 = 0x%02X (C=%b Z=%b)",
                 result, carry_out, zero);

        // Test 3: SUB without borrow
        operand_a = 8'h80;
        operand_b = 8'h30;
        operation = 4'b0001; // SUB
        carry_in = 1'b1;     // No borrow (carry set)
        #10;
        assert (result == 8'h50) else $error("Test 3 failed: SUB 0x80-0x30");
        assert (carry_out == 1'b1) else $error("Test 3 failed: carry should remain set");
        $display("Test 3 passed: SUB 0x80-0x30 = 0x%02X (C=%b)", result, carry_out);

        // Test 4: SUB with borrow
        operand_a = 8'h30;
        operand_b = 8'h80;
        operation = 4'b0001; // SUB
        carry_in = 1'b1;     // No borrow initially
        #10;
        assert (result == 8'hB0) else $error("Test 4 failed: SUB 0x30-0x80");
        assert (carry_out == 1'b0) else $error("Test 4 failed: carry should be clear (borrow)");
        $display("Test 4 passed: SUB 0x30-0x80 = 0x%02X (C=%b)", result, carry_out);

        // Test 5: AND operation
        operand_a = 8'hF0;
        operand_b = 8'h0F;
        operation = 4'b0010; // AND
        carry_in = 1'b0;
        #10;
        assert (result == 8'h00) else $error("Test 5 failed: AND 0xF0&0x0F");
        assert (zero == 1'b1) else $error("Test 5 failed: zero flag should be set");
        $display("Test 5 passed: AND 0xF0&0x0F = 0x%02X (Z=%b)", result, zero);

        // Test 6: OR operation
        operand_a = 8'hF0;
        operand_b = 8'h0F;
        operation = 4'b0011; // OR
        carry_in = 1'b0;
        #10;
        assert (result == 8'hFF) else $error("Test 6 failed: OR 0xF0|0x0F");
        assert (negative == 1'b1) else $error("Test 6 failed: negative flag should be set");
        $display("Test 6 passed: OR 0xF0|0x0F = 0x%02X (N=%b)", result, negative);

        // Test 7: XOR operation
        operand_a = 8'hAA;
        operand_b = 8'h55;
        operation = 4'b0100; // XOR
        carry_in = 1'b0;
        #10;
        assert (result == 8'hFF) else $error("Test 7 failed: XOR 0xAA^0x55");
        $display("Test 7 passed: XOR 0xAA^0x55 = 0x%02X", result);

        // Test 8: ASL (Arithmetic Shift Left)
        operand_a = 8'h81;   // 10000001
        operand_b = 8'h00;
        operation = 4'b0101; // ASL
        carry_in = 1'b0;
        #10;
        assert (result == 8'h02) else $error("Test 8 failed: ASL 0x81");
        assert (carry_out == 1'b1) else $error("Test 8 failed: carry should be set from bit 7");
        $display("Test 8 passed: ASL 0x81 = 0x%02X (C=%b)", result, carry_out);

        // Test 9: LSR (Logical Shift Right)
        operand_a = 8'h81;   // 10000001
        operand_b = 8'h00;
        operation = 4'b0110; // LSR
        carry_in = 1'b0;
        #10;
        assert (result == 8'h40) else $error("Test 9 failed: LSR 0x81");
        assert (carry_out == 1'b1) else $error("Test 9 failed: carry should be set from bit 0");
        $display("Test 9 passed: LSR 0x81 = 0x%02X (C=%b)", result, carry_out);

        // Test 10: ROL (Rotate Left)
        operand_a = 8'h81;   // 10000001
        operand_b = 8'h00;
        operation = 4'b0111; // ROL
        carry_in = 1'b1;     // Carry in becomes bit 0
        #10;
        assert (result == 8'h03) else $error("Test 10 failed: ROL 0x81 with carry");
        assert (carry_out == 1'b1) else $error("Test 10 failed: carry should be set from bit 7");
        $display("Test 10 passed: ROL 0x81 with C=1 = 0x%02X (C=%b)", result, carry_out);

        // Test 11: ROR (Rotate Right)
        operand_a = 8'h81;   // 10000001
        operand_b = 8'h00;
        operation = 4'b1000; // ROR
        carry_in = 1'b1;     // Carry in becomes bit 7
        #10;
        assert (result == 8'hC0) else $error("Test 11 failed: ROR 0x81 with carry");
        assert (carry_out == 1'b1) else $error("Test 11 failed: carry should be set from bit 0");
        $display("Test 11 passed: ROR 0x81 with C=1 = 0x%02X (C=%b)", result, carry_out);

        // Test 12: INC (Increment)
        operand_a = 8'hFE;
        operand_b = 8'h00;
        operation = 4'b1001; // INC
        carry_in = 1'b0;
        #10;
        assert (result == 8'hFF) else $error("Test 12 failed: INC 0xFE");
        assert (carry_out == 1'b0) else $error("Test 12 failed: INC should not affect carry");
        $display("Test 12 passed: INC 0xFE = 0x%02X (C=%b)", result, carry_out);

        // Test 13: DEC (Decrement)
        operand_a = 8'h01;
        operand_b = 8'h00;
        operation = 4'b1010; // DEC
        carry_in = 1'b0;
        #10;
        assert (result == 8'h00) else $error("Test 13 failed: DEC 0x01");
        assert (zero == 1'b1) else $error("Test 13 failed: zero flag should be set");
        assert (carry_out == 1'b0) else $error("Test 13 failed: DEC should not affect carry");
        $display("Test 13 passed: DEC 0x01 = 0x%02X (Z=%b C=%b)", result, zero, carry_out);

        // Test 14: CMP (Compare - same as SUB)
        operand_a = 8'h50;
        operand_b = 8'h50;
        operation = 4'b1101; // CMP
        carry_in = 1'b0;
        #10;
        assert (result == 8'h00) else $error("Test 14 failed: CMP 0x50,0x50");
        assert (zero == 1'b1) else $error("Test 14 failed: zero flag should be set for equal");
        assert (carry_out == 1'b1) else $error("Test 14 failed: carry should be set for A>=B");
        $display("Test 14 passed: CMP 0x50,0x50 = 0x%02X (Z=%b C=%b)", result, zero, carry_out);

        $display("All 6502 CPU ALU tests completed successfully!");
        $finish;
    end

endmodule