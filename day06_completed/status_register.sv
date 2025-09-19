// 6502 Status Register Management
// Manages processor status flags with proper 6502 behavior

module status_register (
    input  logic clk,
    input  logic rst_n,

    // Flag update control
    input  logic update_n,
    input  logic update_z,
    input  logic update_c,
    input  logic update_v,

    // New flag values
    input  logic new_n,
    input  logic new_z,
    input  logic new_c,
    input  logic new_v,

    // Special flag control
    input  logic set_i,     // Set interrupt disable
    input  logic clear_i,   // Clear interrupt disable
    input  logic set_d,     // Set decimal mode
    input  logic clear_d,   // Clear decimal mode
    input  logic set_b,     // Set break flag
    input  logic clear_b,   // Clear break flag

    // Manual flag setting (for SEC/CLC instructions)
    input  logic manual_set_c,
    input  logic manual_clear_c,

    // Status register output
    output logic [7:0] status_reg
);

    // Flag bit definitions (NV-BDIZC format)
    // Bit 7: N (Negative)
    // Bit 6: V (Overflow)
    // Bit 5: - (unused, always 1)
    // Bit 4: B (Break)
    // Bit 3: D (Decimal)
    // Bit 2: I (Interrupt)
    // Bit 1: Z (Zero)
    // Bit 0: C (Carry)

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            status_reg <= 8'b00100100;  // I=1, unused=1, others=0
        end else begin
            // Conditional flag updates
            if (update_n) status_reg[7] <= new_n;
            if (update_v) status_reg[6] <= new_v;

            // Bit 5 is always 1 (unused)
            status_reg[5] <= 1'b1;

            // Break flag control
            if (set_b)    status_reg[4] <= 1'b1;
            if (clear_b)  status_reg[4] <= 1'b0;

            // Decimal mode control
            if (set_d)    status_reg[3] <= 1'b1;
            if (clear_d)  status_reg[3] <= 1'b0;

            // Interrupt disable control
            if (set_i)    status_reg[2] <= 1'b1;
            if (clear_i)  status_reg[2] <= 1'b0;

            // Zero flag
            if (update_z) status_reg[1] <= new_z;

            // Carry flag (with manual control for SEC/CLC)
            if (manual_set_c) begin
                status_reg[0] <= 1'b1;
            end else if (manual_clear_c) begin
                status_reg[0] <= 1'b0;
            end else if (update_c) begin
                status_reg[0] <= new_c;
            end
        end
    end

endmodule