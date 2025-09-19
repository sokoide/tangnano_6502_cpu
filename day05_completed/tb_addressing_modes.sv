// Testbench for Addressing Mode Calculator
// Test all major 6502 addressing modes

module tb_addressing_modes;

    logic [7:0] opcode;
    logic [15:0] pc;
    logic [7:0] operand1, operand2;
    logic [7:0] reg_x, reg_y;
    logic [15:0] effective_addr;
    logic [2:0] addr_mode;
    logic [1:0] instruction_length;
    logic page_crossed;

    // Test target instantiation
    addressing_mode_calculator uut (
        .opcode(opcode),
        .pc(pc),
        .operand1(operand1),
        .operand2(operand2),
        .reg_x(reg_x),
        .reg_y(reg_y),
        .effective_addr(effective_addr),
        .addr_mode(addr_mode),
        .instruction_length(instruction_length),
        .page_crossed(page_crossed)
    );

    initial begin
        $display("Starting 6502 Addressing Mode tests...");

        // Initialize registers
        pc = 16'h0200;
        reg_x = 8'h05;
        reg_y = 8'h0A;

        // Test 1: LDA Immediate #$55
        opcode = 8'hA9;
        operand1 = 8'h55;
        operand2 = 8'h00;
        #10;
        assert (effective_addr == 16'h0201) else $error("Test 1 failed: LDA #$55");
        assert (instruction_length == 2'd2) else $error("Test 1 failed: length should be 2");
        $display("Test 1 passed: LDA #$55 -> EA=0x%04X, len=%d", effective_addr, instruction_length);

        // Test 2: LDA Zero Page $80
        opcode = 8'hA5;
        operand1 = 8'h80;
        operand2 = 8'h00;
        #10;
        assert (effective_addr == 16'h0080) else $error("Test 2 failed: LDA $80");
        assert (instruction_length == 2'd2) else $error("Test 2 failed: length should be 2");
        $display("Test 2 passed: LDA $80 -> EA=0x%04X, len=%d", effective_addr, instruction_length);

        // Test 3: LDA Zero Page,X $80,X
        opcode = 8'hB5;
        operand1 = 8'h80;
        operand2 = 8'h00;
        #10;
        assert (effective_addr == 16'h0085) else $error("Test 3 failed: LDA $80,X");
        assert (instruction_length == 2'd2) else $error("Test 3 failed: length should be 2");
        $display("Test 3 passed: LDA $80,X -> EA=0x%04X, len=%d", effective_addr, instruction_length);

        // Test 4: LDA Absolute $1234
        opcode = 8'hAD;
        operand1 = 8'h34;  // Low byte
        operand2 = 8'h12;  // High byte (little endian)
        #10;
        assert (effective_addr == 16'h1234) else $error("Test 4 failed: LDA $1234");
        assert (instruction_length == 2'd3) else $error("Test 4 failed: length should be 3");
        $display("Test 4 passed: LDA $1234 -> EA=0x%04X, len=%d", effective_addr, instruction_length);

        // Test 5: LDA Absolute,X $1234,X (no page crossing)
        opcode = 8'hBD;
        operand1 = 8'h34;
        operand2 = 8'h12;
        #10;
        assert (effective_addr == 16'h1239) else $error("Test 5 failed: LDA $1234,X");
        assert (page_crossed == 1'b0) else $error("Test 5 failed: no page crossing expected");
        $display("Test 5 passed: LDA $1234,X -> EA=0x%04X, page_crossed=%b", effective_addr, page_crossed);

        // Test 6: LDA Absolute,X with page crossing $12FF,X
        opcode = 8'hBD;
        operand1 = 8'hFF;
        operand2 = 8'h12;
        #10;
        assert (effective_addr == 16'h1304) else $error("Test 6 failed: LDA $12FF,X");
        assert (page_crossed == 1'b1) else $error("Test 6 failed: page crossing expected");
        $display("Test 6 passed: LDA $12FF,X -> EA=0x%04X, page_crossed=%b", effective_addr, page_crossed);

        // Test 7: LDA Absolute,Y $1000,Y
        opcode = 8'hB9;
        operand1 = 8'h00;
        operand2 = 8'h10;
        #10;
        assert (effective_addr == 16'h100A) else $error("Test 7 failed: LDA $1000,Y");
        $display("Test 7 passed: LDA $1000,Y -> EA=0x%04X", effective_addr);

        // Test 8: Branch BPL +5
        pc = 16'h0300;
        opcode = 8'h10;  // BPL
        operand1 = 8'h05; // +5 offset
        operand2 = 8'h00;
        #10;
        assert (effective_addr == 16'h0307) else $error("Test 8 failed: BPL +5");
        $display("Test 8 passed: BPL +5 -> EA=0x%04X", effective_addr);

        // Test 9: Branch BNE -5 (negative offset)
        pc = 16'h0310;
        opcode = 8'hD0;   // BNE
        operand1 = 8'hFB; // -5 offset (two's complement)
        operand2 = 8'h00;
        #10;
        assert (effective_addr == 16'h030D) else $error("Test 9 failed: BNE -5");
        $display("Test 9 passed: BNE -5 -> EA=0x%04X", effective_addr);

        // Test 10: Zero page wraparound $FF,X
        opcode = 8'hB5;  // LDA zp,X
        operand1 = 8'hFF;
        operand2 = 8'h00;
        reg_x = 8'h05;
        #10;
        assert (effective_addr == 16'h0004) else $error("Test 10 failed: zero page wraparound");
        $display("Test 10 passed: LDA $FF,X -> EA=0x%04X (wraparound)", effective_addr);

        $display("All addressing mode tests completed successfully!");
        $finish;
    end

endmodule