# Day 06: Memory Access & LDA Instruction

---

🌐 Available languages:
[English](./README.md) | [日本語](./README_ja.md)

## 📜 Overview

In Day 06, we will breathe more life into our CPU by implementing its first data-handling instruction: **`LDA #imm`** (Load Accumulator with Immediate value). This involves actively using the **Accumulator (A register)** introduced in Day 05.

We will also implement the logic to fetch an 8-bit _operand_ that follows the instruction code in memory.

## 🧠 Memory Model Note

Day 04–09 use a simple program ROM (`rom.sv`) to supply instructions. RAM is still used for data; the RAM-backed program flow starts in Day 10.

## 🔙 Review: Day 05

Before proceeding, make sure you understand:

- **Program Counter (PC)**: Holds the address of the next instruction
- **Sequential Logic**: `always_ff @(posedge clk)` for clock-synchronized updates
- **LCD Display**: How to output debug information to the display

## 🎯 Learning Objectives

- Implement the **Instruction Decoder (simple_decoder.sv)** to classify opcodes into categories.
- Implement the **Flag Calculator (flag_calculator.sv)** to derive status from operation results.
- Implement the **LDA (Load Accumulator) instruction** to enable loading data into the Accumulator (A) implemented in Day 05.
- Understand the basic cycle of **Instruction Fetch** and **Decode**.

## 💡 Stepping Up: From Day 05 to Day 06

In Day 05, the CPU learned its minimum movement: "just take one step (PC+1)." In Day 06, we finally tackle the core function of a CPU: "understanding instructions and moving data."

## 🏗️ Architecture

The decoder and flag calculation logic are now integrated into the CPU.

```mermaid
graph TD
    subgraph CPU
        PC[Program Counter]
        DEC[Instruction Decoder]
        REGS[Registers]
        ALU[ALU / Flag Calc]

        PC --> MEM[Memory/ROM]
        MEM -->|Opcode| DEC
        DEC -->|Control| REGS
        MEM -->|Data| REGS
        REGS --> ALU
        ALU -->|N, Z, C, V| REGS
    end
```

## 🛠️ Implementation Steps

1. **Implement `simple_decoder.sv`**:
    - Use a `case` statement to identify instruction categories (e.g., `is_load`) from opcodes (e.g., `0xA9`).
2. **Implement `flag_calculator.sv`**:
    - Describe the logic to calculate N, Z, C, and V flags based on results.
3. **Extend `cpu.sv`**:
    - Integrate the decoder and flag calculator into the CPU.
    - Extend the state machine to execute the `LDA Immediate` instruction.

## 📘 Fundamentals: Machine Code & Mnemonics

For software engineers, the relationship between Assembly and Machine Code might be a bit opaque at first.

### 1. Mnemonics vs. Machine Code

The code we write is called **Assembly Language**, which uses human-readable **Mnemonics**.
However, the CPU cannot understand this directly. It only understands **Machine Code**, which is just a sequence of numbers.

**Analogy:**

- **Assembly** is like your C++ or Python source code. It's for humans.
- **Machine Code** is like the compiled `.exe` or `.pyc` bytecode. It's for the machine.
- **Assembler** is the compiler that translates one to the other.

| Language         | Example    | Description                                      |
| :--------------- | :--------- | :----------------------------------------------- |
| **Assembly**     | `LDA #$A9` | For humans. Means "Load value into Accumulator". |
| **Machine Code** | `A9 42`    | For CPU. A sequence of hex bytes.                |

In this course, we will write machine code by hand (hand-assembly) to truly understand what the CPU sees.

### 2. Instruction Length (1-byte vs 2-byte)

Machine code instructions can be 1 byte long or take multiple bytes if they need data (operands).

- **1-byte Instruction (e.g., NOP)**

  - Just `EA`.
  - Means "No Operation", so no extra data is needed.

- **2-byte Instruction (e.g., LDA #imm)**
  - Uses 2 bytes like `A9 42`.
  - 1st byte `A9` is the **Opcode** (Operation Code) telling the CPU "We are about to do a Load!".
  - 2nd byte `42` is the **Operand**, the actual value to load.

## 📘 Architecture Deep Dive: How PC Works

The Program Counter (PC) is not just a counter; it is the **conductor** of the CPU.
It points to "where in memory the next instruction is located."

Let's trace how PC changes when executing `LDA #$42` (Machine Code: `A9 42`).

1. **Fetch Opcode**

    - PC points to `8000`.
    - CPU reads **`A9`** from memory address `8000`.
    - CPU decodes `A9`, understands "This is LDA! I need data next."
    - PC moves to `8001`.

2. **Fetch Operand**
    - PC points to `8001`.
    - CPU reads **`42`** from memory address `8001`.
    - CPU puts this `42` into the A Register.
    - PC moves to `8002`, ready for the next instruction.

In this way, the PC advances step-by-step, reading machine code from memory, which the CPU then interprets and executes. This is the fundamental operating principle of computers.

## 💡 What is "Immediate Addressing"?

"Immediate" means the data the instruction needs is located _immediately_ after the instruction code in memory.

Example in memory:

- Address `0x8000`: `0xA9` (LDA #imm instruction)
- Address `0x8001`: `0x42` (The value to load)

When this is executed, the A register will contain the value `0x42`.

## 🧪 Verification

Starting from Day 05, **each day provides a complete testbench** (for Day 06, see `day06/sim/`). Use it to verify the correctness of your implementation.

- **Test Program**: Create a simple ROM containing `A9 42` (LDA #$42).
- **Simulation**: Run `make sim`. Success is achieved if the `A` register holds `0x42` after two clock cycles and the simulation outputs `PASS`.
- **FPGA**: Check the LCD. It should display "A: 42" (or your chosen value).

## 🎯 Preview for Tomorrow

In Day 07, we will add the **X and Y index registers** and implement instructions to transfer data between registers, such as `TAX` (Transfer A to X).
