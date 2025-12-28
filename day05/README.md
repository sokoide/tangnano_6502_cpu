# Day 05: CPU Skeleton & NOP Instruction

---

🌐 Available languages:
[English](./README.md) | [日本語](./README_ja.md)

## 📜 Overview

It's time to start implementing the CPU! The goal of Day 05 is to implement the most fundamental component of a CPU: the **Program Counter (PC)**.

We will connect the CPU's PC value to the LCD display circuit created in Day 04 to visually verify that the PC increments with every clock cycle. This is the "Hello World" of CPU design.

## 🔙 Review: Day 04

Before proceeding, make sure you understand:

- **6502 Register Set**: The role and structure of A, X, Y, PC, SP, and P
- **Flag Calculation**: How the N, Z, C, and V flags are derived from arithmetic results
- **LCD Rendering**: The pipeline that displays characters read from VRAM

## 🎯 Learning Objectives

- **Create CPU Module**: Create a basic `cpu.sv` file.
- **Program Counter (PC)**: Implement the register that hold the address of the next memory location.
- **Sequential Logic**: Understand how the PC updates on every clock edge.
- **Visual Verification**: Display the PC on the LCD.

## 🏗️ Architecture

The CPU is currently empty, but it is built around the Program Counter (PC), which is the basis for all operations.

```mermaid
graph TD
    subgraph "CPU (cpu.sv)"
        subgraph "Internal Registers"
            PC[Program Counter 16-bit]
        end
        
        CLK[clk] --> PC
        RST[rst_n] --> PC
        EN[pc_enable] --> PC
        
        PC --> AB[address_bus 16-bit]
        PC --> DPC[debug_pc 16-bit]
    end
```

## 🛠️ Implementation Steps

### Step 1: Create CPU Module (`cpu.sv`)

Define the minimal CPU interface and write the logic for incrementing the PC.

```mermaid
graph TD
    Reset{rst_n == 0?} -- Yes --> P8000[PC = 0x8000]
    Reset -- No --> Enable{pc_enable == 1?}
    Enable -- Yes --> Inc[PC = PC + 1]
    Enable -- No --> Hold[PC = PC]
```

1. **PC Initialization**: The 6502 normally starts at `0xFFFC`, but for simplicity, we use `0x8000` as the starting address.
2. **PC Update**: On the rising edge of the clock, increment the PC by 1 when reset is released and `pc_enable` is high.

### Step 2: Integrate with LCD Demo (`lcd_demo.sv`)

Complete the "Debug Display Pipeline" to show the internal CPU state (`debug_pc`) on the LCD.

```mermaid
graph TD
    subgraph "CPU"
        PC[debug_pc]
    end
    
    subgraph "LCD Demo (lcd_demo.sv)"
        Writer[VRAM Writer State Machine]
        VRAM[VRAM SDPB]
        SD[LCD Panel]
    end
    
    PC -->|Hex Conversion| Writer
    Writer -->|'P', 'C', ':', 'X', 'X', 'X', 'X'| VRAM
    VRAM -->|Text Rendering| SD
```

1. **Instantiation**: Instantiate the `cpu` module within `lcd_demo.sv`.
2. **Writing Logic**: Update the state machine to convert the PC value to hexadecimal characters (0-F) and write them to a specific VRAM address (e.g., the corner of the screen).

## 📘 Concept: What is a Program Counter?

The **Program Counter (PC)** is a register that allows the CPU to remember **"where in memory to read next"**.

```mermaid
graph LR
    Start([Reset]) --> Init[PC = 0x8000]
    Init --> Fetch[Fetch: PC on Address Bus]
    Fetch --> Execute[Execute: Increment PC]
    Execute --> Fetch
```

Think of the PC as a **bookmark** in a book:

1. **Fetch** the instruction at the bookmark's location.
2. **Execute** what it says.
3. **Move** the bookmark forward to the next line (address).

In Day 05, we aren't reading from memory yet, but we will implement this basic "move the bookmark forward" behavior at the heart of the CPU and verify it visually.

## 💡 Why start here?

Implementing only the PC allows us to verify the entire toolchain—from SystemVerilog code to FPGA deployment and LCD display—before adding the complexity of instruction decoding.

## 🧪 Verification

- **Simulation**: Confirm `PC` increments: `8000` -> `8001` -> `8002` ...
- **FPGA**: If the PC value appears on the LCD and counts up rapidly, you've succeeded (if it's too fast to read, try displaying the upper bits or dividing the clock).

## 🎯 Preview for Tomorrow

In Day 06, we will breathe more life into our CPU by implementing the **A register** and our first data instruction: **`LDA #imm`**. We will also introduce a **structured architecture** using opcode headers and separate memory modules to make the CPU more scalable.
