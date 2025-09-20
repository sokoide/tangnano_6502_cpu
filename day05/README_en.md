# Day 05: 6502 Instruction Set and Addressing Modes

---

🌐 Available languages:
[English](./README.md) | [日本語](./README_ja.md)

## 🎯 Learning Objectives

-   Understand the 13 addressing modes of the 6502
-   Learn the classification and operation of major instruction groups
-   Master how to implement effective address calculation
-   Understand actual instruction encoding

## 📚 Theory

### Addressing Mode List

1.  **Implied** - No operand (TAX, RTS)
2.  **Accumulator** - A register operation (ASL A)
3.  **Immediate** - Immediate value (LDA #$80)
4.  **Zero Page** - Zero page (LDA $80)
5.  **Zero Page,X** - Zero page + X (LDA $80,X)
6.  **Zero Page,Y** - Zero page + Y (LDX $80,Y)
7.  **Absolute** - Absolute address (LDA $1234)
8.  **Absolute,X** - Absolute + X (LDA $1234,X)
9.  **Absolute,Y** - Absolute + Y (LDA $1234,Y)
10. **Indirect** - Indirect (JMP ($1234))
11. **Indexed Indirect** - (zp,X) (LDA ($80,X))
12. **Indirect Indexed** - (zp),Y (LDA ($80),Y)
13. **Relative** - Relative branch (BEQ $80)

### Classification of Major Instructions

**Data Transfer:**

-   LDA, LDX, LDY (Load)
-   STA, STX, STY (Store)
-   TAX, TAY, TXA, TYA, TSX, TXS (Transfer)

**Arithmetic:**

-   ADC, SBC (Add/Subtract)
-   AND, ORA, EOR (Logical operations)
-   ASL, LSR, ROL, ROR (Shift/Rotate)

**Branch/Jump:**

-   BEQ, BNE, BCS, BCC, BMI, BPL, BVS, BVC (Conditional branch)
-   JMP, JSR, RTS (Jump/Subroutine)

## 🛠️ Practice 1: Addressing Mode Calculator

```systemverilog
module addressing_mode_calculator (
    input  logic [7:0]  opcode,
    input  logic [15:0] pc,           // Program counter
    input  logic [7:0]  operand1,     // 1st byte operand
    input  logic [7:0]  operand2,     // 2nd byte operand
    input  logic [7:0]  reg_x,
    input  logic [7:0]  reg_y,

    output logic [15:0] effective_addr,
    output logic [2:0]  addr_mode,
    output logic [1:0]  instruction_length
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

    always_comb begin
        // Default values
        effective_addr = 16'h0000;
        addr_mode = IMMEDIATE;
        instruction_length = 2'd1;

        case (opcode)
            // LDA Immediate - #$nn
            8'hA9: begin
                effective_addr = {8'h00, operand1};
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
                effective_addr = {8'h00, operand1 + reg_x};
                addr_mode = ZERO_PAGE_X;
                instruction_length = 2'd2;
            end

            // LDA Absolute - $nnnn
            8'hAD: begin
                effective_addr = {operand2, operand1};  // Little-endian
                addr_mode = ABSOLUTE;
                instruction_length = 2'd3;
            end

            // TODO: Implement other addressing modes

            default: begin
                effective_addr = 16'h0000;
                addr_mode = IMMEDIATE;
                instruction_length = 2'd1;
            end
        endcase
    end

endmodule
```

## 🛠️ Practice 2: Extended Instruction Decoder

```systemverilog
module instruction_decoder (
    input  logic [7:0] opcode,

    // Instruction type
    output logic is_load,
    output logic is_store,
    output logic is_arithmetic,
    output logic is_logical,
    output logic is_shift,
    output logic is_branch,
    output logic is_jump,
    output logic is_transfer,

    // Register selection
    output logic use_reg_a,
    output logic use_reg_x,
    output logic use_reg_y,

    // Flag effects
    output logic affects_n,
    output logic affects_z,
    output logic affects_c,
    output logic affects_v
);

    always_comb begin
        // Default values
        {is_load, is_store, is_arithmetic, is_logical} = 4'b0000;
        {is_shift, is_branch, is_jump, is_transfer} = 4'b0000;
        {use_reg_a, use_reg_x, use_reg_y} = 3'b000;
        {affects_n, affects_z, affects_c, affects_v} = 4'b0000;

        case (opcode)
            // LDA instructions
            8'hA9, 8'hA5, 8'hB5, 8'hAD, 8'hBD, 8'hB9, 8'hA1, 8'hB1: begin
                is_load = 1'b1;
                use_reg_a = 1'b1;
                affects_n = 1'b1;
                affects_z = 1'b1;
            end

            // ADC instructions
            8'h69, 8'h65, 8'h75, 8'h6D, 8'h7D, 8'h79, 8'h61, 8'h71: begin
                is_arithmetic = 1'b1;
                use_reg_a = 1'b1;
                affects_n = 1'b1;
                affects_z = 1'b1;
                affects_c = 1'b1;
                affects_v = 1'b1;
            end

            // TAX
            8'hAA: begin
                is_transfer = 1'b1;
                use_reg_a = 1'b1;
                use_reg_x = 1'b1;
                affects_n = 1'b1;
                affects_z = 1'b1;
            end

            // TODO: Implement other instructions

            default: begin
                // Unknown instruction
            end
        endcase
    end

endmodule
```

## 🛠️ Practice 3: Branch Calculator

```systemverilog
module branch_calculator (
    input  logic [7:0]  branch_offset,  // Signed 8-bit
    input  logic [15:0] pc,             // Current PC
    output logic [15:0] branch_target
);

    logic [15:0] signed_offset;

    always_comb begin
        // Sign-extend 8-bit to 16-bit
        if (branch_offset[7]) begin
            signed_offset = {8'hFF, branch_offset};  // Negative number
        end else begin
            signed_offset = {8'h00, branch_offset};  // Positive number
        end

        branch_target = pc + signed_offset;
    end

endmodule
```

## 📝 Assignments

### Basic Assignments

1.  Implement all addressing modes
2.  Complete decoder for major instructions
3.  Create test cases for branch instructions

### Advanced Assignments

1.  Instruction cycle count calculator
2.  Detection of page boundary crossing
3.  Illegal instruction detection function

## 📚 Important Implementation Points

### Little-Endian

The 6502 stores 16-bit addresses in little-endian format:

```
Address $1234 is stored in memory as [34] [12]
```

### Page Boundary Crossing

Some addressing modes require an extra cycle if a page boundary is crossed:

-   Absolute,X / Absolute,Y
-   (zp),Y

### Branch Calculation

Relative branches are a signed offset from the current PC:

-   Positive value: Forward branch
-   Negative value: Backward branch
-   Range: -128 to +127

## 📚 What I Learned Today

-   [ ] 13 types of addressing modes
-   [ ] Classification and features of instructions
-   [ ] How to calculate effective addresses
-   [ ] Handling of little-endian
-   [ ] Implementation of branch calculation

## 🎯 Preview for Tomorrow

In Day 06, as the first stage of CPU implementation, we will implement the decoder and ALU in detail:

-   Complete instruction decoder
-   ALU design and implementation
-   Flag generation logic
