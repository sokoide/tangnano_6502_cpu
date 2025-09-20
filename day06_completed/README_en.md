# Day 06: CPU Decoder and ALU

---

🌐 Available languages:
[English](./README.md) | [日本語](./README_ja.md)

## Learning Objectives

In Day 06, we will implement the core of the 6502 CPU: the instruction decoder and the ALU (Arithmetic Logic Unit). We will use the components created so far to build a system that can interpret and execute actual 6502 instructions.

### What You Will Learn Today

1.  **Instruction Decoder Design**

    -   Analysis of the 6502 instruction set
    -   Generating control signals from opcodes
    -   Determining the addressing mode

2.  **ALU Implementation**

    -   Arithmetic operations (ADD, SUB)
    -   Logical operations (AND, OR, XOR)
    -   Shift and rotate operations
    -   Flag generation (N, Z, C, V)

3.  **Status Register Management**

    -   Accurate implementation of the 6502 flags
    -   Flag update control for each instruction
    -   Implementation of the NV-BDIZC format

4.  **System Integration**
    -   Coordination of the decoder, ALU, and status register
    -   Execution of actual 6502 instructions
    -   Debugging and testing

## Implementation Details

### 1. CPU Decoder (`cpu_decoder.sv`)

A complete decoder for 6502 instructions:

```systemverilog
// Major instruction groups
// - Load/Store: LDA, LDX, LDY, STA, STX, STY
// - Arithmetic: ADC, SBC
// - Logical: AND, OR, EOR
// - Transfer: TAX, TAY, TXA, TYA
// - Shift: ASL, LSR, ROL, ROR
// - Compare: CMP, CPX, CPY
// - Branch: BCC, BCS, BEQ, BNE, etc.
// - Jump: JMP, JSR, RTS
// - Stack: PHA, PLA, PHP, PLP
// - Flag: SEC, CLC, SEI, CLI, etc.
```

**Control Signal Generation**:

-   ALU operation selection (alu_op[3:0])
-   Register write control
-   Memory access control
-   Flag update control
-   Datapath selection

### 2. CPU ALU (`cpu_alu.sv`)

A complete 6502-compatible ALU:

#### Arithmetic Operations

```systemverilog
ALU_ADD: ADC instruction (add with carry)
ALU_SUB: SBC instruction (subtract with borrow)
```

#### Logical Operations

```systemverilog
ALU_AND: AND instruction
ALU_OR:  ORA instruction
ALU_XOR: EOR instruction
```

#### Shift/Rotate

```systemverilog
ALU_ASL: Arithmetic shift left
ALU_LSR: Logical shift right
ALU_ROL: Rotate left (through carry)
ALU_ROR: Rotate right (through carry)
```

#### Others

```systemverilog
ALU_INC: Increment (does not affect carry)
ALU_DEC: Decrement (does not affect carry)
ALU_CMP: Compare (only uses flags from the subtraction result)
```

### 3. Status Register (`status_register.sv`)

6502 Status Register (NV-BDIZC):

| Bit | Flag | Name      | Function                               |
| --- | ---- | --------- | -------------------------------------- |
| 7   | N    | Negative  | Most significant bit of the result     |
| 6   | V    | Overflow  | Overflow in signed arithmetic          |
| 5   | -    | Unused    | Always 1                               |
| 4   | B    | Break     | Set when a BRK instruction is executed |
| 3   | D    | Decimal   | BCD arithmetic mode                    |
| 2   | I    | Interrupt | Interrupt disable                      |
| 1   | Z    | Zero      | Result is zero                         |
| 0   | C    | Carry     | Carry/borrow                           |

**Features**:

-   Appropriate flag updates for each instruction
-   Manual control with SEC/CLC instructions
-   Referenced in conditional branches

### 4. Integration Test (`top.sv`)

Integrated test system:

-   Verifies the coordination of each component
-   Executes a sequence of actual 6502 instructions
-   Verifies operation with debug outputs

## 6502 Instruction Set Implementation

### Load/Store Instructions

```systemverilog
LDA #$42    // A = $42, N=0, Z=0
LDA $80     // A = memory[$80]
STA $90     // memory[$90] = A
```

### Arithmetic Instructions

```systemverilog
CLC         // C = 0
ADC #$10    // A = A + $10 + C
SEC         // C = 1
SBC #$05    // A = A - $05 - (1-C)
```

### Logical Instructions

```systemverilog
AND #$F0    // A = A & $F0
ORA #$0F    // A = A | $0F
EOR #$FF    // A = A ^ $FF
```

### Shift Instructions

```systemverilog
ASL A       // A = A << 1, C = old A[7]
LSR A       // A = A >> 1, C = old A[0]
```

### Compare Instructions

```systemverilog
CMP #$42    // Set flags: A - $42
CPX #$10    // Set flags: X - $10
```

### Register Transfer

```systemverilog
TAX         // X = A, N=A[7], Z=(A==0)
TXA         // A = X, N=X[7], Z=(X==0)
```

## Build and Execute

### Required Files

```
day06_completed/
├── cpu_decoder.sv           # Instruction decoder
├── cpu_alu.sv              # Arithmetic logic unit
├── status_register.sv      # Status register
├── top.sv                  # Integrated test system
├── tb_cpu_alu.sv          # ALU testbench
├── Makefile               # Build system
└── README_ja.md           # This document

Dependent files:
└── day05_completed/addressing_mode_calculator.sv
```

### Build Commands

```bash
# Build for Tang Nano 9K
make tang_nano_9k

# Build for Tang Nano 20K
make tang_nano_20k

# Run ALU simulation
make run_sim

# Write to FPGA
make program_9k    # Tang Nano 9K
make program_20k   # Tang Nano 20K
```

### Run Tests

```bash
# ALU unit test
make run_sim

# Integrated system test
# Verify operation with LEDs and switches on the Tang Nano
```

## Debug Outputs

Signals that can be monitored on the Tang Nano pins:

### ALU State

-   `debug_alu_result[7:0]` - ALU operation result
-   `debug_alu_carry` - Carry output
-   `debug_alu_zero` - Zero flag
-   `debug_alu_negative` - Negative flag
-   `debug_alu_overflow` - Overflow flag

### Decoder State

-   `debug_alu_op[3:0]` - ALU operation code
-   `debug_reg_a_write` - A register write
-   `debug_mem_read` - Memory read
-   `debug_mem_write` - Memory write

### System State

-   `debug_opcode[7:0]` - Current instruction code
-   `debug_inst_length[1:0]` - Instruction length

## Example Test Programs

### Basic Arithmetic Test

```assembly
LDA #$50    ; A = $50 (80 decimal)
ADC #$30    ; A = $50 + $30 = $80
            ; N=1 (result is negative), V=1 (overflow)

LDA #$FF    ; A = $FF
ADC #$01    ; A = $FF + $01 = $00
            ; Z=1 (result is zero), C=1 (carry occurred)
```

### Logical Operation Test

```assembly
LDA #$F0    ; A = $F0 (11110000)
AND #$0F    ; A = $F0 & $0F = $00
            ; Z=1 (result is zero)

LDA #$AA    ; A = $AA (10101010)
EOR #$55    ; A = $AA ^ $55 = $FF
            ; N=1 (result is negative)
```

### Shift Operation Test

```assembly
LDA #$81    ; A = $81 (10000001)
ASL A       ; A = $02 (00000010), C=1
            ; Most significant bit goes to carry

LDA #$81    ; A = $81 (10000001)
LSR A       ; A = $40 (01000000), C=1
            ; Least significant bit goes to carry
```

## Learning Points

### Instruction Decoding

1.  **Opcode Analysis**:

    -   Identify instruction from 8-bit opcode
    -   Determine addressing mode
    -   Determine immediate/memory access

2.  **Control Signal Generation**:
    -   ALU operation selection
    -   Datapath control
    -   Memory access control

### ALU Design

1.  **Operation Implementation**:

    -   Parallel operations in a combinational circuit
    -   Consideration of carry propagation
    -   Overflow detection logic

2.  **Flag Generation**:
    -   Flag update rules for each operation
    -   6502-specific behavior (INC/DEC do not affect carry)

### System Integration

1.  **Inter-Module Coordination**:

    -   Decoder -> ALU -> Status
    -   Appropriate timing control
    -   Ensuring debuggability

2.  **On-Device Verification**:
    -   Verifying operation on the Tang Nano
    -   Status display with LEDs
    -   Control with switches

## Troubleshooting

### Common Issues

1.  **Flags are not set correctly**

    -   Check the flag generation logic of the ALU
    -   Check the update control of the status register
    -   Check the flag update rules for each instruction

2.  **Operation result is not as expected**

    -   Check the operation logic within the ALU
    -   Check the setting of the carry input
    -   Check the operand selection

3.  **Instruction is not decoded correctly**
    -   Check the opcode pattern matching
    -   Check the completeness of the `case` statement
    -   Check the appropriateness of the default behavior

### Debugging Methods

1.  **Utilize Simulation**:

    ```bash
    make run_sim
    # Detailed verification in the testbench
    ```

2.  **Step-by-Step Testing**:

    -   ALU unit test
    -   Decoder unit test
    -   Integration test

3.  **On-Device Verification**:
    -   Status verification with LEDs
    -   Manual control with switches

## Advanced Assignments

### Feature Extensions

1.  **Add Instructions**:

    -   Add unimplemented instructions
    -   Extended instruction set

2.  **Optimization**:

    -   Timing improvement
    -   Resource efficiency

3.  **Debug Features**:
    -   Breakpoints
    -   Step execution

### Next Steps

In Day 07, we will implement the memory interface and stack operations, moving towards a complete CPU system.

## Reference Materials

-   6502 Instruction Set Reference
-   6502 Status Register Specification
-   SystemVerilog ALU Design Patterns
-   CPU Architecture Design Principles
