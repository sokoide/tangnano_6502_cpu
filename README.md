# Build a 6502 CPU from Scratch on an FPGA

---

🌐 Available languages:
[English](./README.md) | [日本語](./README_ja.md)

## 📖 Project Overview

This project is a step-by-step learning curriculum designed to guide you through implementing the legendary 8-bit MOS 6502 CPU from scratch in SystemVerilog on an FPGA (Tang Nano 9K).

Ultimately, you will build a complete computer system on the FPGA, capable of running classic software like the Woz Monitor used in the Apple I.

## 🎯 Learning Objectives

-   **Fundamentals of Digital Circuit Design**: Understand the basics of combinational and sequential logic.
-   **Hardware Description Languages**: Master writing logic circuits using SystemVerilog.
-   **CPU Architecture**: Gain a deep understanding of CPU components—such as the program counter, registers, ALU, and instruction decoder—by implementing them one by one.
-   **Mastering Addressing Modes**: Learn how 6502's powerful addressing modes (indexed, indirect, etc.) are implemented in hardware.
-   **Hardware Debugging**: Learn debugging techniques using both simulation and on-chip hardware (an LCD).

## 📅 Curriculum Roadmap

The roadmap is divided into four main phases.

### Phase 1: Preparations (Day 01-04)

Setting up the environment and building the necessary debug tools.

|    Day     | Topic                 | What You'll Learn                                           |
| :--------: | :-------------------- | :---------------------------------------------------------- |
| **Day 01** | **Blinky LED**        | Environment setup and FPGA programming.                     |
| **Day 02** | **4-bit ALU**         | Combinational logic and basic logical operations.           |
| **Day 03** | **Traffic Light FSM** | Sequential logic and Finite State Machines.                 |
| **Day 04** | **Debug Foundation**  | **LCD display circuit (BSRAM/pROM) and base register set.** |

### Phase 2: Core CPU Implementation (Day 05-10)

Implementing core CPU functionality and visualizing internal state.

|    Day     | Topic                   | Instructions (Examples)                |
| :--------: | :---------------------- | :------------------------------------- |
| **Day 05** | **CPU Skeleton**        | `NOP` (Program Counter only).          |
| **Day 06** | **Memory Access**       | `LDA #imm` (Immediate load).           |
| **Day 07** | **Reg Transfers**       | `TAX`, `TAY`, `INX`, `INY`.            |
| **Day 08** | **Arithmetic (ALU)**    | `ADC`, `SBC` (NVZC Flag calculations). |
| **Day 09** | **Branching**           | `BNE`, `BEQ`, `BPL`, `BMI`.            |
| **Day 10** | **Stack & Subroutines** | `JSR`, `RTS`, `PHA`, `PLA`.            |

### Phase 3: Addressing Modes & Data Processing (Day 11-15)

Strengthening memory operations and complex processing.

|    Day     | Topic                 | What You'll Learn                           |
| :--------: | :-------------------- | :------------------------------------------ |
| **Day 11** | **Zero Page**         | Zero Page addressing (`LDA $00`) and RAM.   |
| **Day 12** | **Absolute**          | Absolute addressing (`LDA $1234`).          |
| **Day 13** | **Logic Ops**         | `AND`, `ORA`, `EOR`, `BIT` (Bitwise logic). |
| **Day 14** | **Shift & Rotate**    | `ASL`, `LSR`, `ROL`, `ROR`.                 |
| **Day 15** | **Compare & Inc/Dec** | `CMP`, `CPX`, `CPY`, `INC`, `DEC`.          |

### Phase 4: Advanced Addressing & Custom Extension (Day 16-20)

Complex addressing modes and hardware-native custom instructions.

|    Day     | Topic              | What You'll Learn                                                              |
| :--------: | :----------------- | :----------------------------------------------------------------------------- |
| **Day 16** | **Indexed**        | Indexed addressing (`LDA $1234,X` / `,Y`).                                     |
| **Day 17** | **Indirect**       | Indirect addressing (`JMP ($1234)`, `($00,X)`, `($00),Y`).                     |
| **Day 18** | **Custom Opcodes** | **`HLT` (Halt), `WVS` (Wait V-Sync), `CVR` (Clear VRAM), `IFO` (Debug Info).** |
| **Day 19** | **Integration**    | Integrating UART (Serial) and Timer peripherals.                               |
| **Day 20** | **Final Polish**   | Cycle optimization and final integration tests.                                |

---

### 🏁 Final Goal (Day 99)

-   **Nearly Complete 6502 CPU** (excluding full interrupts).
-   **Running Woz Monitor** or **Apple I Basic**.
-   Custom OS or programs controlling FPGA-native hardware.

## 🛠️ What You'll Need

-   **Hardware**: Sipeed Tang Nano 9K / 20K and 480x272 LCD panel.
-   **Software**: GOWIN EDA, verilator, GTKwave.

Check [Day 01](./day01/README.md) to get started!

---

[Full Instruction Set List (INSTRUCTIONS.md)](./day99_completed/docs/INSTRUCTIONS.md)
