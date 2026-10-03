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

## 🧠 Memory Model Note

From Day 10 onward, the program runs from RAM backed by Gowin BSRAM (`ram.sv`), not the simple ROM used in earlier days.

## 🎯 Learning Objectives

- **Pointer Concepts**: Understand how to fetch an "address of an address."
- **Pre- vs. Post-Indexing**: Learn the difference between `(zp,X)` and `(zp),Y`.
- **Complex Memory Fetches**: Manage state transitions for instructions that perform multiple memory reads in a single opcode.

## 🏗️ Example Instructions

```mermaid
graph TD
    subgraph "JMP (abs)"
        Instr[Instruction<br/>JMP $1000]
        Ptr[Pointer at $1000<br/>Contains $2034]
        Target[Target Address<br/>$2034]
        Instr -->|Fetch Pointer| Ptr
        Ptr -->|Jump to| Target
    end

    subgraph "LDA (zp),Y"
        ZP[ZP Address]
        Ptr2[Read Pointer from ZP]
        AddY{+ Y}
        Eff[Effective Address]
        ZP --> Ptr2
        Ptr2 --> AddY
        AddY --> Eff
    end
```

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

This Day includes a CPU testbench. If the starter TODOs are not yet implemented, it is expected and normal for the CPU test to fail. After implementing the TODOs, run `make test-cpu` and confirm the tests pass. Passing the tests verifies the tested scope only and does not guarantee untested instructions or real-hardware behavior.

- **Test Program**:

    ```asm
    LDX #$03
    LDA ($40,X) ; pointer at $0043 -> $1234: A = 0x99
    LDX #$05
    LDA ($FE,X) ; zero-page wrap ($FE+5 = $03): -> $1250: A = 0xAA
    LDY #$04
    LDA ($60),Y ; pointer $1140 + Y -> $1144: A = 0xBB
    LDY #$00
    LDA ($FF),Y ; pointer wraps $FF -> $00: -> $1360: A = 0xCC
    JSR $0250   ; subroutine: LDA #$42 / RTS
    JMP ($2000) ; pointer at $2000 -> $0230: LDA #$DD / HLT
    ```

- **Simulation**: Run `make test-cpu` and verify the simulation outputs `PASS` (`make sim` additionally runs the TFT smoke test).
- **FPGA**: Confirm on the LCD that the final data pointed to by the pointer is loaded correctly.

## 🎯 Next Step

In Day 18, we will break away from the standard 6502 set and implement **Custom FPGA Instructions (HLT, WVS, CVR, IFO)** to take direct control of our hardware peripherals.
