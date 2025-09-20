# Tang Nano 6502 CPU Learning Material

This is a 10-day step-by-step guide to learning about the 6502 CPU and LCD controller using the Tang Nano FPGA.

---

🌐 Available languages:
[English](./README.md) | [日本語](./README_ja.md)

## 📚 Learning Overview

In this course, you will learn step-by-step from the basics of FPGAs and SystemVerilog to a complete 6502 CPU implementation. Each day balances theory and practice, allowing you to create projects that actually run on the Tang Nano.

## 🎯 Learning Objectives

-   **FPGA Development**: Master the basic operations of the GoWin EDA tool and Tang Nano.
-   **SystemVerilog**: Acquire skills from basic to advanced hardware description language.
-   **6502 Architecture**: Understand a classic CPU architecture.
-   **System Design**: Develop skills in integrated design of CPU, memory, and I/O.
-   **Practical Development**: Gain experience with on-device testing and debugging.

## 🛠️ Required Hardware

-   **Tang Nano 9K** or **Tang Nano 20K** FPGA development board
-   **043026-N6(ML) 4.3" 480×272 LCD Module** (used from Day 09 onwards)
-   USB-C cable (for programming)

## 💻 Required Software

-   **GoWin EDA** (FPGA synthesis and place & route tool)
-   **cc65** (6502 assembler, used on Day 10)
-   **srecord** (binary conversion tool)
-   **Make** (build system)

### Installation Instructions

**macOS:**

```bash
brew install srecord cc65
```

**Linux (Ubuntu/Debian):**

```bash
sudo apt install srecord cc65 golang gtkwave verilator
```

**GoWin EDA:** Download and install from the official website.

## 📅 10-Day Learning Plan

### Day 01: Tang Nano + GoWin EDA Basics

**Topics:**

-   Understanding the basic specifications of Tang Nano 9K/20K
-   Basic operations and project creation in GoWin EDA
-   First HDL project: Blinking LED (Hello World)
-   Basics of constraint files (.cst)

**Deliverables:**

-   A simple project that blinks an LED
-   Mastery of basic synthesis, place & route, and programming procedures in GoWin EDA

**Practice Time:** Approx. 2-3 hours

---

### Day 02: SystemVerilog Basics (Combinational Circuits)

**Topics:**

-   Basic syntax and module structure of SystemVerilog
-   Designing combinational circuits (logic gates, decoders, multiplexers)
-   Differentiating between `assign` and `always_comb`
-   Basics of testbenches

**Deliverables:**

-   7-segment decoder
-   4-bit ALU (addition, logical operations)

**Practice Time:** Approx. 3-4 hours

---

### Day 03: SystemVerilog Basics (Sequential Circuits)

**Topics:**

-   Concepts of clock and reset
-   Flip-flops and latches
-   Register design using `always_ff`
-   Basics of Finite State Machines (FSM)
-   Counters and timer circuits

**Deliverables:**

-   8-bit counter
-   LED PWM dimming controller
-   Simple state machine

**Practice Time:** Approx. 3-4 hours

---

### Day 04: 6502 CPU Architecture Overview

**Topics:**

-   History and features of the 6502 CPU
-   Register set (A, X, Y, SP, PC, P)
-   Memory map and addressing
-   Instruction fetch, decode, and execute cycle
-   Flag register and its operation

**Deliverables:**

-   SystemVerilog model of the 6502 register set
-   Simple instruction decoder (for a subset of instructions)

**Practice Time:** Approx. 2-3 hours

---

### Day 05: 6502 Instruction Set and Addressing Modes

**Topics:**

-   Detailed explanation of the 13 addressing modes of the 6502
-   Classification and operation of major instruction groups
-   Load/store instructions (LDA, STA, etc.)
-   Arithmetic instructions (ADC, SBC, AND, etc.)
-   Branch and jump instructions (BEQ, JMP, JSR, etc.)

**Deliverables:**

-   Addressing mode calculator
-   Decode table for major instructions

**Practice Time:** Approx. 3-4 hours

---

### Day 06: CPU Implementation Part 1 - Decoder and ALU

**Topics:**

-   Detailed design of the instruction decoder
-   Implementation of the Arithmetic Logic Unit (ALU)
-   Flag calculation logic (N, Z, C, V)
-   Concept of micro-instruction control

**Deliverables:**

-   Complete instruction decoder module
-   6502-compatible ALU module
-   Flag generation logic

**Practice Time:** Approx. 4-5 hours

---

### Day 07: CPU Implementation Part 2 - Memory Interface

**Topics:**

-   Memory bus interface design
-   Implementation of stack operations
-   Optimization of zero-page access
-   Basics of memory-mapped I/O

**Deliverables:**

-   Memory controller module
-   Stack pointer control logic
-   Address generation unit

**Practice Time:** Approx. 4-5 hours

---

### Day 08: CPU Implementation Part 3 - Integration and Testing

**Topics:**

-   Integration of the CPU core
-   Instruction cycle control
-   Testing with basic 6502 programs
-   Debugging techniques and simulation

**Deliverables:**

-   A functional 6502 CPU core
-   Verification of the basic instruction set
-   A set of test programs

**Practice Time:** Approx. 5-6 hours

---

### Day 09: LCD Control and System Integration

**Topics:**

-   Principles of LCD timing control
-   RGB signal generation and VGA/LCD output
-   Design of a character display system
-   Implementation of VRAM (Video RAM)
-   How to use a font ROM

**Deliverables:**

-   LCD controller module
-   System with character display functionality
-   Character output at 480×272 resolution

**Practice Time:** Approx. 4-5 hours

---

### Day 10: Assembly Programming and Applications

**Topics:**

-   How to use the cc65 assembler
-   Practical 6502 assembly programming
-   Utilizing custom instructions (CVR, IFO, HLT, WVS)
-   Full system testing and debugging
-   Creating application programs

**Deliverables:**

-   "Hello World" display program
-   Scrolling text display
-   Interactive demo program

**Practice Time:** Approx. 3-4 hours

---

## 📁 Directory Structure

```
├── README_ja.md                    # This file (main guide)
├── day99_completed/                # Final completed product (for reference)
│
├── day01/                          # Learning directory
│   ├── README_ja.md               # Detailed explanation for the day
│   └── (Basic templates)
├── day01_completed/               # Complete version
│   └── (The complete project for the day)
│
├── day02/
├── day02_completed/
│
... (Similarly for day03 to day10)
```

## 🚀 How to Proceed with Learning

1. **Daily Study**:

    - Learn the theory from `dayXX/README_ja.md`.
    - Practice with the templates in `dayXX/`.
    - If you get stuck, refer to `dayXX_completed/`.

2. **On-Device Verification**:

    - Test each day's deliverables on the actual Tang Nano.
    - Experience the differences between simulation and real hardware.

3. **Step-by-Step Understanding**:
    - Make sure you understand the content of the previous day before moving on.
    - Don't hesitate to refer to the completed version if you don't understand something.

## 🎓 Skill Level After Completion

Upon completing this course, you will have acquired the following skills:

-   **FPGA Development**: Ability to create and debug basic FPGA projects.
-   **SystemVerilog**: Ability to design at an intermediate level of HDL.
-   **CPU Design**: Understanding and ability to design a simple CPU architecture.
-   **System Integration**: Ability to design a system combining CPU, memory, and I/O.
-   **Practical Skills**: Ability to not only understand theory but also test and debug on real hardware.

## 📖 Reference Materials

-   [6502.org](http://www.6502.org/) - Official 6502 CPU documentation
-   [GoWin EDA Documentation](https://www.gowinsemi.com/) - FPGA development tool
-   [SystemVerilog LRM](https://ieeexplore.ieee.org/document/8299595) - Language specification
-   `day99_completed/docs/` - Detailed technical documents

## 🤝 Learning Support

Each day's directory contains detailed explanations and practice guides. If you get stuck:

1. Re-read the `README_ja.md` for that day.
2. Refer to the completed version in `dayXX_completed/`.
3. Check the technical documents in `day99_completed/docs/`.

---

**When you are ready to start learning, begin with `day01/README_ja.md`!**
