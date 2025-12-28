# Day 17: Indirect Addressing ((zp,X), (zp),Y)

---

🌐 Available languages:
[English](./README.md) | [日本語](./README_ja.md)

## 📜 Overview

Today, we implement the most complex and powerful addressing modes of the 6502: **Indirect Addressing**.

**Analogy:**
Think of this as a **"Scavenger Hunt"** or **"Pointer to a Pointer"** in C (`**ptr`).

1. **Immediate**: "The treasure is here."
2. **Absolute**: "The treasure is at 123 Main St."
3. **Indirect**: "Go to 123 Main St. There you will find a note with the address of the treasure."

This is the hardware implementation of "pointers" in languages like C, and it is essential for operating systems and sophisticated applications.

## 🎯 Learning Objectives

- **Pointer Concepts**: Understand how to fetch an "address of an address."
- **Pre- vs. Post-Indexing**: Learn the difference between `(zp,X)` and `(zp),Y`.
- **Complex Memory Fetches**: Manage state transitions for instructions that perform multiple memory reads in a single opcode.

## 🏗️ Example Instructions

| Opcode | Mnemonic     | Description                                        | Cycles |
| :----: | ------------ | -------------------------------------------------- | :----: |
| `0x6C` | `JMP (abs)`  | Indirect Jump: Jump to address stored at `abs`     |   5    |
| `0xA1` | `LDA (zp,X)` | Pre-indexed Indirect: Load from `pointer(zp+X)`    |   6    |
| `0xB1` | `LDA (zp),Y` | Post-indexed Indirect: Load from `pointer(zp) + Y` |   5+   |

## 🛠️ Implementation Steps

1. **Indirect Address Fetching**:
    - Fetch the 2 bytes from the specified memory location (e.g., Zero Page) and store them in a temporary 16-bit internal register.
2. **Indexing Logic**:
    - `(zp,X)`: Add X to the page-0 address _before_ fetching the pointer.
    - `(zp),Y`: Fetch the pointer from page-0 _first_, then add Y to get the final effective address.
3. **Advanced FSM Control**:
    - Since these instructions take 5 to 6 cycles, ensure your state machine correctly sequences the operand fetch, pointer fetch, and final data access/operation.

## 🧪 Verification

Starting from Day 05, **the testbench (`day17/sim/`) is provided in a complete state.** Use it to verify the correctness of your implementation.

- **Test Program**:
    ```asm
    JSR sub    ; Jump to Subroutine
    HLT
sub:
    LDA #$42
    RTS        ; Return from Subroutine
    ```
- **Simulation**: Run `make sim` and verify that the subroutine call and return work correctly and the simulation outputs `PASS`.
- **FPGA**: Observe the PC jumping to the subroutine and returning correctly on the LCD.

## 🎯 Next Step

In Day 18, we will break away from the standard 6502 set and implement **Custom FPGA Instructions (HLT, WVS, CVR, IFO)** to take direct control of our hardware peripherals.
