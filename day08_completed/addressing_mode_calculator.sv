// 6502 Addressing Mode Calculator (mode-based)
// Calculates effective address from decoded addressing mode + operands.
//
// Note: This version is intentionally simple for educational use.
// Some 6502 modes (indexed-indirect/indirect-indexed) normally require
// extra memory reads to dereference a zero-page pointer; those are not
// modeled here because the calculator has no memory interface.

module addressing_mode_calculator (
    input  logic [2:0]  mode,
    input  logic [7:0]  operand_low,
    input  logic [7:0]  operand_high,
    input  logic [7:0]  reg_x,
    input  logic [7:0]  reg_y,
    input  logic [15:0] pc,

    output logic [15:0] effective_address,
    output logic        page_boundary_crossed
);

    logic [15:0] base_addr;
    logic [15:0] indexed_addr;

    always_comb begin
        effective_address = 16'h0000;
        page_boundary_crossed = 1'b0;

        base_addr = 16'h0000;
        indexed_addr = 16'h0000;

        case (mode)
            3'b000: begin
                // Immediate: operand byte was at (pc-1) because pc has already
                // been incremented past the operand by the fetch/decode stage.
                effective_address = pc - 16'd1;
            end

            3'b001: begin
                // Zero page
                effective_address = {8'h00, operand_low};
            end

            3'b010: begin
                // Zero page,X
                effective_address = {8'h00, operand_low + reg_x};
            end

            3'b011: begin
                // Absolute
                effective_address = {operand_high, operand_low};
            end

            3'b100: begin
                // Absolute,X
                base_addr = {operand_high, operand_low};
                indexed_addr = base_addr + {8'h00, reg_x};
                effective_address = indexed_addr;
                page_boundary_crossed = (indexed_addr[15:8] != base_addr[15:8]);
            end

            3'b101: begin
                // Absolute,Y
                base_addr = {operand_high, operand_low};
                indexed_addr = base_addr + {8'h00, reg_y};
                effective_address = indexed_addr;
                page_boundary_crossed = (indexed_addr[15:8] != base_addr[15:8]);
            end

            3'b110: begin
                // Indexed-indirect ( ($nn,X) ) would dereference a ZP pointer.
                // Here: treat as a simple ZP,X address for demo purposes.
                effective_address = {8'h00, operand_low + reg_x};
            end

            3'b111: begin
                // Indirect-indexed ( ($nn),Y ) would dereference a ZP pointer.
                // Here: treat as a simple ZP base + Y for demo purposes.
                effective_address = {8'h00, operand_low} + {8'h00, reg_y};
            end

            default: begin
                effective_address = 16'h0000;
                page_boundary_crossed = 1'b0;
            end
        endcase
    end

endmodule

