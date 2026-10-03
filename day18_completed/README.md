# Day 18: Custom Instructions (WVS, CVR, IFO, HLT)

---

🌐 Available languages:
[English](./README.md) | [日本語](./README_ja.md)

## 📜 Overview

One of the best parts of building your own CPU on an FPGA is adding "original instructions" that don't exist in standard architectures. Today, we will use unused 6502 opcodes to implement **custom instructions** that directly control the FPGA hardware.

This allows the program to halt the CPU, control VRAM writing, and perform other unique operations.

## 🧠 Memory Model Note

From Day 10 onward, the program runs from RAM backed by Gowin BSRAM (`ram.sv`), not the simple ROM used in earlier days.

## 🎯 Learning Objectives

- **Defining Custom Instructions**: How to use unused opcodes.
- **Hardware Interfacing**: Understanding how instruction execution affects external hardware (like LCD drivers).
- **Architecture Flexibility**: Learning the concept of "accelerators" where software directly triggers hardware functions.

## 🏗️ Custom Instructions to Implement

```mermaid
graph TD
    CPU[CPU Execution] --> Fetch["Fetch 0xFF (WVS)"]
    Fetch --> Wait{Wait for VSync?}
    VSync[VSync Signal] --> Wait
    Wait -- No --> Wait
    Wait -- Yes --> Next[Next Instruction]
```

| Opcode | Mnemonic     | Description                                                               |
| :----: | ------------ | ------------------------------------------------------------------------- |
| `0xFF` | `WVS #count` | **Wait for V-Sync**: In Day 18, operand N waits for N VSync rising edges. |
| `0xCF` | `CVR`        | **Clear VRAM**: Request the peripheral circuit to clear VRAM.             |
| `0xDF` | `IFO`        | **Info**: Request the peripheral circuit to display debug information.    |
| `0xEF` | `HLT`        | **Halt CPU**: Stop the CPU while the LCD controller keeps running.        |

`CVR` and `IFO` are request signals from the CPU to the peripheral circuit. The CPU instruction execution cycle and the time needed for VRAM clearing or character rendering are separate things.

> [!NOTE]
> Through Day 17 the CPU was throttled via `pc_enable` in `lcd_demo.sv` for debugging. In Day 18 the CPU runs continuously (`pc_enable = 1`) and synchronizes with the display in software via the `WVS` instruction. The CPU/memory clock (`MEMORY_CLK`) in Day 18 is 27MHz on the 9K board only (Day 04-17 used 40.5MHz) and 40.5MHz on the 20K board (see `day18_*.sdc`).

## 🛠️ Implementation Steps

1. **Opcode Assignment**:
    - Define new instructions in `opcodes.svh`.
2. **Decoder and Execution Logic**:
    - Implement `WVS` as an opcode plus a 1-byte immediate operand. In the Day 18 spec, operand N waits for N rising edges (Day 99 waits for N+1, so beware the spec difference).
3. **External Signal Definition**:
    - Add `vsync` input and notification signals to the `cpu` module's ports and connect them to external hardware.

## 🧪 Verification

Run the completed tests in this directory with `make test`. `test` runs `test-cpu` (CPU logic test with the shared testbench `../day18/sim/tb_cpu.sv`), `test-lcd` (TFT smoke test), `test-lcd-pipeline`, `test-sync`, `test-system` and `test-vsync` in order. Passing the tests verifies the tested scope only and does not guarantee untested instructions or real-hardware behavior.

- **Completed `rom.sv` program**:

    ```asm
    LDA #$01
    STA $00    ; $00 = $01
    LDA #$02
    STA $01    ; $01 = $02
    LDA #$03
    STA $02    ; $02 = $03
    LOOP:      ; $020C
    CLC
    ADC #$01   ; A += 1
    INX
    INY
    IFO        ; request debug display
    WVS #$3A   ; wait for 58 VSyncs (approx. 1 second)
    JMP LOOP
    ```

`make test-cpu` runs the shared testbench `../day18/sim/tb_cpu.sv`. The testbench injects a different program using CVR / `WVS #2` / IFO / `JSR` / `HLT`, so it is separate from the completed ROM listing above.

- **FPGA**: After `make download`, confirm that the IFO display refreshes about once per second and the A/X/Y registers count up on the LCD.
  The right column of the memory area is a day99-style LED view: memory row `0x0k` shows byte `$0k` as eight `@` (1) / space (0) cells, bit 7 down to bit 0 under the `76543210` header, with a `0x0k:` label to the left of each row.

## 🎉 Congratulations

You have successfully completed the entire 18-day curriculum!
By building a 6502 CPU from scratch on an FPGA and even adding your own custom instructions, you have gained deep knowledge that bridges the gap between hardware and software.

This journey doesn't end here. You now have the foundation to optimize this CPU, add more instructions, or even dive into entirely new architectures. The possibilities are endless!

Wishing you the very best in your future engineering endeavors!
