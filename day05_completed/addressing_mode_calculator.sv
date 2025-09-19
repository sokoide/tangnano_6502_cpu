// 6502 Addressing Mode Calculator
// Calculate effective addresses for all 6502 addressing modes

module addressing_mode_calculator (
    input  logic [7:0]  opcode,
    input  logic [15:0] pc,           // Program counter
    input  logic [7:0]  operand1,     // First operand byte
    input  logic [7:0]  operand2,     // Second operand byte
    input  logic [7:0]  reg_x,
    input  logic [7:0]  reg_y,

    output logic [15:0] effective_addr,
    output logic [2:0]  addr_mode,
    output logic [1:0]  instruction_length,
    output logic        page_crossed
);

    // Addressing mode definitions
    localparam IMMEDIATE     = 3'b000;
    localparam ZERO_PAGE     = 3'b001;
    localparam ZERO_PAGE_X   = 3'b010;
    localparam ABSOLUTE      = 3'b011;
    localparam ABSOLUTE_X    = 3'b100;
    localparam ABSOLUTE_Y    = 3'b101;
    localparam INDEXED_IND   = 3'b110;
    localparam INDIRECT_IND  = 3'b111;

    logic [15:0] base_addr;
    logic [15:0] indexed_addr;

    always_comb begin
        // Default values
        effective_addr = 16'h0000;
        addr_mode = IMMEDIATE;
        instruction_length = 2'd1;
        page_crossed = 1'b0;

        case (opcode)
            // LDA Immediate - #$nn
            8'hA9: begin
                effective_addr = pc + 1;
                addr_mode = IMMEDIATE;
                instruction_length = 2'd2;
            end

            // LDA Zero Page - $nn
            8'hA5: begin
                effective_addr = {8'h00, operand1};
                addr_mode = ZERO_PAGE;
                instruction_length = 2'd2;
            end

            // LDA Zero Page,X - $nn,X
            8'hB5: begin
                effective_addr = {8'h00, (operand1 + reg_x) & 8'hFF};
                addr_mode = ZERO_PAGE_X;
                instruction_length = 2'd2;
            end

            // LDA Absolute - $nnnn
            8'hAD: begin
                effective_addr = {operand2, operand1};  // Little endian
                addr_mode = ABSOLUTE;
                instruction_length = 2'd3;
            end

            // LDA Absolute,X - $nnnn,X
            8'hBD: begin
                base_addr = {operand2, operand1};
                indexed_addr = base_addr + {8'h00, reg_x};
                effective_addr = indexed_addr;
                addr_mode = ABSOLUTE_X;
                instruction_length = 2'd3;
                page_crossed = (base_addr[15:8] != indexed_addr[15:8]);
            end

            // LDA Absolute,Y - $nnnn,Y
            8'hB9: begin
                base_addr = {operand2, operand1};
                indexed_addr = base_addr + {8'h00, reg_y};
                effective_addr = indexed_addr;
                addr_mode = ABSOLUTE_Y;
                instruction_length = 2'd3;
                page_crossed = (base_addr[15:8] != indexed_addr[15:8]);
            end

            // LDA (Zero Page,X) - ($nn,X)
            8'hA1: begin
                effective_addr = {8'h00, (operand1 + reg_x) & 8'hFF};
                addr_mode = INDEXED_IND;
                instruction_length = 2'd2;
            end

            // LDA (Zero Page),Y - ($nn),Y
            8'hB1: begin
                effective_addr = {8'h00, operand1};
                addr_mode = INDIRECT_IND;
                instruction_length = 2'd2;
                // Note: Page crossing calculation needs indirect address
            end

            // STA Zero Page
            8'h85: begin
                effective_addr = {8'h00, operand1};
                addr_mode = ZERO_PAGE;
                instruction_length = 2'd2;
            end

            // STA Absolute
            8'h8D: begin
                effective_addr = {operand2, operand1};
                addr_mode = ABSOLUTE;
                instruction_length = 2'd3;
            end

            // ADC Immediate
            8'h69: begin
                effective_addr = pc + 1;
                addr_mode = IMMEDIATE;
                instruction_length = 2'd2;
            end

            // ADC Zero Page
            8'h65: begin
                effective_addr = {8'h00, operand1};
                addr_mode = ZERO_PAGE;
                instruction_length = 2'd2;
            end

            // JMP Absolute
            8'h4C: begin
                effective_addr = {operand2, operand1};
                addr_mode = ABSOLUTE;
                instruction_length = 2'd3;
            end

            // JMP Indirect
            8'h6C: begin
                effective_addr = {operand2, operand1};
                addr_mode = ABSOLUTE;  // Address to read from
                instruction_length = 2'd3;
            end

            // Branch instructions (relative addressing)
            8'h10, 8'h30, 8'h50, 8'h70, 8'h90, 8'hB0, 8'hD0, 8'hF0: begin
                // Sign extend 8-bit offset to 16-bit
                if (operand1[7]) begin
                    effective_addr = pc + 2 + {8'hFF, operand1};  // Negative offset
                end else begin
                    effective_addr = pc + 2 + {8'h00, operand1};  // Positive offset
                end
                addr_mode = IMMEDIATE;  // Special case for relative
                instruction_length = 2'd2;
                // Page crossing for branches
                page_crossed = (pc[15:8] != effective_addr[15:8]);
            end

            default: begin
                effective_addr = pc;
                addr_mode = IMMEDIATE;
                instruction_length = 2'd1;
            end
        endcase
    end

endmodule