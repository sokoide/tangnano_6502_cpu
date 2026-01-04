# Day 07: Register Operations (X & Y)

---

🌐 Available languages:
[English](./README.md) | [日本語](./README_ja.md)

## 📜 Overview

In addition to the Accumulator, the 6502 has two versatile 8-bit index registers: the **X Register** and the **Y Register**. In Day 07, we will add these to our CPU.

These registers are essential for many addressing modes and are often used as loop counters or offsets. We will implement instructions to transfer values between registers and perform basic increment/decrement operations.

## 🧠 Memory Model Note

Day 04–09 use a simple program ROM (`rom.sv`) to supply instructions. RAM, including Zero Page/Stack/Program RAM, is not used until Day 10.

## 🎯 Learning Objectives

- **Utilize X and Y Registers**: Put the general-purpose index registers implemented in Day 05 into practical use.
- **Implement Transfer Instructions**: Implement `TAX`, `TAY`, `TXA`, and `TYA`.
- **Implement Increment Instructions**: Implement `INX` and `INY`.
- **Expand Decoder**: Master handling single-byte instructions with no operands.

## 🏗️ Instructions to Implement

```mermaid
graph TD
    A["Accumulator (A)"]
    X[Index X]
    Y[Index Y]

    A -- TAX --> X
    A -- TAY --> Y
    X -- TXA --> A
    Y -- TYA --> A
    X -- INX --> X
    Y -- INY --> Y
```

| Opcode | Mnemonic | Description | Cycles |
| :----: | -------- | ----------- | :----: |
| `0xAA` | `TAX`    | Copy A to X |   2    |
| `0xA8` | `TAY`    | Copy A to Y |   2    |
| `0x8A` | `TXA`    | Copy X to A |   2    |
| `0x98` | `TYA`    | Copy Y to A |   2    |
| `0xE8` | `INX`    | Increment X |   2    |
| `0xC8` | `INY`    | Increment Y |   2    |

_Note: On a real 6502, these take 2 cycles. In our simplified FPGA model, you might implement them in a single cycle._

> [!TIP]
> **Column: Opcodes**
>
> In Day 06 we used `LDA` as `0xA9`, and in Day 07 we define `TAX` as `0xAA`, etc.
> These are standard 6502 opcodes listed in references like the
> [6502 Instruction Set](https://www.masswerk.at/6502/6502_instruction_set.html).
> You can hand-assemble them, but longer programs get tedious.
> In that case, you can assemble with `cc65` like this:
>
> ```bash
> cat > hoge.s << 'END'
>    .org $0200
>    LDA #$42
>    TAX
> END
> ```
>
> Then you can generate a listing and see that `LDA #$42` becomes `0xA9 0x42`:
>
> ```bash
> ca65 -l hoge.lst hoge.s
>
> cat hoge.lst
>
> 000000r 1                   .org $0200
> 000200  1  A9 42            LDA #$42
> 000202  1  AA               TAX
> 000202  1
> ```
>
> The [day99_completed examples](../day99_completed/examples/Makefile) use this flow to assemble 6502 code into FPGA-ready binaries.

## 🛠️ Implementation Steps

1. **Declare Registers**:
    - In `cpu.sv`, add `logic [7:0] X, Y;`.
2. **Extend the Decoder**:
    - In the `always_comb` block, add the new opcodes (`0xAA`, `0xA8`, `0x8A`, `0x98`, `0xE8`, `0xC8`) to your `case` statement.
3. **Transfer Logic**:
    - `TAX`: `X <= A;`
    - `TXA`: `A <= X;`
4. **Arithmetic Logic**:
    - `INX`: `X <= X + 1;`
    - Note: These instructions usually update the Zero (Z) and Negative (N) flags, but we will handle flag implementation in Day 08.
5. **Update LCD Display**:
    - Add `debug_x` and `debug_y` ports to the CPU and display their values on the LCD.

## 💡 The Role of Index Registers

The X and Y registers shine when implementing **indexed addressing modes** (e.g., `LDA $1234,X`). This allows the CPU to efficiently read data from tables or arrays in memory.

## 🧪 Verification

- **Test Program**:

    ```asm
    LDA #$40
    TAX        ; X = 0x40
    INX        ; X = 0x41
    TXA        ; A = 0x41
    ```

- **FPGA**: Verify on the LCD that the X register changes as expected.

## 🎯 Next Step

In Day 08, we will significantly strengthen the CPU's computational power by integrating the **ALU (Arithmetic Logic Unit)** for full addition/subtraction and the **Processor Status (P) register** to bundle our status flags.
