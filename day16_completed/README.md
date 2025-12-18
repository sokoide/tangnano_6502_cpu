# Day 16: Indexed Addressing (LDA abs,X)

---

🌐 Available languages:
[English](./README.md) | [日本語](./README_ja.md)

## 📜 Overview

Today, we implement one of the features that makes the 6502 incredibly powerful: **Indexed Addressing**.

In this mode, the CPU accesses an address calculated by adding the value of the **X** or **Y** register to a base address. This enables efficient processing of arrays, tables, and lists using loops.

## 🎯 Learning Objectives

-   **Index Calculation**: Understand the timing of adding a register value to a base address.
-   **Array Processing**: Buffer or table traversal using loops and the X register.
-   **Multi-cycle Logic**: Handling the extra cycles required for address arithmetic.

## 🏗️ Example Instructions

| Opcode | Mnemonic    | Description                   | Cycles |
| :----: | ----------- | ----------------------------- | :----: |
| `0xBD` | `LDA abs,X` | Load A from address (abs + X) |   4+   |
| `0xB9` | `LDA abs,Y` | Load A from address (abs + Y) |   4+   |
| `0x9D` | `STA abs,X` | Store A to address (abs + X)  |   5    |

_Note: The `+` indicates that an extra cycle is added on a real 6502 if a "page boundary" is crossed (e.g., from $xxFF to $yy00). You may implement a simplified fixed-cycle version initially._

## 🛠️ Implementation Steps

1.  **Add Address Adder**:
    -   Implement logic to add the 8-bit X or Y register value to the 16-bit fetched base address.
    -   Example: `effective_address = base_address + X;`
2.  **State Machine Adjustment**:
    -   Manage the cycles to fetch the base address bytes, perform the addition, and then perform the final memory access.

## 🧪 Verification

-   **Test Program**:
    ```asm
    ; Load array elements into A sequentially
    LDX #$00
    LOOP:
    LDA DATA,X ; Load from DATA + X
    INX
    CPX #$03
    BNE LOOP
    HLT
    DATA: .byte $11, $22, $33
    ```
-   **FPGA**: Confirm on the LCD that A becomes `$11`, `$22`, and then `$33` before the program exits the loop.

## 🎯 Next Step

In Day 17, we will tackle the most advanced mode: **Indirect Addressing**. This is essential for handling pointers and dynamic memory access.
