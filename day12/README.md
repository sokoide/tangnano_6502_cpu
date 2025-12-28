# Day 12: Absolute Addressing (16-bit)

---

🌐 Available languages:
[English](./README.md) | [日本語](./README_ja.md)

## 📜 Overview

The Zero Page we learned on Day 11 is useful but limited to 256 bytes. Today, we implement **Absolute Addressing**, which enables the CPU to access the full 64KB memory range.

In this mode, the opcode is followed by a 2-byte address (low byte, then high byte). This allows the CPU to read or write to any memory location, as well as interact with memory-mapped ROM and peripherals.

## 🎯 Learning Objectives

- **16-bit Address Handling**: Fetch a full 2-byte address in Little-Endian format.
- **Full-Range Memory Access**: Master the mode essential for large data tables and IO.

## 🏗️ 6502 Address Format (Little-Endian)

The 6502 uses **Little-Endian**. When specifying a 16-bit address like `$ABCD`, it is stored in memory as follows:

1. Opcode
2. Low Byte of Address (`$CD`)
3. High Byte of Address (`$AB`)

**Analogy:**
Think of it like writing a date as **"Day-Month-Year"** (25th December 2025).

- The "smallest" unit (Day) comes first.
- The "biggest" unit (Year) comes last.
- Big-Endian would be "Year-Month-Day" (2025-12-25).

## 🏗️ Instructions to Implement

| Opcode | Mnemonic  | Description                         | Cycles |
| :----: | --------- | ----------------------------------- | :----: |
| `0xAD` | `LDA abs` | Load A from specific 16-bit address |   4    |
| `0x8D` | `STA abs` | Store A to specific 16-bit address  |   4    |

## 🛠️ Implementation Steps

1. **Multi-cycle Address Fetch**:
    - Fetch the address low byte and store it in a temporary register.
    - Fetch the address high byte and combine it into a full 16-bit address.
2. **Driving the Address Bus**:
    - Drive the `address_bus` with the completed 16-bit value and read/write data in the following cycle.

## 🧪 Verification

Starting from Day 05, **the testbench (`day12/sim/`) is provided in a complete state.** Use it to verify the correctness of your implementation.

- **Test Program**:

    ```asm
    LDA #$55
    STA $1234  ; Store to Absolute address $1234
    LDA #$00
    LDA $1234  ; Load from address $1234 (A = 0x55)
    ```

- **Simulation**: Run `make sim` and verify that Absolute addressing read/write works correctly and the simulation outputs `PASS`.
- **FPGA**: Confirm on the LCD that the PC and A register values change as expected.

## 🎯 Next Step

In Day 13, we will enhance our data processing capabilities by implementing **Logical Operations (AND, ORA, EOR, BIT)**.
