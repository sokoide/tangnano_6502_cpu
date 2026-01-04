/* verilator lint_off PINCONNECTEMPTY */
/* verilator lint_off UNUSEDSIGNAL */
// Day 04 Completed: 6502 CPU Architecture Overview
// Test module for register set and basic instruction decoding

module top_core (
    input logic       clk,
    input logic       rst_n,
    input logic [3:0] switches, // Input switches for control

    // Debug outputs
    output logic [7:0] debug_reg_a,        // A register
    output logic [7:0] debug_reg_x,        // X register
    output logic [7:0] debug_reg_y,        // Y register
    output logic [7:0] debug_reg_sp,       // Stack pointer
    output logic [7:0] debug_reg_pc_low,   // PC low byte
    output logic [7:0] debug_reg_pc_high,  // PC high byte
    output logic [7:0] debug_flags,        // Status flags

    // Instruction classification outputs
    output logic led_load,        // Load instruction indicator
    output logic led_store,       // Store instruction indicator
    output logic led_arithmetic,  // Arithmetic instruction indicator
    output logic led_branch       // Branch instruction indicator
);

    // Internal signals
    logic [ 7:0] demo_opcode;
    logic [15:0] reg_pc;
    logic [7:0] reg_a, reg_x, reg_y, reg_sp, reg_p;

    // Test sequence counter
    logic [24:0] demo_counter;
    logic [ 2:0] demo_state;

    // Register control signals
    logic a_write, x_write, y_write, sp_write, pc_write, p_write;

    // Test data
    logic [ 7:0] demo_data;
    logic [15:0] demo_addr;

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
        .data_in(demo_data),
        .addr_in(demo_addr),
        .reg_a(reg_a),
        .reg_x(reg_x),
        .reg_y(reg_y),
        .reg_sp(reg_sp),
        .reg_pc(reg_pc),
        .reg_p(reg_p)
    );

    // Simple instruction decoder
    simple_decoder decoder (
        .opcode       (demo_opcode),
        .is_load      (led_load),
        .is_store     (led_store),
        .is_transfer  (),                // Not used in this demo
        .is_arithmetic(led_arithmetic),
        .is_logical   (),                // Not used in this demo
        .is_shift     (),                // Not used in this demo
        .is_branch    (led_branch),
        .is_jump      (),                // Not used in this demo
        .is_compare   (),                // Not used in this demo
        .is_flag      (),                // Not used in this demo
        .is_stack     (),                // Not used in this demo
        .is_nop       ()                 // Not used in this demo
    );

    // Test sequence controller
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            demo_counter <= 25'b0;
            demo_state <= 3'b000;
            a_write <= 1'b0;
            x_write <= 1'b0;
            y_write <= 1'b0;
            sp_write <= 1'b0;
            pc_write <= 1'b0;
            p_write <= 1'b0;
            demo_data <= 8'h00;
            demo_addr <= 16'h0000;
            demo_opcode <= 8'hEA;  // NOP
        end else begin
            demo_counter <= demo_counter + 1;

            // Reset all write signals
            {a_write, x_write, y_write, sp_write, pc_write, p_write} <= 6'b000000;

            // State machine for testing registers
            if (demo_counter[24]) begin  // Slow state changes
                demo_counter <= 25'b0;
                demo_state   <= demo_state + 1;

                case (demo_state)
                    3'b000: begin  // Test A register
                        a_write <= 1'b1;
                        demo_data <= 8'h55;
                        demo_opcode <= 8'hA9;  // LDA immediate
                    end

                    3'b001: begin  // Test X register
                        x_write <= 1'b1;
                        demo_data <= 8'hAA;
                        demo_opcode <= 8'hA2;  // LDX immediate
                    end

                    3'b010: begin  // Test Y register
                        y_write <= 1'b1;
                        demo_data <= 8'h33;
                        demo_opcode <= 8'hA0;  // LDY immediate
                    end

                    3'b011: begin  // Test PC
                        pc_write <= 1'b1;
                        demo_addr <= 16'h1234;
                        demo_opcode <= 8'h4C;  // JMP absolute
                    end

                    3'b100: begin  // Test store instruction
                        demo_opcode <= 8'h85;  // STA zero page
                    end

                    3'b101: begin  // Test arithmetic instruction
                        demo_opcode <= 8'h69;  // ADC immediate
                    end

                    3'b110: begin  // Test branch instruction
                        demo_opcode <= 8'h10;  // BPL
                    end

                    3'b111: begin  // Reset to beginning
                        demo_opcode <= 8'hEA;  // NOP
                    end
                endcase
            end

            // Switch-controlled opcodes for manual testing
            if (switches[3]) begin
                case (switches[2:0])
                    3'b000: demo_opcode <= 8'hA9;  // LDA immediate
                    3'b001: demo_opcode <= 8'h85;  // STA zero page
                    3'b010: demo_opcode <= 8'h69;  // ADC immediate
                    3'b011: demo_opcode <= 8'h10;  // BPL
                    3'b100: demo_opcode <= 8'hAA;  // TAX
                    3'b101: demo_opcode <= 8'h4C;  // JMP absolute
                    3'b110: demo_opcode <= 8'hC9;  // CMP immediate
                    3'b111: demo_opcode <= 8'hEA;  // NOP
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
