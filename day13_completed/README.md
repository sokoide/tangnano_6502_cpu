# Day 13: Logical Operations & BIT

---

🌐 Available languages:
[English](./README.md) | [日本語](./README_ja.md)

## 📜 Overview

In addition to arithmetic, bitwise manipulation is a core responsibility of a CPU. Today, we implement **Logical Operations (AND, ORA, EOR)** and the **BIT** instruction for checking bit states.

These instructions enable "masking," "toggling," and "testing" specific bits—operations that are essential for low-level hardware control.

## 🎯 Learning Objectives

- **Bitwise Logic Implementation**: Hardware implementation of AND, OR, and XOR.
- **Flag Updates**: Verify how N and Z flags are updated after logical operations.
- **The BIT Instruction**: Understand how to test flags without modifying the Accumulator.

## 🏗️ Instructions to Implement

| Opcode | Mnemonic   | Description                   | Cycles |
| :----: | ---------- | ----------------------------- | :----: |
| `0x29` | `AND #imm` | A = A & Operand               |   2    |
| `0x09` | `ORA #imm` | A = A \| Operand              |   2    |
| `0x49` | `EOR #imm` | A = A ^ Operand               |   2    |
| `0x24` | `BIT zp`   | Test bits in memory against A |   3    |

_Note: The `BIT` instruction also copies memory bit 7 to the N flag and bit 6 to the V flag, which is unique._

## 🛠️ Implementation Steps

1. **Extend the ALU**:
    - Add `&` (AND), `|` (OR), and `^` (XOR) logic to your `always_comb` block.
2. **Flag Update Logic**:
    - Update `Z = (result == 0)` and `N = result[7]` for logical results.
3. **Decode BIT Instruction**:
    - `BIT` updates the Z flag based on `A & Memory`, but **does not change** the value of A.
    - Implement the transfer logic for flags: `N = Memory[7]` and `V = Memory[6]`.

## 🧪 Verification

- **Test Program**:

    ```asm
    LDA #$FF
    AND #$0F   ; A = $0F, Z=0, N=0
    ORA #$80   ; A = $8F, Z=0, N=1
    EOR #$8F   ; A = $00, Z=1, N=0
    ```

- **FPGA**: Confirm on the LCD that the Accumulator and N/Z flags change correctly as each operation completes.

## 🎯 Next Step

In Day 14, we will further expand our bit manipulation repertoire by implementing **Shift and Rotate Instructions (ASL, LSR, ROL, ROR)**.
