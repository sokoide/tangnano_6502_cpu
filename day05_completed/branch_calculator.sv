// Branch Target Calculator
// Calculate branch target addresses for relative branching

module branch_calculator (
    input  logic [7:0]  branch_offset,  // Signed 8-bit offset
    input  logic [15:0] pc,             // Current PC
    input  logic [7:0]  status_reg,     // Processor status register
    input  logic [7:0]  opcode,         // Branch instruction opcode

    output logic [15:0] branch_target,
    output logic        branch_taken,
    output logic        page_crossed
);

    logic [15:0] signed_offset;
    logic [15:0] next_pc;
    logic branch_condition;

    // Calculate next PC (PC + 2 for branch instructions)
    assign next_pc = pc + 2;

    // Sign extend 8-bit offset to 16-bit
    always_comb begin
        if (branch_offset[7]) begin
            signed_offset = {8'hFF, branch_offset};  // Negative offset
        end else begin
            signed_offset = {8'h00, branch_offset};  // Positive offset
        end

        branch_target = next_pc + signed_offset;
    end

    // Branch condition evaluation
    always_comb begin
        case (opcode)
            8'h10: branch_condition = ~status_reg[7];  // BPL - Branch if Plus (N=0)
            8'h30: branch_condition = status_reg[7];   // BMI - Branch if Minus (N=1)
            8'h50: branch_condition = ~status_reg[6];  // BVC - Branch if Overflow Clear (V=0)
            8'h70: branch_condition = status_reg[6];   // BVS - Branch if Overflow Set (V=1)
            8'h90: branch_condition = ~status_reg[0];  // BCC - Branch if Carry Clear (C=0)
            8'hB0: branch_condition = status_reg[0];   // BCS - Branch if Carry Set (C=1)
            8'hD0: branch_condition = ~status_reg[1];  // BNE - Branch if Not Equal (Z=0)
            8'hF0: branch_condition = status_reg[1];   // BEQ - Branch if Equal (Z=1)
            default: branch_condition = 1'b0;          // Unknown branch instruction
        endcase

        branch_taken = branch_condition;
    end

    // Page crossing detection (different high byte)
    assign page_crossed = branch_taken && (next_pc[15:8] != branch_target[15:8]);

endmodule