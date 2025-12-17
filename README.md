# Tang Nano 6502 CPU Learning Material

This is a 10-day step-by-step guide to learning about the 6502 CPU and LCD controller using the Tang Nano FPGA.

---

🌐 Available languages:
[English](./README.md) | [日本語](./README_ja.md)

## 📚 Learning Overview

Day 04 now focuses solely on the LCD display pipeline (see `day04/README.md` and `day04_completed/README.md`), while Days 05–10 build the 6502 CPU in front of that same display chain. The new `docs/day05-10_curriculum.md` plus the worksheets in `day05/`–`day10/` and their completed counterparts (`day05_completed/`–`day10_completed/`) describe how each lesson layers registers, decoder/ALU, memory, CPU, VRAM, and assembly tooling so the LCD always reflects your progress.

In this course, you will learn step-by-step from the basics of FPGAs and SystemVerilog to a complete 6502 CPU implementation. Each day balances theory and practice, allowing you to create projects that actually run on the Tang Nano.

## 🎯 Learning Objectives

- **FPGA Development**: Master the basic operations of the GoWin EDA tool and Tang Nano.
- **SystemVerilog**: Acquire skills from basic to advanced hardware description language.
- **6502 Architecture**: Understand a classic CPU architecture.
- **System Design**: Develop skills in integrated design of CPU, memory, and I/O.
- **Practical Development**: Gain experience with on-device testing and debugging.

## 🛠️ Required Hardware

- **Tang Nano 9K** or **Tang Nano 20K** FPGA development board
- **043026-N6(ML) 4.3" 480×272 LCD Module** (used from Day 09 onwards)
- USB-C cable (for programming)

**Tang Nano 9K:**

- FPGA: Gowin GW1NR-9C
- Logic Elements: 8,640 LUT4
- Memory: 468Kbit BSRAM
- PLL: 2
- I/O Pins: 63

**Tang Nano 20K:**

- FPGA: Gowin GW2AR-18C
- Logic Elements: 20,736 LUT4
- Memory: 828Kbit BSRAM
- PLL: 4
- I/O Pins: 107

### Board Selection

This project supports both boards. When using the provided Makefiles, you can specify the board:

```bash
make BOARD=9k   # Default
make BOARD=20k
```

## 💻 Required Software

- **GoWin EDA** (FPGA synthesis and place & route tool)
- **cc65** (6502 assembler, used on Day 10)
- **srecord** (binary conversion tool)
- **Make** (build system)

### Installation Instructions

**macOS:**

```bash
brew update
brew install -y srecord cc65 golang gtkwave verilator
```

**Linux (Ubuntu/Debian):**

```bash
sudo apt update
sudo apt install -y srecord cc65 golang gtkwave verilator libnss3 libnspr4 libasound2-dev
sudo apt install -y --reinstall \
  libfreetype6 \
  libfontconfig1
```

**GoWin EDA:**

- Download _Gowin V1.9.11.03 Education_ for macOS, Windows & Linux from <https://www.gowinsemi.com/ja/support/download_eda/>
  - Mac users only need macOS version of IDE which includes both compiler & programmer
  - Install macOS IDE into /Applications/GowinIDE.app
  - Windows users should install Windows version of IDE on Windows (compiler & programmer), Linux version of IDE (compiler) on WSLS. WSL cannot use the programmer -> needs Windows version of it
  - Install Linux IDE into $(HOME)/Gowin/IDE
  - Install Windows IDE into c:\Gowin
- macOS only
  - First time -> fails to open
  - macOS settings -> privacy -> scroll to the bottom -> allow anytime
  - Patch command line tool

```bash
GW=/Applications/GowinIDE.app/Contents/Resources/Gowin_EDA/IDE

for f in "$GW/bin/"*; do
  if file "$f" | grep -q executable; then
    install_name_tool \
      -add_rpath @executable_path/../lib \
      -add_rpath @executable_path/../Frameworks \
      "$f" 2>/dev/null
  fi
done

for f in "$GW/bin/"*; do
  if file "$f" | grep -q executable; then
    if otool -L "$f" | grep -q '/Library/Frameworks/Tcl.framework'; then
      install_name_tool \
        -change \
        /Library/Frameworks/Tcl.framework/Versions/8.6/Tcl \
        @rpath/Tcl.framework/Versions/8.6/Tcl \
        "$f"
    fi
  fi
done
```

- WSL only

```bash
# install IDE and programmer in $HOME/Gowin
cd $HOME/Gowin/IDE/lib
mv libfreetype.so.6 libfreetype.so.6.gowin.bak

# set env var
export QT_QPA_PLATFORM=minimal
export QT_OPENGL=software
export QT_XCB_GL_INTEGRATION=none
```

### macOS Tool Paths

If you installed Gowin EDA as an app bundle and the tools (`gw_sh`, `programmer_cli`) are not in your `PATH`, you can pass them explicitly to `make`:

```bash
make GWSH=/Applications/GowinIDE.app/Contents/Resources/Gowin_EDA/IDE/bin/gw_sh \
     PRG=/Applications/GowinIDE.app/Contents/Resources/Gowin_EDA/Programmer/bin/programmer_cli \
     download
```

## 📅 10-Day Learning Plan

### Day 01: Tang Nano + GoWin EDA Basics

**Topics:**

- Understanding the basic specifications of Tang Nano 9K/20K
- Basic operations and project creation in GoWin EDA
- First HDL project: Blinking LED (Hello World)
- Basics of constraint files (.cst)

**Deliverables:**

- A simple project that blinks an LED
- Mastery of basic synthesis, place & route, and programming procedures in GoWin EDA

**Practice Time:** Approx. 1 hour

---

### Day 02: SystemVerilog Basics (Combinational Circuits)

**Topics:**

- Basic syntax and module structure of SystemVerilog
- Designing combinational circuits (logic gates, decoders, multiplexers)
- Differentiating between `assign` and `always_comb`
- Basics of testbenches, Verilator for simulation

**Deliverables:**

- 7-segment decoder
- 4-bit ALU (addition, logical operations)

_This lesson feeds into the Day 05–Day 10 curriculum (`docs/day05-10_curriculum.md`). Keep the LCD pipeline alive so you can observe the addressing/decoder state on-screen._

_Day 10 ties the assembly toolchain into the record: use `docs/day05-10_curriculum.md` and `day05`–`day10` worksheets before running the `day10_completed/` demos that drive the LCD._

**Practice Time:** Approx. 2 hours

- Simulation waveform display
  ![Wave](./docs/day02_wave.png)

---

### Day 03: SystemVerilog Basics (Sequential Circuits)

**Topics:**

- Concepts of clock and reset
- Flip-flops and latches
- Register design using `always_ff`
- Basics of Finite State Machines (FSM)
- Counters and timer circuits

**Deliverables:**

- 8-bit counter
- LED PWM dimming controller
- Simple state machine

**Practice Time:** Approx. 2 hours

---

### Day 04: LCD

Day 04 is purely about bringing the Day 09 LCD pipeline forward: the PLL, VRAM/font ROM, and `lcd.sv` character renderer are already wired so the 480×272 panel displays text before the CPU exists. Follow `day04/README.md` and `day04_completed/README.md` for the hardware and simulation walkthroughs, and use `day04_completed/top_9k.sv` / `top_20k.sv` plus the shared `lcd/` RTL to drive the TFT connector directly.

---

## 🧩 Day 05–Day 10 Curriculum Flow

The second half of the course is a cohesive micro-curriculum that walks through the full CPU stack:

1. **Day 05 (Instruction Set & Addressing)** – Build the addressing mode calculator and classify every major instruction group so that opcodes can be mapped to hardware behaviors.
2. **Day 06 (Decoder + Control Unit)** – Translate the classification into concrete control signals, state transitions, and flag updates.
3. **Day 07 (Memory Interface + Stack)** – Design the bus interface, stack pointer control, and memory demultiplexing that the decoder drives.
4. **Day 08 (Integration & Testing)** – Hook registers, datapath, and ALU together, then validate the instruction set with simulation and on-board tests.
5. **Day 09 (LCD + VRAM Pipeline)** – Introduce the character display hardware and font ROM so the CPU can drive a 480×272 TFT.
6. **Day 10 (Assembly Applications)** – Use cc65 and the custom CVR/IFO/HLT/WVS instructions to put text on the LCD, scroll banners, and showcase animation.

Each day builds on the previous one, so by Day 10 you have a full 6502 CPU, VRAM pipeline, and assembly toolchain that can draw directly to the LCD. Consult `docs/day05-10_curriculum.md` and the new daily guides (`day05/README.md` through `day10/README.md`) for the recommended flow plus the corresponding completed versions (`day05_completed/`–`day10_completed/`).

## 📁 Directory Structure

```bash
├── README.md                       # This file (main guide)
├── day99_completed/                # Final completed product (for reference)
│
├── day01/                          # Learning directory
│   ├── README.md / README_ja.md    # Detailed explanation for the day
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
   - Learn the theory from `dayXX/README.md` (or `README_ja.md`).
   - Practice by implementing in `dayXX/` (some days provide templates; if not, use `dayXX_completed/` as your runnable starting point).
   - If you get stuck, refer to `dayXX_completed/`.

2. **On-Device Verification**:
   - Test each day's deliverables on the actual Tang Nano.
   - Experience the differences between simulation and real hardware.

3. **Step-by-Step Understanding**:
   - Make sure you understand the content of the previous day before moving on.
   - Don't hesitate to refer to the completed version if you don't understand something.

## 🎓 Skill Level After Completion

Upon completing this course, you will have acquired the following skills:

- **FPGA Development**: Ability to create and debug basic FPGA projects.
- **SystemVerilog**: Ability to design at an intermediate level of HDL.
- **CPU Design**: Understanding and ability to design a simple CPU architecture.
- **System Integration**: Ability to design a system combining CPU, memory, and I/O.
- **Practical Skills**: Ability to not only understand theory but also test and debug on real hardware.

## 📖 Reference Materials

- [6502.org](http://www.6502.org/) - Official 6502 CPU documentation
- [GoWin EDA Documentation](https://www.gowinsemi.com/) - FPGA development tool
- [SystemVerilog LRM](https://ieeexplore.ieee.org/document/8299595) - Language specification
- `day99_completed/docs/` - Detailed technical documents
- `day99_completed/docs/MODULE_MAP.md` - Code reading guide (top → cpu/lcd/ram)

## 🤝 Learning Support

Each day's directory contains detailed explanations and practice guides. If you get stuck:

1. Re-read the `README.md` (or `README_ja.md`) for that day.
2. Refer to the completed version in `dayXX_completed/`.
3. Check the technical documents in `day99_completed/docs/`.

---

## ✅ Reference Implementation (Day 99)

`day99_completed/` contains the complete integrated system (6502 CPU + LCD controller + build tooling). Start here if you want to run the finished design or cross-check your work.

```bash
cd day99_completed
make help
make
make download
```

**When you are ready to start learning, begin with `day01/README.md`!**
