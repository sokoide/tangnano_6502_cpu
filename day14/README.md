# Day 14: Shift & Rotate Instructions (ASL, LSR, ROL, ROR)

---

🌐 Available languages:
[English](./README.md) | [日本語](./README_ja.md)

## 📜 Overview

Today, we implement **Shift** and **Rotate** instructions, which move bits to the left or right within a register.

These instructions are frequently used for fast multiplication by 2 (`ASL`), division by 2 (`LSR`), and processing serial data. A key concept here is understanding how shifted-out bits are stored in the **Carry (C) flag**.

## 🎯 Learning Objectives

- **Bit Shifting**: Moving bits and filling the empty space with 0.
- **Bit Rotation**: Circularly shifting bits through the Carry flag.
- **High-speed Math**: Understanding how shifts perform efficient multiplication and division.

## 🏗️ Instructions to Implement

| Opcode | Mnemonic | Description                         | Cycles |
| :----: | -------- | ----------------------------------- | :----: |
| `0x0A` | `ASL A`  | Arithmetic Shift Left (Fill with 0) |   2    |
| `0x4A` | `LSR A`  | Logical Shift Right (Fill with 0)   |   2    |
| `0x2A` | `ROL A`  | Rotate Left (Through Carry)         |   2    |
| `0x6A` | `ROR A`  | Rotate Right (Through Carry)        |   2    |

## 🛠️ Implementation Steps

1. **Shift Logic**:
    - `ASL`: `new_A = {A[6:0], 1'b0};` `new_C = A[7];`
    - `LSR`: `new_A = {1'b0, A[7:1]};` `new_C = A[0];`
2. **Rotate Logic**:
    - `ROL`: `new_A = {A[6:0], C};` `new_C = A[7];`
    - `ROR`: `new_A = {C, A[7:1]};` `new_C = A[0];`
3. **Flag Updates**:
    - All shift/rotate instructions update Z and N based on the result. The C flag becomes the bit that was shifted or rotated out.

## 🧪 Verification

Starting from Day 05, **the testbench (`day14/sim/`) is provided in a complete state.** Use it to verify the correctness of your implementation.

- **Test Program**:
    ```asm
    LDX #$05
loop:
    DEX
    BNE loop   ; Repeat until X is 0
    BRK
    ```
- **Simulation**: Run `make sim` and verify that conditional branching works correctly based on flags and the simulation outputs `PASS`.
- **FPGA**: Observe the loop execution and final stop at a specific address on the LCD.

## 🎯 Next Step

In Day 15, we will implement **Comparison Instructions (CMP, CPX, CPY)** and **Increment/Decrement** for memory contents, which provide the data needed for branches.
