# Day 08: Integrated 6502 CPU Core

---

🌐 Available languages:
[English](./README.md) | [日本語](./README_ja.md)

## Learning Objectives

In Day 08, we will integrate all the components created so far to implement a fully functional 6502 CPU core.

### What You Will Learn Today

1.  **CPU Architecture Integration**

    -   Datapath design
    -   Control unit implementation
    -   Register file management

2.  **Instruction Execution Pipeline**

    -   FETCH -> DECODE -> EXECUTE -> MEMORY -> WRITEBACK
    -   State machine control
    -   Appropriate timing control

3.  **Memory Interface Integration**

    -   Connecting the CPU and memory system
    -   Bus arbitration and timing
    -   Debugging and monitoring

4.  **Executing a Real 6502 Program**
    -   Test ROM program
    -   Verifying the operation of the instruction set
    -   Performance optimization

## Implementation Details

### 1. CPU Core (`cpu_core.sv`)

A complete 6502 CPU core:

```systemverilog
// Major components
// - cpu_datapath: ALU, registers, multiplexers
// - cpu_control_unit: Instruction decoding and execution control
// - status_register: Processor status management
```

### 2. CPU Datapath (`cpu_datapath.sv`)

Data flow control:

-   ALU input selection (A/X/Y/memory)
-   Register data source selection
-   Integration of ALU and register file

### 3. Control Unit (`cpu_control_unit.sv`)

Instruction execution control:

-   5-state machine implementation
-   Addressing mode control
-   Memory access arbitration

### 4. Register File (`cpu_registers.sv`)

6502 register set:

-   A, X, Y registers
-   Program Counter (PC)
-   Stack Pointer (SP)

### 5. Test ROM (`test_rom.sv`)

A comprehensive test program:

-   Basic load/store operations
-   Arithmetic and logical operations
-   Register transfers
-   Stack operations
-   Branches and jumps
-   Subroutine calls

## CPU States

### Execution Cycle

1.  **FETCH**: Fetch instruction from the PC location
2.  **DECODE**: Read operands (if necessary)
3.  **EXECUTE**: Calculate effective address, generate control signals
4.  **MEMORY**: Execute memory access
5.  **WRITEBACK**: Write the result back to a register

### Clock Control

CPU clock speed controllable by switches:

-   `00`: Lowest speed (1.69MHz) - for debugging
-   `01`: Low speed (3.375MHz) - for observation
-   `10`: Medium speed (6.75MHz) - normal operation
-   `11`: Highest speed (27MHz) - full performance

## Test Program

A comprehensive test sequence stored in ROM:

### Basic Tests

1.  **Load/Store**: `LDA #$42`, `STA $80`
2.  **Arithmetic**: `ADC`, `SBC` operations
3.  **Logical**: `AND`, `OR`, `EOR` operations
4.  **Shift**: `ASL`, `LSR` operations

### Advanced Tests

5.  **Compare**: `CMP` instruction and flag setting
6.  **Register Transfer**: `TAX`, `TAY`, `TXA`, `TYA`
7.  **Stack**: `PHA`, `PLA` operations
8.  **Control Flow**: `JMP`, `JSR`, `RTS`

### Practical Tests

9.  **Loop**: Implementation of a loop with a counter
10. **I/O**: Reading switches
11. **Memory Test**: Pattern writing/reading

## Build and Execute

### Required Files

```
day08_completed/
├── cpu_core.sv              # Main CPU core
├── cpu_datapath.sv          # Datapath
├── cpu_control_unit.sv      # Control unit
├── cpu_registers.sv         # Register file
├── test_rom.sv              # Test program ROM
├── top.sv                   # Integrated system
├── tb_cpu_core.sv           # Testbench
├── Makefile                 # Build system
└── README_ja.md             # This document

Dependent files:
├── day05_completed/addressing_mode_calculator.sv
├── day06_completed/cpu_alu.sv
├── day06_completed/cpu_decoder.sv
├── day06_completed/status_register.sv
└── day07_completed/memory_*.sv
```

### Build Commands

```bash
# Build for Tang Nano 9K
make tang_nano_9k

# Build for Tang Nano 20K
make tang_nano_20k

# Run simulation
make run_sim

# Write to FPGA
make program_9k    # Tang Nano 9K
make program_20k   # Tang Nano 20K
```

## Debug Outputs

CPU states that can be monitored on the Tang Nano pins:

### Register State

-   `debug_reg_a[7:0]` - Accumulator
-   `debug_reg_x[7:0]` - X register
-   `debug_reg_y[7:0]` - Y register
-   `debug_reg_sp[7:0]` - Stack pointer
-   `debug_reg_pc[15:0]` - Program counter
-   `debug_status_reg[7:0]` - Status register

### Execution State

-   `debug_opcode[7:0]` - Current instruction
-   `debug_cpu_state[2:0]` - CPU state
-   `debug_mem_addr[15:0]` - Memory address
-   `debug_mem_data[7:0]` - Memory data

## Execution Example

### CPU State After Initialization

```
PC=$C000: Program start
A=$00 X=$00 Y=$00 SP=$FF: Initial register values
Status=$24: I=1, unused=1, others=0
```

### Test Program Execution

```
PC=$C000: LDA #$42    → A=$42
PC=$C002: STA $80     → [$0080]=$42
PC=$C004: LDA #$84    → A=$84
PC=$C006: STA $81     → [$0081]=$84
PC=$C008: LDA $80     → A=$42
PC=$C00A: CLC         → Status=$20 (C=0)
PC=$C00B: ADC $81     → A=$C6, Status=$A0 (N=1)
```

## Learning Points

### Architecture Integration

1.  **Modular Design**: Independence of each component
2.  **Interface Standardization**: Consistent signal naming
3.  **Hierarchical Structure**: Top-down design
4.  **Reusability**: Utilizing components from previous days

### Execution Control

1.  **State Machine**: Clear state transitions
2.  **Timing Control**: Appropriate clock management
3.  **Error Handling**: Detection of illegal states
4.  **Debuggability**: Visualization of internal states

### Performance

1.  **Clock Efficiency**: Execution with the minimum number of cycles
2.  **Memory Efficiency**: Appropriate memory access patterns
3.  **Resource Efficiency**: Optimal use of FPGA resources

## Troubleshooting

### Common Issues

1.  **CPU does not run**

    -   Check the reset signal
    -   Check the clock supply
    -   Check the initial PC value ($C000)

2.  **Instruction does not execute correctly**

    -   Check the decoder output
    -   Check the ALU operation
    -   Check the memory interface

3.  **Register value is abnormal**
    -   Check the write enable signal
    -   Check the datapath connection
    -   Investigate timing issues

## Next Steps

In Day 09, we will add an LCD controller system to visually display the CPU's output.

## Reference Materials

-   6502 CPU Architecture Specification
-   SystemVerilog CPU Design Patterns
-   FPGA Timing Constraint Design
-   Debugging and Testing Methods
