// Day 05 Completed: 6502 Instruction Set and Addressing Modes
// Test module for addressing mode calculation and instruction decoding

module top (
    input  wire clk,
    input  wire rst_n,
    input  wire [3:0] switches,           // Control switches

    // Debug outputs for addressing
    output wire [7:0] debug_addr_low,     // Effective address low
    output wire [7:0] debug_addr_high,    // Effective address high
    output wire [2:0] debug_addr_mode,    // Addressing mode
    output wire [1:0] debug_inst_length,  // Instruction length
    output wire debug_page_crossed,       // Page boundary crossed

    // Instruction type indicators
    output wire led_load,                 // Load instruction
    output wire led_store,                // Store instruction
    output wire led_arithmetic,           // Arithmetic instruction
    output wire led_branch,               // Branch instruction

    // Additional debug
    output wire [7:0] debug_opcode,       // Current opcode
    output wire [7:0] debug_operand1,     // First operand
    output wire [7:0] debug_operand2      // Second operand
);

    // Test sequence control
    logic [26:0] test_counter;
    logic [3:0] test_opcode_index;

    // Test data
    logic [7:0] test_opcode;
    logic [7:0] test_operand1, test_operand2;
    logic [15:0] test_pc;
    logic [7:0] test_reg_x, test_reg_y;

    // Addressing mode calculator outputs
    logic [15:0] effective_addr;
    logic [2:0] addr_mode;
    logic [1:0] instruction_length;
    logic page_crossed;

    // Test opcodes and their operands
    logic [7:0] test_opcodes [0:15];
    logic [7:0] test_operand1_data [0:15];
    logic [7:0] test_operand2_data [0:15];

    // Initialize test data
    initial begin
        // Various addressing modes to demonstrate
        test_opcodes[0]  = 8'hA9; test_operand1_data[0]  = 8'h55; test_operand2_data[0]  = 8'h00; // LDA #$55
        test_opcodes[1]  = 8'hA5; test_operand1_data[1]  = 8'h80; test_operand2_data[1]  = 8'h00; // LDA $80
        test_opcodes[2]  = 8'hB5; test_operand1_data[2]  = 8'h80; test_operand2_data[2]  = 8'h00; // LDA $80,X
        test_opcodes[3]  = 8'hAD; test_operand1_data[3]  = 8'h34; test_operand2_data[3]  = 8'h12; // LDA $1234
        test_opcodes[4]  = 8'hBD; test_operand1_data[4]  = 8'h34; test_operand2_data[4]  = 8'h12; // LDA $1234,X
        test_opcodes[5]  = 8'hB9; test_operand1_data[5]  = 8'h34; test_operand2_data[5]  = 8'h12; // LDA $1234,Y
        test_opcodes[6]  = 8'h85; test_operand1_data[6]  = 8'h90; test_operand2_data[6]  = 8'h00; // STA $90
        test_opcodes[7]  = 8'h8D; test_operand1_data[7]  = 8'h56; test_operand2_data[7]  = 8'h34; // STA $3456
        test_opcodes[8]  = 8'h69; test_operand1_data[8]  = 8'h10; test_operand2_data[8]  = 8'h00; // ADC #$10
        test_opcodes[9]  = 8'h4C; test_operand1_data[9]  = 8'h00; test_operand2_data[9]  = 8'h30; // JMP $3000
        test_opcodes[10] = 8'h10; test_operand1_data[10] = 8'h05; test_operand2_data[10] = 8'h00; // BPL +5
        test_opcodes[11] = 8'hD0; test_operand1_data[11] = 8'hFB; test_operand2_data[11] = 8'h00; // BNE -5
        test_opcodes[12] = 8'hAA; test_operand1_data[12] = 8'h00; test_operand2_data[12] = 8'h00; // TAX
        test_opcodes[13] = 8'hA1; test_operand1_data[13] = 8'h20; test_operand2_data[13] = 8'h00; // LDA ($20,X)
        test_opcodes[14] = 8'hB1; test_operand1_data[14] = 8'h30; test_operand2_data[14] = 8'h00; // LDA ($30),Y
        test_opcodes[15] = 8'hEA; test_operand1_data[15] = 8'h00; test_operand2_data[15] = 8'h00; // NOP
    end

    // Addressing mode calculator
    addressing_mode_calculator addr_calc (
        .opcode(test_opcode),
        .pc(test_pc),
        .operand1(test_operand1),
        .operand2(test_operand2),
        .reg_x(test_reg_x),
        .reg_y(test_reg_y),
        .effective_addr(effective_addr),
        .addr_mode(addr_mode),
        .instruction_length(instruction_length),
        .page_crossed(page_crossed)
    );

    // Instruction decoder
    instruction_decoder decoder (
        .opcode(test_opcode),
        .is_load(led_load),
        .is_store(led_store),
        .is_arithmetic(led_arithmetic),
        .is_logical(),
        .is_shift(),
        .is_branch(led_branch),
        .is_jump(),
        .is_transfer(),
        .is_compare(),
        .is_flag(),
        .is_stack(),
        .use_reg_a(),
        .use_reg_x(),
        .use_reg_y(),
        .affects_n(),
        .affects_z(),
        .affects_c(),
        .affects_v(),
        .mem_read(),
        .mem_write()
    );

    // Test sequence controller
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            test_counter <= 27'b0;
            test_opcode_index <= 4'b0000;
            test_pc <= 16'h0200;
            test_reg_x <= 8'h05;
            test_reg_y <= 8'h0A;
        end else begin
            test_counter <= test_counter + 1;

            // Change test case every ~0.5 seconds (at 27MHz)
            if (test_counter[25]) begin
                test_counter <= 27'b0;
                test_opcode_index <= test_opcode_index + 1;

                // Update PC to simulate instruction execution
                test_pc <= test_pc + {14'b0, instruction_length};
            end

            // Manual control with switches
            if (switches[3]) begin
                test_opcode_index <= switches[2:0];
                // Reset counter to hold the selected instruction
                test_counter <= 27'b0;
            end
        end
    end

    // Assign test data based on current index
    always_comb begin
        test_opcode = test_opcodes[test_opcode_index];
        test_operand1 = test_operand1_data[test_opcode_index];
        test_operand2 = test_operand2_data[test_opcode_index];
    end

    // Debug outputs
    assign debug_addr_low = effective_addr[7:0];
    assign debug_addr_high = effective_addr[15:8];
    assign debug_addr_mode = addr_mode;
    assign debug_inst_length = instruction_length;
    assign debug_page_crossed = page_crossed;
    assign debug_opcode = test_opcode;
    assign debug_operand1 = test_operand1;
    assign debug_operand2 = test_operand2;

endmodule