# Tang Nano 6502 CPU with LCD Display

A SystemVerilog implementation of a 6502 instruction subset with custom extensions, along with an LCD controller, for Tang Nano 9K and 20K FPGA boards. This project features a modular architecture, a Verilator-based regression test suite, and support for custom assembly programs.

---

🌐 **Available languages:** [English](./README.md) | [日本語](./README_ja.md)

## 🚀 Quick Start

This guide explains how to build and deploy the project on Tang Nano 9K and 20K boards.

### Prerequisites

- **Hardware**: Tang Nano 9K or 20K
- **Software**: Gowin EDA, cc65, Make

### 1. Clone the Repository

```bash
git clone <repository-url>
cd tangnano_6502_cpu
```

### 2. Build and Download

The Makefile handles both Tang Nano variants. By default it targets **Tang Nano 9K**; pass `BOARD=20k` to build the 20K project.

```bash
# Tang Nano 9K (default)
make download

# Tang Nano 20K
make BOARD=20k download
```

## ✨ Features

- **6502 Instruction Subset**: Implements a subset of the 6502 instruction set plus custom extensions. Unimplemented opcodes stop with a FAULT; interrupts, decimal mode, and full cycle accuracy are out of scope (see `docs/INSTRUCTIONS.md`).
- **LCD Text Display**: Drives a 480x272 LCD to display 60x17 characters with hardware-accelerated font rendering.
- **Modular Design**: Clean separation between the CPU core, LCD controller, and memory systems.
- **Assembly Programming**: Integrated with the cc65 toolchain, with several example programs included.
- **Incremental Simulation**: `make test` runs CPU regression/contract, ALU, RAM, font, LCD, clock, and system tests, among others. Each test covers only its own scope; they do not cover the full 6502 instruction set or real hardware.
- **Multi-Board Support**: Easily switch between Tang Nano 9K and 20K targets.

## 📚 Documentation

For more details, refer to the documentation:

| Document                                                               | Description                                        |
| ---------------------------------------------------------------------- | -------------------------------------------------- |
| **[docs/DEVELOPER.md](./docs/DEVELOPER.md)**                           | Technical architecture, setup, and learning guide. |
| **[docs/README_architecture_en.md](./docs/README_architecture_en.md)** | In-depth details of the CPU architecture.          |
| **[docs/BUILD.md](./docs/BUILD.md)**                                   | Build system, tooling, and manual configuration.   |
| **[docs/INSTRUCTIONS.md](./docs/INSTRUCTIONS.md)**                     | Supported CPU instructions and custom extensions.  |
| **[docs/LCD.md](./docs/LCD.md)**                                       | LCD specifications and controller details.         |
| **[docs/CODING_STYLE.md](./docs/CODING_STYLE.md)**                     | SystemVerilog coding conventions.                  |
| **[docs/MODULE_MAP.md](./docs/MODULE_MAP.md)**                         | Code reading guide (top → cpu/lcd/ram).            |
| **[AGENTS.md](./AGENTS.md)**                                           | Guidelines for AI-assisted development.            |

## 🏗️ Project Structure

```bash
├── src/                    # SystemVerilog source files
│   ├── top_9k.sv          # 9K board wrapper (reset polarity, IO)
│   ├── top_20k.sv         # 20K board wrapper (reset polarity, IO)
│   ├── top_core.sv        # Top-level system integration (PLL, memory, LCD)
│   ├── cpu.sv             # Main CPU module (2-process FSM)
│   ├── cpu/               # cpu_types_pkg.sv, cpu_fsm_next_pkg.sv, legacy/
│   ├── cpu_alu.sv / cpu_decoder.sv / cpu_memory.sv
│   │                      # Standalone modules, not wired into cpu.sv
│   │                      # (exercised by tb_cpu_modules.sv only)
│   ├── lcd.sv             # LCD timing and character rendering
│   ├── tb_*.sv            # Testbenches
│   └── gowin_*/           # Board-specific PLL/BRAM/ROM primitives
├── sim/                   # Verilator stubs for Gowin primitives
├── include/               # Shared constants and auto-generated files
├── examples/              # 6502 assembly programs
└── docs/                  # Comprehensive documentation
```

## 🧠 6502 CPU Implementation

This project implements a documented binary-mode instruction subset with four custom opcodes. Unsupported instructions fault; this is not a cycle-exact or fully compatible NMOS 6502.

## 🧭 How this differs from day06-18 (educational CPU)

The day06-18 folders are an educational, step-by-step 6502 build-up (components → integration). For teaching, their module boundaries and control style intentionally prioritize clarity and incremental learning, so they do not necessarily match day99.

- **day06-18**: split into learning-friendly blocks (registers/ALU/decoder/memory interface/control unit) and evolve gradually.
- **day99**: an integrated, “real system” target (LCD + VRAM + custom opcodes). The CPU core is refactored around `cpu_ctx_t` and converged to a **2-process FSM** (compute `next` in `always_comb`, update `cur <= next` in `always_ff`) to make maintenance/refactors safer.

For education, keeping day06-18 as-is is usually better. If you want a more production-oriented reference for safe refactors and extensibility, day99’s 2-process FSM structure is the intended example.

See `day99_completed/docs/FSM.md` and `day99_completed/docs/README_architecture_en.md` for details.

### Custom Instructions

In addition to the standard 6502 instruction set, this CPU includes custom opcodes for efficient hardware interaction:

- `0xCF` **CVR**: Clear VRAM (hardware-accelerated screen clear).
- `0xDF` **IFO**: Info/Debug (display registers and memory).
- `0xEF` **HLT**: Halt CPU while keeping the LCD active.
- `0xFF` **WVS**: Wait for VSync to synchronize with display refresh.

### Memory Map

```text
0x0000-0x00FF  Zero Page (RAM)
0x0100-0x01FF  Stack (RAM)
0x0200-0x7BFF  Program/Data RAM
0x7C00-0x7FFF  VRAM shadow copy in RAM (CPU reads use this copy; writes to this range are ignored)
0x8000-0xDFFF  RAM mirror of 0x0000-0x5FFF (address bit 15 is not stored)
0xE000-0xE3FF  Text VRAM (CPU writes; reads are not mapped to VRAM)
0xE400-0xFBFF  RAM mirror of 0x6400-0x7BFF
0xFC00-0xFFFF  RAM mirror of 0x7C00-0x7FFF, backing VRAM shadow reads
```

The font ROM is a separate LCD-only resource and is not in the CPU address map. VRAM writes also update the RAM shadow copy at `0x7C00-0x7FFF`, which CPU reads access. Reads from `0xE000-0xE3FF` do not read VRAM. Writes through `0xFC00-0xFFFF` address the RAM mirror directly and do not update VRAM. This follows the decode in `src/cpu_memory.sv` and the 15-bit RAM ports in `src/ram.sv`.

**Display system:** 60 columns × 17 rows at 8 × 16 pixels per character on a 480 × 272 LCD. See [`docs/INSTRUCTIONS.md`](./docs/INSTRUCTIONS.md) for the supported instructions and memory behavior.

## 🎮 Programming Examples

The `examples/` directory contains several 6502 assembly programs. Use the `cc65` toolchain to build them.

```bash
# Install prerequisites (macOS)
brew install srecord cc65

# Install prerequisites (Linux)
sudo apt install srecord cc65

# Build and program an example (default: simple5).
# PROG selects any examples/*.s by name, without the .s extension.
cd day99_completed
make prog-download               # = prog + download, with the default program
make prog-download PROG=simple   # e.g. simple.s draws 'A' in the top-left corner

# Or regenerate the boot program only, then build/program separately
make prog PROG=simple
make download
```

The currently embedded program is recorded in the `// source:` line of
`include/boot_program.sv` and shown by `make help`.

**Online Tools:**

- [6502 Assembler](https://sokoide.github.io/6502-assembler/)
- [6502 Debugger](https://sokoide.github.io/6502-emulator/)

## 🧪 Testing and Simulation

`make test` runs the CPU regression/contract tests plus peripheral and integration simulations. The CPU regression suite (`tb_cpu_regression.sv`) verifies selected cases of the implemented subset. The static opcode audit in `docs/INSTRUCTIONS.md` and these local tests do not guarantee all inputs and boundary conditions; synthesis, place-and-route, and continuous operation on real hardware are separate validations.

```bash
# Run lint and format checks
make lint
make format
```

For detailed simulation instructions, see **[docs/DEVELOPER.md](./docs/DEVELOPER.md)**.

## 🤝 Contributing

Contributions are welcome! Please review the coding standards and development guidelines in the `docs/` directory.

## 📄 License

- **Font**: [Sweet16Font](https://github.com/kmar/Sweet16Font) (Boost Software License)
- **Project Code**: See individual file headers for licensing information.

## 🖼️ Example Output

![LCD Example](./docs/lcd.jpg)

_The system running a text display program on a 480x272 LCD module._
