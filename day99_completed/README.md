# Tang Nano 6502 CPU with LCD Display

A complete SystemVerilog implementation of a 6502 microprocessor with an LCD controller for Tang Nano FPGA boards. This project features a modular architecture, comprehensive testing, and support for custom assembly programs.

---

🌐 **Available languages:** [English](./README.md) | [日本語](./README_ja.md)

## 🚀 Quick Start

This guide explains how to build and deploy the project on Tang Nano 9K and 20K boards.

### Prerequisites

-   **Hardware**: Tang Nano 9K or 20K
-   **Software**: Gowin EDA, cc65, Make

### 1. Clone the Repository

```bash
git clone <repository-url>
cd tangnano_6502_cpu
```

### 2. Modify Files for 20K

By default, the project targets the **Tang Nano 9K**. If you are using a **Tang Nano 20K**, please make the following modifications.

-   For Tang Nano 20K

    -   Update the following files

    -   `lcd_cpu_bsram.gprj`

        ```xml
        <!-- Tang Nano 9K -->
        <!-- <Device name="GW1NR-9C" pn="GW1NR-LV9QN88PC6/I5">gw1nr9c-004</Device> -->
        <!-- Tang Nano 20K -->
        <Device name="GW2AR-18C" pn="GW2AR-LV18QN88C8/I7">gw2ar18c-000</Device>

        <!-- Tang Nano 9K -->
        <!-- <File path="src/lcd_cpu_bsram_9K.cst" type="file.cst" enable="1"/>
        <File path="src/gowin_rpll_9K/gowin_rpll40.v" type="file.verilog" enable="1"/>
        <File path="src/gowin_rpll_9K/gowin_rpll9.v" type="file.verilog" enable="1"/> -->
        <!-- Tang Nano 20K -->
        <File path="src/lcd_cpu_bsram_20K.cst" type="file.cst" enable="1"/>
        <File path="src/gowin_rpll_20K/gowin_rpll40.v" type="file.verilog" enable="1"/>
        <File path="src/gowin_rpll_20K/gowin_rpll9.v" type="file.verilog" enable="1"/>
        ```

    -   `src/top.sv`

    ```systemverilog
        // Tang Nano 9K:
        //  wire rst_n = ResetButton;
        // Tang Nano 20K:
        wire rst_n = !ResetButton;
    ```

### 3. Build and Download

The Makefile automates the build process.

```bash
# Build and download for Tang Nano 9K (default)
make download
```

If you are using a **Tang Nano 20K**, use the `BOARD` variable.

```bash
# Build and download for Tang Nano 20K
make BOARD=20k download
```

## ✨ Features

-   **Complete 6502 CPU**: Implements the standard instruction set with custom extensions for hardware control.
-   **LCD Text Display**: Drives a 480x272 LCD to display 60x17 characters with hardware-accelerated font rendering.
-   **Modular Design**: Clean separation between the CPU core, LCD controller, and memory systems.
-   **Assembly Programming**: Integrated with the cc65 toolchain, with several example programs included.
-   **Comprehensive Testing**: Includes unit tests, integration suites, and simulation testbenches.
-   **Multi-Board Support**: Easily switch between Tang Nano 9K and 20K targets.

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
| **[CLAUDE.md](./CLAUDE.md)**                                           | Guidelines for AI-assisted development.            |

## 🏗️ Project Structure

```
├── src/                    # SystemVerilog source files
│   ├── cpu.sv             # Main CPU module
│   ├── lcd.sv             # LCD timing and character rendering
│   ├── top.sv             # Top-level system integration
│   └── gowin_*/           # Board-specific PLL configurations
├── include/               # Shared constants and auto-generated files
├── examples/              # 6502 assembly programs
├── tests/                 # Testbench files
└── docs/                  # Comprehensive documentation
```

## 🧠 6502 CPU Implementation

### Custom Instructions

In addition to the standard 6502 instruction set, this CPU includes custom opcodes for efficient hardware interaction:

-   `0xCF` **CVR**: Clear VRAM (hardware-accelerated screen clear).
-   `0xDF` **IFO**: Info/Debug (display registers and memory).
-   `0xEF` **HLT**: Halt CPU while keeping the LCD active.
-   `0xFF` **WVS**: Wait for VSync to synchronize with display refresh.

### Memory Map

```
0x0000-0x01FF  Zero Page & Stack (512B)
0x0200-0x7BFF  Program RAM (30.5KB)
0x7C00-0x7FFF  Shadow VRAM (1KB, read-only)
0xE000-0xE3FF  VRAM (1KB, write-only)
0xF000-0xFFFF  Font ROM (4KB, for display controller)
```

**Display System:**

-   60×17 character text mode (480×272 pixels)
-   16×8 pixel font characters with [Sweet16Font](https://github.com/kmar/Sweet16Font) (Boost licensed)
-   Hardware accelerated character rendering

Complete instruction reference and addressing modes available in [docs/README_architecture_en.md](./docs/README_architecture_en.md).

## 🎮 Programming Examples

The `examples/` directory contains several 6502 assembly programs. Use the `cc65` toolchain to build them.

```bash
# Install prerequisites (macOS)
brew install srecord cc65

# Install prerequisites (Linux)
sudo apt install srecord cc65

# Build and run an example
cd examples
make clean && make          # Builds simple5.s by default
cd ..
make download               # Program the FPGA with the example
```

**Online Tools:**

-   [6502 Assembler](https://sokoide.github.io/6502-assembler/)
-   [6502 Debugger](https://sokoide.github.io/6502-emulator/)

## 🧪 Testing and Simulation

The project includes a comprehensive testing infrastructure.

```bash
# Run lint and format checks
make lint
make format
```

For detailed simulation instructions, see **[docs/DEVELOPER.md](./docs/DEVELOPER.md)**.

## 🤝 Contributing

Contributions are welcome! Please review the coding standards and development guidelines in the `docs/` directory.

## 📄 License

-   **Font**: [Sweet16Font](https://github.com/kmar/Sweet16Font) (Boost Software License)
-   **Project Code**: See individual file headers for licensing information.

## 🖼️ Example Output

![LCD Example](./docs/lcd.jpg)

_The system running a text display program on a 480x272 LCD module._
