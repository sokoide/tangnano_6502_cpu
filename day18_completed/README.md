# Day 18: Custom Extended Instructions (WVS, CVR, IFO)

---

🌐 Available languages:
[English](./README.md) | [日本語](./README_ja.md)

## 📜 Overview

One of the best parts of building a CPU on an FPGA is the ability to add "your own instructions" that don't exist in the original architecture. Today, we will use unused 6502 opcodes to implement **Custom Instructions** that directly control our FPGA hardware.

These opcodes will allow our programs to stop the CPU, synchronize with display updates, or reset hardware states directly.

## 🎯 Learning Objectives

-   **Defining Custom Opcodes**: How to utilize unused opcode slots in an architecture.
-   **Hardware-Software Coupling**: See how an instruction execution can trigger signals for external modules (like an LCD driver).
-   **Architectural Flexibility**: Understand "accelerator" concepts where software triggers complex hardware functions.

## 🏗️ Custom Instructions to Implement

| Opcode | Mnemonic | Description                                                     |
| :----: | -------- | --------------------------------------------------------------- |
| `0x12` | `WVS`    | **Wait for V-Sync**: Wait for next vertical sync (for display). |
| `0x22` | `CVR`    | **Clear VRAM**: Clear VRAM or fill with a specific color.       |
| `0x32` | `IFO`    | **Info**: Display debug info (registers, PC, etc.) on screen.   |

> [!NOTE]
> Previously, the CPU speed was intentionally throttled for debugging. With the `WVS` instruction, we can now synchronize with the display in software, so the CPU now runs at the full FPGA clock speed (approx. 40MHz).

## 🛠️ Implementation Steps

1.  **Assign Opcodes**:
    -   Define the new opcodes in `opcodes.svh`. We typically choose slots that are undefined in the standard 6502 (like the `0x02` family).
2.  **Decoder & Execution Logic**:
    -   Add these to your `case` statement in `cpu.sv`.
    -   Example: For `WVS`, pause PC increments and state transitions until an external `vsync_in` signal is pulsed.
3.  **Define External Signals**:
    -   Add ports to the `cpu` module to communicate these "triggers" to the rest of the FPGA.

## 🧪 Verification

-   **Test Program**:
    ```asm
    LDA #$AA
    STA $4000  ; Draw something
    WVS        ; Wait for screen refresh
    HLT        ; Stop execution
    ```
-   **FPGA**: Confirm on the LCD that the Program Counter stops and the hardware responds to the custom triggers as programmed.

## 🎯 Next Step

In Day 19, we will integrate **Peripherals** like a UART (Serial Port) and Timers to let our CPU communicate with the outside world.
