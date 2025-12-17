# Day 12: Absolute Addressing (16-bit)

---

🌐 Available languages:
[English](./README.md) | [日本語](./README_ja.md)

## 📜 Overview

The Zero Page we learned on Day 11 is useful but limited to 256 bytes. Today, we implement **Absolute Addressing**, which enables the CPU to access the full 64KB memory range.

In this mode, the opcode is followed by a 2-byte address (low byte, then high byte). This allows the CPU to read or write to any memory location, as well as interact with memory-mapped ROM and peripherals.

## 🎯 Learning Objectives

-   **16-bit Address Handling**: Fetch a full 2-byte address in Little-Endian format.
-   **Full-Range Memory Access**: Master the mode essential for large data tables and IO.
-   **JMP Instruction**: Implement an unconditional jump to a specific 16-bit address.

## 🏗️ 6502 Address Format (Little-Endian)

The 6502 uses **Little-Endian**. When specifying a 16-bit address like `$ABCD`, it is stored in memory as follows:

1.  Opcode
2.  Low Byte of Address (`$CD`)
3.  High Byte of Address (`$AB`)

## 🏗️ Instructions to Implement

| Opcode | Mnemonic  | Description                          | Cycles |
| :----: | --------- | ------------------------------------ | :----: |
| `0xAD` | `LDA abs` | Load A from specific 16-bit address  |   4    |
| `0x8D` | `STA abs` | Store A to specific 16-bit address   |   4    |
| `0x4C` | `JMP abs` | Unconditional Jump to 16-bit address |   3    |

## 🛠️ Implementation Steps

1.  **Multi-cycle Address Fetch**:
    -   Fetch the address low byte and store it in a temporary register.
    -   Fetch the address high byte and combine it into a full 16-bit address.
2.  **Driving the Address Bus**:
    -   Drive the `address_bus` with the completed 16-bit value and read/write data in the following cycle.
3.  **Handling JMP**:
    -   Instead of reading/writing memory, `JMP` directly assigns the fetched 16-bit address to the `PC`.

## 🧪 Verification

-   **Test Program**:
    ```asm
    LDA #$AA
    STA $0200  ; Store in RAM (Page 2)
    LDA #$00
    LDA $0200  ; Re-load (A should become $AA)
    JMP $8000  ; Loop back to start
    ```
-   **FPGA**: Confirm on the LCD that the PC and A register values change as expected, indicating successful memory access and jumping.

## 🎯 Next Step

In Day 13, we will enhance our data processing capabilities by implementing **Logical Operations (AND, ORA, EOR, BIT)**.
