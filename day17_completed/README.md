# Day 17: Indirect Addressing ((zp,X), (zp),Y)

---

🌐 Available languages:
[English](./README.md) | [日本語](./README_ja.md)

## 📜 Overview

Today, we implement the most complex and powerful addressing modes of the 6502: **Indirect Addressing**.

In these modes, the CPU doesn't look at the data at the specified address. Instead, it looks at that address to find _another_ address, and then accesses the data there. This is the hardware implementation of "pointers" in languages like C, and it is essential for operating systems and sophisticated applications.

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
        Instr[Instruction<br/>JMP ($1000)]
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
| `0x6C` | `JMP (abs)`  | Indirect Jump: Jump to address stored at `abs`     | 5      |
| `0xA1` | `LDA (zp,X)` | Pre-indexed Indirect: Load from `pointer(zp+X)`    | 6      |
| `0xB1` | `LDA (zp),Y` | Post-indexed Indirect: Load from `pointer(zp) + Y` | 5+     |

## 🛠️ Implementation Steps

1. **Indirect Address Fetching**:
    - Fetch the 2 bytes from the specified memory location (e.g., Zero Page) and store them in a temporary 16-bit internal register.
2. **Indexing Logic**:
    - `(zp,X)`: Add X to the page-0 address _before_ fetching the pointer.
    - `(zp),Y`: Fetch the pointer from page-0 _first_, then add Y to get the final effective address.
3. **Advanced FSM Control**:
    - Sequence operand fetch, pointer low/high reads, and final access as separate FSM steps with synchronous RAM waits. Standard 6502 cycles are reference values only.

## 🧪 Verification

- **Running the tests (simulation)**: Run `make test-cpu` in this directory. The shared testbench `../day17/sim/tb_cpu.sv` exercises `LDA (zp,X)`, `LDA (zp),Y`, and `JMP (abs)` (including zero-page wraps and `JSR`/`RTS` interaction) and must finish with `PASS`. `make sim` runs the TFT smoke test. `make test` additionally runs the synchronous RAM integration tests and the LCD pipeline test.

- **On-board program (instruction sequence in `rom.sv`)**:

    ```asm
    LDA #$20
    STA $10    ; Store $20 at $0010
    LDA #$80
    STA $11    ; Store $80 at $0011 -> Pointer value is now $8020

    LDY #$01
    LDA ($10),Y ; Load from address ($8020 + 1) = $8021
    HLT
    ```

    The target data `$42` at `$8021` is baked into the ROM; it is not initialized by the CPU. The shared testbench used by `make test-cpu` injects a different program and pointer tables.

- **FPGA**: Confirm on the LCD debug readout (`PC:xxxx A:xx ...`) that A ends up as `$42` and the CPU stops at `HLT`.

## 🎯 Next Step

In Day 18, we will implement **Custom FPGA Instructions (WVS, CVR, IFO)** beyond the standard 6502 set. Together with `HLT` (introduced in Day 10), they give direct control over our hardware peripherals.

Zero-page pointer reads wrap from $FF to $00. JMP (abs) instead increments the full 16-bit address; the NMOS 6502 page-boundary bug ($12FF to $1200) is not reproduced: this CPU reads $1300.

Instruction-table cycles are reference values for the standard 6502, not clock counts for this FSM including memory waits.
