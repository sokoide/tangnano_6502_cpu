# Day 11: Zero Page Addressing & RAM

---

🌐 Available languages:
[English](./README.md) | [日本語](./README_ja.md)

## 📜 Overview

So far, all our programs have used "Immediate (`#imm`)" or "Register-to-Register" operations. From today, we start working with **Memory** in earnest.

Our first step is implementing a key 6502 feature: **Zero Page Addressing**. This mode allows the CPU to quickly read/write to the first 256 bytes of memory (`$0000` to `$00FF`), making it perfect for storing variables.

## 🎯 Learning Objectives

- **Zero Page Concept**: Understand the speed and convenience of accessing Page 0 (`$00xx`).
- **RAM Control**: Implement a memory region where data can be read and written during execution.
- **Load/Store**: Implement basic memory access instructions like `LDA zp` and `STA zp`.

## 🏗️ What is Zero Page?

- **Address Range**: `$0000` to `$00FF`.
- **Advantages**: It only requires 1 byte for the address, making instructions shorter and execution faster.

**Analogy:**
Think of Zero Page as the **"VIP Section"** or **"L1 Cache"** of memory.

- **Normal Memory (Absolute)**: Requires a full street address (16-bit) to find. "1234 Main St."
- **Zero Page**: Only requires a nickname (8-bit) because it's right in the neighborhood. "Bob's House."

It is functionally used like "extra registers" or high-speed variables for your programs.

## 🏗️ Instructions to Implement

| Opcode | Mnemonic | Description                   | Cycles |
| :----: | -------- | ----------------------------- | :----: |
| `0xA5` | `LDA zp` | Load A from Zero Page address |   3    |
| `0x85` | `STA zp` | Store A to Zero Page address  |   3    |
| `0xA6` | `LDX zp` | Load X from Zero Page address |   3    |
| `0x86` | `STX zp` | Store X to Zero Page address  |   3    |

## 🛠️ Implementation Steps

1. **Define RAM Region**:
    - Verify your memory map so that writes to `$0000-$00FF` are handled by physical RAM (e.g., Block RAM inside the FPGA).
2. **Add Addressing States**:
    - Fetch the second byte (lower 8 bits of the address).
    - Access memory by setting the upper 8 bits to `$00`.
3. **Read/Write Timing**:
    - For `STA`, ensure `write_en` is pulsed at the correct clock edge while valid data is on the bus.

## 🧪 Verification

Starting from Day 05, **the testbench (`day11/sim/`) is provided in a complete state.** Use it to verify the correctness of your implementation.

- **Test Program**:
    ```asm
    LDA #$42
    STA $10    ; Store 0x42 to address $0010
    LDA #$00
    LDA $10    ; Load from address $0010 (A = 0x42)
    ```
- **Simulation**: Run `make sim` and verify that the RAM write and read operations work correctly and the simulation outputs `PASS`.
- **FPGA**: Confirm on the LCD that the A register value changes as expected.

## 🎯 Next Step

In Day 12, we will implement **Absolute Addressing**, allowing the CPU to reach any address in the full 64KB range ($0000 - $FFFF).
