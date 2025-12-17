# Day 19: Peripheral Integration (UART & Timers)

---

🌐 Available languages:
[English](./README.md) | [日本語](./README_ja.md)

## 📜 Overview

Even the fastest CPU is useless if it cannot communicate with the outside world. Today, we connect our CPU to a **UART (Serial Port)** and a **Hardware Timer** using **Memory-Mapped I/O (MMIO)**.

This allows your 6502 programs to print characters to your PC's terminal and track elapsed time with high precision.

## 🎯 Learning Objectives

-   **Memory-Mapped I/O (MMIO)**: Map specific memory addresses to hardware devices.
-   **UART Communication**: Learn how to control serial data transmission via registers.
-   **Timers**: Implement a hardware counter that increments with the clock and can be read by software.

## 🏗️ Example Memory Map

| Address Range   | Device      | Description                                |
| --------------- | ----------- | ------------------------------------------ |
| `$0000 - $07FF` | RAM         | Work area (2KB)                            |
| `$4000`         | UART Data   | Read for incoming, Write for outgoing data |
| `$4001`         | UART Status | Flags for Transmit Ready or Data Available |
| `$4010`         | Timer       | Counter (e.g., millisecond ticks)          |
| `$8000 - $FFFF` | ROM         | Program storage                            |

## 🛠️ Implementation Steps

1.  **Expand the Address Decoder**:
    -   In `top.sv` or your bus controller, add logic to route accesses to specific address ranges to your peripheral modules instead of RAM/ROM.
2.  **Connect the UART Module**:
    -   When `STA $4000` is executed, trigger the UART to transmit that byte over the physical TX pin.
3.  **Implement the Timer**:
    -   Create a counter that increments every 1ms (by dividing the system clock) and allow the CPU to read its value via `LDA $4010`.

## 🧪 Verification

-   **Test Program**:
    ```asm
    LDA #'H'     ; Character 'H'
    STA $4000    ; Send via UART
    LDA #'I'     ; Character 'I'
    STA $4000    ; Send via UART
    ```
-   **FPGA**: Use a serial terminal program (like PuTTY or `screen`) on your PC to confirm that the string "HI" is received from the FPGA.

## 🎯 Next Step

Day 20 is our final day! We will focus on **Optimization**, **Bug Fixing**, and **Final Polish** to complete your personalized 6502 computer system.
