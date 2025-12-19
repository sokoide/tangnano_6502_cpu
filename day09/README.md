# Day 09: Branch Instructions & Control Flow

---

🌐 Available languages:
[English](./README.md) | [日本語](./README_ja.md)

## 📜 Overview

A CPU that only executes instructions in a straight line isn't very capable. Today, we give our CPU "decision-making" power by implementing **Branch Instructions**.

Instructions like `BNE` (Branch if Not Equal) and `BEQ` (Branch if Equal) check the status flags (specifically the Zero flag) and jump the execution point (Program Counter) if a condition is met. This is the foundation of loops and `if` statements.

## 🔙 Review: Day 08

Before proceeding, make sure you understand:

- **ALU**: Performs addition (`ADC`) and subtraction (`SBC`)
- **Status Flags**: N (Negative), V (Overflow), Z (Zero), C (Carry)
- **Flag Updates**: How operations automatically set these flags

## 🎯 Learning Objectives

- **Control Flow**: Understand how loops and conditional branches are achieved at the hardware level.
- **Relative Addressing**: Implement the mechanism to calculate "how far" to jump from the current Program Counter (PC).
- **Conditional PC Updates**: Decide whether to jump or proceed to the next instruction based on the Zero (Z) flag.

## 🏗️ Instructions to Implement

| Opcode | Mnemonic | Description                  | Condition |
| :----: | -------- | ---------------------------- | --------- |
| `0xD0` | `BNE`    | Branch if Not Equal (Zero=0) | Z = 0     |
| `0xF0` | `BEQ`    | Branch if Equal (Zero=1)     | Z = 1     |
| `0x10` | `BPL`    | Branch if Plus (Negative=0)  | N = 0     |
| `0x30` | `BMI`    | Branch if Minus (Negative=1) | N = 1     |

## 🛠️ Implementation Steps

1. **Relative Address Calculation**:
    - The second byte of a branch instruction is a **signed 8-bit offset**.
    - Target PC formula: `target_pc = (PC + 2) + $signed(offset);` (Wait until the offset byte is fetched).
2. **Condition Check**:
    - Inside your `always_ff` block, check the state of the relevant flag.
    - Example: `if (opcode == OP_BNE && !Z) PC <= target_pc;`
3. **State Machine Extension**:
    - Expand your FSM to handle the offset fetch cycle and then decide the next PC value in the following cycle.

## 💡 Why Relative Addressing?

Branch instructions use relative offsets rather than absolute addresses. This makes the code **position-independent**, meaning it can work correctly no matter where it's loaded in memory without being recompiled.

## 🧪 Verification

- **Test Program**:

    ```asm
    LDA #$00   ; A = 0, Z = 1
    BEQ SKIP   ; Z=1 so it should jump
    LDA #$FF   ; This should be skipped
    SKIP:
    INX        ; Jump target
    ```

- **FPGA**: Verify on the LCD that the PC value skips the expected address range during execution.

## 🎯 Next Step

In Day 10, we will complete the core CPU features by implementing the **Stack** and **Stack Pointer (S)**, enabling function calls (subroutines).
