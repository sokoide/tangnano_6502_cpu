# Day 07: Memory Interface and Stack

---

🌐 Available languages:
[English](./README.md) | [日本語](./README_ja.md)

## Learning Objectives

In Day 07, we will implement the memory interface and stack management, which are important components of the 6502 CPU system.

### What You Will Learn Today

1.  **Memory Mapping**

    -   Dividing the address space for RAM, ROM, and I/O
    -   Generating chip select signals
    -   Address decoding

2.  **Memory Interface**

    -   Controlling memory reads and writes
    -   Appropriate timing control
    -   Connecting to external memory

3.  **Stack Pointer Management**

    -   6502 stack operation (grows downwards from $01FF)
    -   PUSH and POP operations
    -   Stack overflow/underflow detection

4.  **Memory Controller**
    -   Arbitration between CPU and stack operations
    -   Priority control
    -   Integrated memory access

## Implementation Details

### 1. Memory Interface (`memory_interface.sv`)

```systemverilog
// Memory Map
// $0000-$7FFF: RAM (32KB)
// $8000-$BFFF: I/O space (16KB)
// $C000-$FFFF: ROM (16KB)
```

-   Address decoding
-   Memory read/write state machine
-   Appropriate interface with external memory

### 2. Stack Pointer (`stack_pointer.sv`)

```systemverilog
// 6502 Stack Features
// - Fixed to Page 1 ($0100-$01FF)
// - Starts at $01FF and grows downwards
// - SP is only the lower 8 bits
```

-   Stack operations (PUSH/POP)
-   Overflow/underflow detection
-   Appropriate address generation

### 3. Memory Controller (`memory_controller.sv`)

-   Integration of CPU and stack operations
-   Priority control for memory access
-   Simple RAM and ROM modules

### 4. Test System (`top.sv`)

A demonstration to test the actual memory system:

-   RAM read/write test
-   ROM read test
-   Stack operation test
-   Address mapping verification

## Build and Execute

### Required Files

-   `memory_interface.sv` - Memory interface control
-   `stack_pointer.sv` - Stack pointer management
-   `memory_controller.sv` - Integrated memory controller
-   `simple_ram.sv` - Simple RAM module
-   `simple_rom.sv` - Simple ROM module
-   `top.sv` - Test system
-   `tb_memory_system.sv` - Testbench
-   `Makefile` - Build system

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

Signals that can be monitored with LEDs or pins on the Tang Nano:

-   `debug_mem_addr[15:0]` - Current memory address
-   `debug_mem_data[7:0]` - Memory data
-   `debug_mem_read` - Memory read signal
-   `debug_mem_write` - Memory write signal
-   `debug_stack_ptr[7:0]` - Stack pointer value
-   `debug_stack_push/pop` - Stack operation signals

## Test Sequence

Test patterns that can be controlled with switches:

1.  **RAM Write Test** - Write test data to RAM
2.  **RAM Read Test** - Read data from RAM
3.  **ROM Read Test** - Read program data from ROM
4.  **Stack Push Test** - Push data onto the stack
5.  **Stack Pop Test** - Pop data from the stack
6.  **Zero Page Access** - Read/write to zero-page memory
7.  **Stack Page Access** - Direct access to the stack page

## Learning Points

### Understanding Memory Mapping

Standard memory layout of a 6502 system:

-   **Zero Page** ($0000-$00FF): High-speed access
-   **Stack Page** ($0100-$01FF): Dedicated to the stack
-   **RAM Area** ($0200-$7FFF): General data and programs
-   **I/O Area** ($8000-$BFFF): Peripherals
-   **ROM Area** ($C000-$FFFF): Program and interrupt vectors

### Details of Stack Operations

```systemverilog
// PUSH operation: Decrement SP, then write data
// POP operation:  Read data, then increment SP
```

### Memory Access Timing

-   Appropriate setup/hold times
-   Control of chip select signals
-   Synchronization of read/write signals

## Next Steps

In Day 08, we will integrate all the components created so far to implement a complete 6502 CPU core.

## Reference Materials

-   6502 Memory Map Design Guide
-   Tang Nano Memory Interface Specification
-   SystemVerilog Memory Modeling
-   FPGA RAM/ROM Implementation Patterns
