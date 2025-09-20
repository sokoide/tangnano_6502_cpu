# Day 05 Completed: 6502 Instruction Set and Addressing Modes

This is the implementation of the 13 addressing modes of the 6502 and a complete instruction decode.

---

🌐 Available languages:
[English](./README.md) | [日本語](./README_ja.md)

## File Structure

-   `addressing_mode_calculator.sv` - Addressing mode calculator
-   `instruction_decoder.sv` - Extended instruction decoder
-   `branch_calculator.sv` - Branch calculator
-   `top.sv` - Integrated test module
-   `tb_addressing_modes.sv` - Addressing mode testbench
-   `Makefile` - Build and test automation

## Implemented Features

### 1. Addressing Mode Calculator

**Supports 13 addressing modes:**

1.  **Immediate** - `#$nn` (Immediate)
2.  **Zero Page** - `$nn` (Zero Page)
3.  **Zero Page,X** - `$nn,X` (Zero Page+X)
4.  **Zero Page,Y** - `$nn,Y` (Zero Page+Y)
5.  **Absolute** - `$nnnn` (Absolute Address)
6.  **Absolute,X** - `$nnnn,X` (Absolute+X)
7.  **Absolute,Y** - `$nnnn,Y` (Absolute+Y)
8.  **Indirect** - `($nnnn)` (Indirect)
9.  **Indexed Indirect** - `($nn,X)` (Indexed Indirect)
10. **Indirect Indexed** - `($nn),Y` (Indirect Indexed)
11. **Relative** - Relative address for branch instructions
12. **Implied** - No operand
13. **Accumulator** - A register operation

**Functionality:**

-   Effective address calculation
-   Instruction length determination (1-3 bytes)
-   Page boundary crossing detection
-   Little-endian support

### 2. Extended Instruction Decoder

**Instruction Classification:**

-   Load/Store instructions (LDA, STA, LDX, STX, LDY, STY)
-   Arithmetic instructions (ADC, SBC)
-   Logical operations (AND, ORA, EOR)
-   Shift instructions (ASL, LSR, ROL, ROR)
-   Transfer instructions (TAX, TAY, TXA, TYA)
-   Branch instructions (BEQ, BNE, BPL, BMI, etc.)
-   Jump instructions (JMP, JSR, RTS)
-   Compare instructions (CMP, CPX, CPY)
-   Flag instructions (SEC, CLC, etc.)
-   Stack instructions (PHA, PLA, etc.)

**Output Information:**

-   Used register (A, X, Y)
-   Affected flags (N, Z, C, V)
-   Memory access (read/write)

### 3. Branch Calculator

**Branch Instructions:**

-   BPL/BMI (Positive/Negative check)
-   BVC/BVS (Overflow)
-   BCC/BCS (Carry)
-   BNE/BEQ (Zero check)

**Functionality:**

-   Signed 8-bit offset processing
-   Branch condition evaluation
-   Page boundary crossing detection

## How to Build and Test

### Simulation Test

```bash
make test
```

### FPGA Build

```bash
# Tang Nano 9K
make BOARD=9k download

# Tang Nano 20K
make BOARD=20k download
```

## Test Contents

The addressing mode testbench tests the following:

1.  **Immediate Addressing**: `LDA #$55`
2.  **Zero Page**: `LDA $80`
3.  **Zero Page Indexed**: `LDA $80,X`
4.  **Absolute Address**: `LDA $1234`
5.  **Absolute Indexed**: `LDA $1234,X` (including page boundary crossing)
6.  **Branch Instructions**: `BPL +5`, `BNE -5`
7.  **Zero Page Wrap-around**: `LDA $FF,X`

## Hardware Verification

### Inputs

-   `rst_n`: Reset button
-   `switches[3:0]`: Test control
    -   `switches[3]=0`: Automatic demo mode
    -   `switches[3]=1`: Manual selection mode (select instruction with switches[2:0])

### Outputs

-   `debug_addr_low[7:0]`: Lower byte of effective address
-   `debug_addr_high[7:0]`: Upper byte of effective address
-   `debug_addr_mode[2:0]`: Addressing mode number
-   `debug_inst_length[1:0]`: Instruction length
-   `debug_page_crossed`: Page boundary crossing flag
-   `led_load/store/arithmetic/branch`: Instruction type display

### Demo Sequence

Sequentially executes 16 instructions to verify the operation of each addressing mode:

1.  `LDA #$55` (Immediate)
2.  `LDA $80` (Zero Page)
3.  `LDA $80,X` (Zero Page,X)
4.  `LDA $1234` (Absolute)
5.  `LDA $1234,X` (Absolute,X)
6.  `LDA $1234,Y` (Absolute,Y)
7.  `STA $90` (Store)
8.  `ADC #$10` (Arithmetic)
9.  `JMP $3000` (Jump)
10. `BPL +5` (Branch)
11. `TAX` (Transfer)
12. Other complex addressing

## Learning Points

### Features of 6502 Addressing

-   **High Speed of Zero Page**: Fast access with 2-byte instructions
-   **Index Registers**: Array access with X/Y
-   **Indirect Addressing**: Pointer operations
-   **Page Boundary Crossing**: Requires an extra cycle
-   **Little-Endian**: Order of lower byte -> upper byte

### Implementation Techniques

-   Complex address calculation logic
-   Instruction classification with conditional branching
-   Page boundary detection algorithm
-   Comprehensive testbench design

### Debugging Methods

-   Verifying address calculation in real-time
-   Visualization of instruction types
-   Monitoring of page boundary crossing
-   Detailed verification by simulation

## Advanced Assignments

1.  **Complete Implementation of Indirect Addressing**: Implementation including memory reads
2.  **Cycle Count Calculation**: Number of execution cycles for each addressing mode
3.  **Invalid Address Detection**: Detection of invalid address access

With this implementation, you have a complete understanding of the flexible addressing features of the 6502, and the foundation for the next step of CPU implementation is in place.
