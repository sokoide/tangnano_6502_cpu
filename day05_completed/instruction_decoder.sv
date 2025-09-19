// Extended 6502 Instruction Decoder
// Complete instruction decoding with register and flag control

module instruction_decoder (
    input  logic [7:0] opcode,

    // Instruction type outputs
    output logic is_load,
    output logic is_store,
    output logic is_arithmetic,
    output logic is_logical,
    output logic is_shift,
    output logic is_branch,
    output logic is_jump,
    output logic is_transfer,
    output logic is_compare,
    output logic is_flag,
    output logic is_stack,

    // Register usage
    output logic use_reg_a,
    output logic use_reg_x,
    output logic use_reg_y,

    // Flag effects
    output logic affects_n,
    output logic affects_z,
    output logic affects_c,
    output logic affects_v,

    // Memory access
    output logic mem_read,
    output logic mem_write
);

    always_comb begin
        // Default all outputs
        {is_load, is_store, is_arithmetic, is_logical} = 4'b0000;
        {is_shift, is_branch, is_jump, is_transfer} = 4'b0000;
        {is_compare, is_flag, is_stack} = 3'b000;
        {use_reg_a, use_reg_x, use_reg_y} = 3'b000;
        {affects_n, affects_z, affects_c, affects_v} = 4'b0000;
        {mem_read, mem_write} = 2'b00;

        case (opcode)
            // LDA instructions
            8'hA9, 8'hA5, 8'hB5, 8'hAD, 8'hBD, 8'hB9, 8'hA1, 8'hB1: begin
                is_load = 1'b1;
                use_reg_a = 1'b1;
                affects_n = 1'b1;
                affects_z = 1'b1;
                mem_read = 1'b1;
            end

            // LDX instructions
            8'hA2, 8'hA6, 8'hB6, 8'hAE, 8'hBE: begin
                is_load = 1'b1;
                use_reg_x = 1'b1;
                affects_n = 1'b1;
                affects_z = 1'b1;
                mem_read = 1'b1;
            end

            // LDY instructions
            8'hA0, 8'hA4, 8'hB4, 8'hAC, 8'hBC: begin
                is_load = 1'b1;
                use_reg_y = 1'b1;
                affects_n = 1'b1;
                affects_z = 1'b1;
                mem_read = 1'b1;
            end

            // STA instructions
            8'h85, 8'h95, 8'h8D, 8'h9D, 8'h99, 8'h81, 8'h91: begin
                is_store = 1'b1;
                use_reg_a = 1'b1;
                mem_write = 1'b1;
            end

            // STX instructions
            8'h86, 8'h96, 8'h8E: begin
                is_store = 1'b1;
                use_reg_x = 1'b1;
                mem_write = 1'b1;
            end

            // STY instructions
            8'h84, 8'h94, 8'h8C: begin
                is_store = 1'b1;
                use_reg_y = 1'b1;
                mem_write = 1'b1;
            end

            // ADC instructions
            8'h69, 8'h65, 8'h75, 8'h6D, 8'h7D, 8'h79, 8'h61, 8'h71: begin
                is_arithmetic = 1'b1;
                use_reg_a = 1'b1;
                affects_n = 1'b1;
                affects_z = 1'b1;
                affects_c = 1'b1;
                affects_v = 1'b1;
                mem_read = 1'b1;
            end

            // SBC instructions
            8'hE9, 8'hE5, 8'hF5, 8'hED, 8'hFD, 8'hF9, 8'hE1, 8'hF1: begin
                is_arithmetic = 1'b1;
                use_reg_a = 1'b1;
                affects_n = 1'b1;
                affects_z = 1'b1;
                affects_c = 1'b1;
                affects_v = 1'b1;
                mem_read = 1'b1;
            end

            // AND instructions
            8'h29, 8'h25, 8'h35, 8'h2D, 8'h3D, 8'h39, 8'h21, 8'h31: begin
                is_logical = 1'b1;
                use_reg_a = 1'b1;
                affects_n = 1'b1;
                affects_z = 1'b1;
                mem_read = 1'b1;
            end

            // ORA instructions
            8'h09, 8'h05, 8'h15, 8'h0D, 8'h1D, 8'h19, 8'h01, 8'h11: begin
                is_logical = 1'b1;
                use_reg_a = 1'b1;
                affects_n = 1'b1;
                affects_z = 1'b1;
                mem_read = 1'b1;
            end

            // EOR instructions
            8'h49, 8'h45, 8'h55, 8'h4D, 8'h5D, 8'h59, 8'h41, 8'h51: begin
                is_logical = 1'b1;
                use_reg_a = 1'b1;
                affects_n = 1'b1;
                affects_z = 1'b1;
                mem_read = 1'b1;
            end

            // Transfer instructions
            8'hAA: begin  // TAX
                is_transfer = 1'b1;
                use_reg_a = 1'b1;
                use_reg_x = 1'b1;
                affects_n = 1'b1;
                affects_z = 1'b1;
            end

            8'hA8: begin  // TAY
                is_transfer = 1'b1;
                use_reg_a = 1'b1;
                use_reg_y = 1'b1;
                affects_n = 1'b1;
                affects_z = 1'b1;
            end

            8'h8A: begin  // TXA
                is_transfer = 1'b1;
                use_reg_x = 1'b1;
                use_reg_a = 1'b1;
                affects_n = 1'b1;
                affects_z = 1'b1;
            end

            8'h98: begin  // TYA
                is_transfer = 1'b1;
                use_reg_y = 1'b1;
                use_reg_a = 1'b1;
                affects_n = 1'b1;
                affects_z = 1'b1;
            end

            // Branch instructions
            8'h10, 8'h30, 8'h50, 8'h70, 8'h90, 8'hB0, 8'hD0, 8'hF0: begin
                is_branch = 1'b1;
                mem_read = 1'b1;  // Read offset
            end

            // Jump instructions
            8'h4C, 8'h6C: begin  // JMP
                is_jump = 1'b1;
                mem_read = 1'b1;
            end

            8'h20: begin  // JSR
                is_jump = 1'b1;
                mem_read = 1'b1;
                mem_write = 1'b1;  // Stack operations
            end

            8'h60: begin  // RTS
                is_jump = 1'b1;
                mem_read = 1'b1;   // Stack operations
            end

            // Compare instructions
            8'hC9, 8'hC5, 8'hD5, 8'hCD, 8'hDD, 8'hD9, 8'hC1, 8'hD1: begin // CMP
                is_compare = 1'b1;
                use_reg_a = 1'b1;
                affects_n = 1'b1;
                affects_z = 1'b1;
                affects_c = 1'b1;
                mem_read = 1'b1;
            end

            8'hE0, 8'hE4, 8'hEC: begin  // CPX
                is_compare = 1'b1;
                use_reg_x = 1'b1;
                affects_n = 1'b1;
                affects_z = 1'b1;
                affects_c = 1'b1;
                mem_read = 1'b1;
            end

            8'hC0, 8'hC4, 8'hCC: begin  // CPY
                is_compare = 1'b1;
                use_reg_y = 1'b1;
                affects_n = 1'b1;
                affects_z = 1'b1;
                affects_c = 1'b1;
                mem_read = 1'b1;
            end

            // Flag instructions
            8'h18: begin  // CLC
                is_flag = 1'b1;
                affects_c = 1'b1;
            end

            8'h38: begin  // SEC
                is_flag = 1'b1;
                affects_c = 1'b1;
            end

            // Stack instructions
            8'h48: begin  // PHA
                is_stack = 1'b1;
                use_reg_a = 1'b1;
                mem_write = 1'b1;
            end

            8'h68: begin  // PLA
                is_stack = 1'b1;
                use_reg_a = 1'b1;
                affects_n = 1'b1;
                affects_z = 1'b1;
                mem_read = 1'b1;
            end

            default: begin
                // NOP or undefined - no operation
            end
        endcase
    end

endmodule