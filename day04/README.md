# Day 04: 6502 CPU Architecture Overview

---

🌐 Available languages:
[English](./README.md) | [日本語](./README_ja.md)

## 🎯 Learning Objectives

-   Understand the history and features of the 6502 CPU
-   Learn the register set and their roles
-   Understand the basics of memory maps and addressing
-   Grasp the flow of the instruction execution cycle

## 📚 Theory

### History of the 6502 CPU

**Development Background:**

-   Developed by MOS Technology in 1975
-   Innovatively low price for its time ($25)
-   Used in the Apple II, Commodore 64, NES, etc.
-   Simple design, also ideal for educational purposes

### Register Set

**8-bit Registers:**

-   **A (Accumulator)**: The main player in arithmetic operations, used by many instructions
-   **X, Y (Index)**: For indexing in addressing
-   **SP (Stack Pointer)**: Points to the stack location (0x0100-0x01FF)

**16-bit Register:**

-   **PC (Program Counter)**: The address of the next instruction to be executed

**1-bit Flags (P Register):**

-   **N (Negative)**: Set when the result is negative
-   **V (Overflow)**: Set on signed overflow
-   **B (Break)**: Set when a BRK instruction is executed
-   **D (Decimal)**: BCD arithmetic mode (usually unused)
-   **I (Interrupt)**: Interrupt disable flag
-   **Z (Zero)**: Set when the result is zero
-   **C (Carry)**: Set on carry/borrow

### Memory Map Basics

```
0x0000-0x00FF : Zero Page (high-speed access area)
0x0100-0x01FF : Stack (stack area)
0x0200-0x7FFF : General RAM
0x8000-0xFFFF : Program ROM (usually)
```

## 🛠️ Practice 1: 6502 Register Set

### Implementation in SystemVerilog

```systemverilog
module cpu_registers (
    input  logic clk,
    input  logic rst_n,

    // Register control
    input  logic a_write,
    input  logic x_write,
    input  logic y_write,
    input  logic sp_write,
    input  logic pc_write,
    input  logic p_write,

    // Data bus
    input  logic [7:0]  data_in,
    input  logic [15:0] addr_in,

    // Register output
    output logic [7:0]  reg_a,
    output logic [7:0]  reg_x,
    output logic [7:0]  reg_y,
    output logic [7:0]  reg_sp,
    output logic [15:0] reg_pc,
    output logic [7:0]  reg_p
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_a  <= 8'h00;
            reg_x  <= 8'h00;
            reg_y  <= 8'h00;
            reg_sp <= 8'hFF;  // Stack starts from the top
            reg_pc <= 16'h0200;  // Program start address
            reg_p  <= 8'h20;     // Start with interrupts disabled
        end else begin
            if (a_write)  reg_a  <= data_in;
            if (x_write)  reg_x  <= data_in;
            if (y_write)  reg_y  <= data_in;
            if (sp_write) reg_sp <= data_in;
            if (pc_write) reg_pc <= addr_in;
            if (p_write)  reg_p  <= data_in;
        end
    end

endmodule
```

## 🛠️ Practice 2: Simple Instruction Decoder

### Basic Instruction Classification

```systemverilog
module simple_decoder (
    input  logic [7:0] opcode,
    output logic is_load,      // LDA, LDX, LDY
    output logic is_store,     // STA, STX, STY
    output logic is_transfer,  // TAX, TAY, TXA, etc.
    output logic is_arithmetic // ADC, SBC
);

    always_comb begin
        // Default values
        is_load = 1'b0;
        is_store = 1'b0;
        is_transfer = 1'b0;
        is_arithmetic = 1'b0;

        case (opcode)
            // LDA instructions
            8'hA9, 8'hA5, 8'hB5, 8'hAD, 8'hBD, 8'hB9, 8'hA1, 8'hB1:
                is_load = 1'b1;

            // STA instructions
            8'h85, 8'h95, 8'h8D, 8'h9D, 8'h99, 8'h81, 8'h91:
                is_store = 1'b1;

            // TODO: Implement other instruction groups

            default: begin
                // Unknown instruction
            end
        endcase
    end

endmodule
```

## 🛠️ Practice 3: Flag Calculation Logic

### Implementation of N and Z Flags

```systemverilog
module flag_calculator (
    input  logic [7:0] result,
    input  logic [7:0] operand_a,
    input  logic [7:0] operand_b,
    input  logic       operation,  // 0:ADD, 1:SUB

    output logic flag_n,  // Negative
    output logic flag_z,  // Zero
    output logic flag_c,  // Carry
    output logic flag_v   // Overflow
);

    logic [8:0] temp_result;

    always_comb begin
        // Calculate with 9 bits to detect carry
        if (operation) begin
            temp_result = {1'b0, operand_a} - {1'b0, operand_b};
        end else begin
            temp_result = {1'b0, operand_a} + {1'b0, operand_b};
        end

        // Flag calculation
        flag_n = result[7];              // Most significant bit
        flag_z = (result == 8'h00);      // Zero check
        flag_c = temp_result[8];         // Carry

        // Overflow check (signed arithmetic)
        flag_v = (operand_a[7] == operand_b[7]) &&
                 (operand_a[7] != result[7]);
    end

endmodule
```

## 📝 Assignments

### Basic Assignments

1.  Testbench to verify the operation of all registers
2.  Extend the classification function for major instructions
3.  Implement calculation logic for all flags

### Advanced Assignments

1.  Addressing mode detector
2.  Instruction length calculator
3.  Stack operation simulator

## 📚 Important Points

### Features of the 6502

-   **Simple Design**: No complex instructions
-   **Memory-Mapped I/O**: No special I/O instructions needed
-   **Zero Page**: The first 256 bytes, which can be accessed quickly
-   **Fixed Stack**: Fixed at 0x0100-0x01FF

### Architectural Advantages

-   **Educational Value**: Easy-to-understand structure
-   **Implementation Cost**: Low number of transistors
-   **Programmability**: Intuitive instruction set

## 📚 What I Learned Today

-   [ ] History and features of the 6502 CPU
-   [ ] Register set and their roles
-   [ ] Basics of the memory map
-   [ ] How to classify instructions
-   [ ] How flag calculation works

## 🎯 Preview for Tomorrow

In Day 05, we will learn in detail about the 6502 instruction set and addressing modes:

-   13 types of addressing modes
-   Operation of major instructions
-   Effective address calculation
