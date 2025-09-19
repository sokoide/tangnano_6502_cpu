// Day 04 Completed: 6502 CPU Architecture Overview
// Test module for register set and basic instruction decoding

module top (
    input  wire clk,
    input  wire rst_n,
    input  wire [3:0] switches,           // Input switches for control

    // Debug outputs
    output wire [7:0] debug_reg_a,        // A register
    output wire [7:0] debug_reg_x,        // X register
    output wire [7:0] debug_reg_y,        // Y register
    output wire [7:0] debug_reg_sp,       // Stack pointer
    output wire [7:0] debug_reg_pc_low,   // PC low byte
    output wire [7:0] debug_reg_pc_high,  // PC high byte
    output wire [7:0] debug_flags,        // Status flags

    // Instruction classification outputs
    output wire led_load,                 // Load instruction indicator
    output wire led_store,                // Store instruction indicator
    output wire led_arithmetic,           // Arithmetic instruction indicator
    output wire led_branch                // Branch instruction indicator
);

    // Internal signals
    logic [7:0] test_opcode;
    logic [15:0] reg_pc;
    logic [7:0] reg_a, reg_x, reg_y, reg_sp, reg_p;

    // Test sequence counter
    logic [24:0] test_counter;
    logic [2:0] test_state;

    // Register control signals
    logic a_write, x_write, y_write, sp_write, pc_write, p_write;

    // Test data
    logic [7:0] test_data;
    logic [15:0] test_addr;

    // 6502 Register Set
    cpu_registers registers (
        .clk(clk),
        .rst_n(rst_n),
        .a_write(a_write),
        .x_write(x_write),
        .y_write(y_write),
        .sp_write(sp_write),
        .pc_write(pc_write),
        .p_write(p_write),
        .data_in(test_data),
        .addr_in(test_addr),
        .reg_a(reg_a),
        .reg_x(reg_x),
        .reg_y(reg_y),
        .reg_sp(reg_sp),
        .reg_pc(reg_pc),
        .reg_p(reg_p)
    );

    // Simple instruction decoder
    simple_decoder decoder (
        .opcode(test_opcode),
        .is_load(led_load),
        .is_store(led_store),
        .is_transfer(),              // Not used in this demo
        .is_arithmetic(led_arithmetic),
        .is_logical(),               // Not used in this demo
        .is_shift(),                 // Not used in this demo
        .is_branch(led_branch),
        .is_jump(),                  // Not used in this demo
        .is_compare(),               // Not used in this demo
        .is_flag(),                  // Not used in this demo
        .is_stack(),                 // Not used in this demo
        .is_nop()                    // Not used in this demo
    );

    // Test sequence controller
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            test_counter <= 25'b0;
            test_state <= 3'b000;
            a_write <= 1'b0;
            x_write <= 1'b0;
            y_write <= 1'b0;
            sp_write <= 1'b0;
            pc_write <= 1'b0;
            p_write <= 1'b0;
            test_data <= 8'h00;
            test_addr <= 16'h0000;
            test_opcode <= 8'hEA;    // NOP
        end else begin
            test_counter <= test_counter + 1;

            // Reset all write signals
            {a_write, x_write, y_write, sp_write, pc_write, p_write} <= 6'b000000;

            // State machine for testing registers
            if (test_counter[24]) begin  // Slow state changes
                test_counter <= 25'b0;
                test_state <= test_state + 1;

                case (test_state)
                    3'b000: begin  // Test A register
                        a_write <= 1'b1;
                        test_data <= 8'h55;
                        test_opcode <= 8'hA9;  // LDA immediate
                    end

                    3'b001: begin  // Test X register
                        x_write <= 1'b1;
                        test_data <= 8'hAA;
                        test_opcode <= 8'hA2;  // LDX immediate
                    end

                    3'b010: begin  // Test Y register
                        y_write <= 1'b1;
                        test_data <= 8'h33;
                        test_opcode <= 8'hA0;  // LDY immediate
                    end

                    3'b011: begin  // Test PC
                        pc_write <= 1'b1;
                        test_addr <= 16'h1234;
                        test_opcode <= 8'h4C;  // JMP absolute
                    end

                    3'b100: begin  // Test store instruction
                        test_opcode <= 8'h85;  // STA zero page
                    end

                    3'b101: begin  // Test arithmetic instruction
                        test_opcode <= 8'h69;  // ADC immediate
                    end

                    3'b110: begin  // Test branch instruction
                        test_opcode <= 8'h10;  // BPL
                    end

                    3'b111: begin  // Reset to beginning
                        test_opcode <= 8'hEA;  // NOP
                    end
                endcase
            end

            // Switch-controlled opcodes for manual testing
            if (switches[3]) begin
                case (switches[2:0])
                    3'b000: test_opcode <= 8'hA9;  // LDA immediate
                    3'b001: test_opcode <= 8'h85;  // STA zero page
                    3'b010: test_opcode <= 8'h69;  // ADC immediate
                    3'b011: test_opcode <= 8'h10;  // BPL
                    3'b100: test_opcode <= 8'hAA;  // TAX
                    3'b101: test_opcode <= 8'h4C;  // JMP absolute
                    3'b110: test_opcode <= 8'hC9;  // CMP immediate
                    3'b111: test_opcode <= 8'hEA;  // NOP
                endcase
            end
        end
    end

    // Debug outputs
    assign debug_reg_a = reg_a;
    assign debug_reg_x = reg_x;
    assign debug_reg_y = reg_y;
    assign debug_reg_sp = reg_sp;
    assign debug_reg_pc_low = reg_pc[7:0];
    assign debug_reg_pc_high = reg_pc[15:8];
    assign debug_flags = reg_p;

endmodule