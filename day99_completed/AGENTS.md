# Repository Guidelines

## Project Overview

This is a Tang Nano 9K/20K FPGA project implementing a 6502 CPU with LCD controller and BSRAM. It displays text on a 480x272 LCD module using a custom 6502 CPU implementation in SystemVerilog.

**Key Components:**

- 6502 CPU core (`src/cpu.sv`) with most standard instructions plus custom extensions
- LCD controller (`src/lcd.sv`) for 480x272 display timing
- Text-based VRAM system with font ROM
- Assembly program pipeline using cc65 toolchain

## Project Structure & Module Organization

- `src/`: SystemVerilog sources (`top_9k.sv`, `top_20k.sv`, `top_core.sv`, `platform_clocks.sv`, `reset_sync.sv`, `lcd.sv`, `cpu*.sv`, `ram.sv`) and testbenches `tb_*.sv`. Vendor IP lives under `src/gowin_*`.
- `include/`: Shared headers and generated files (`consts.svh`, `boot_program.sv` [generated], `cpu_ifo_auto_generated.svh` [generated], `cpu_tasks.svh`, `cpu_pkg.sv`).
- `examples/`: 6502 assembly programs and Makefile that generates `include/boot_program.sv`.
- `utils/`: Helper tools (e.g., `utils/hex_fpga/` Go converter).
- `impl/pnr/`: Build outputs (e.g., `lcd_cpu_bsram.fs`, `lcd_cpu_bsram.vo`).
- Docs: architecture and developer notes in `docs/` (`DEVELOPER.md`, `FSM.md`, `MODULE_MAP.md`, `LCD.md`, etc.).

## Build, Test, and Development Commands

- `make` — Run Gowin flow via `proj.tcl`; emits `impl/pnr/lcd_cpu_bsram.fs`.
- `make download` — Program Tang Nano (SRAM) via `programmer_cli`.
- `make clean` — Remove local build artifacts.
- `make test` — Run Verilator simulations (or `make BOARD=20k test`).
- `cd examples && make` — Assemble 6502 program and regenerate `include/boot_program.sv`. Edit `SRCS` in `examples/Makefile` to select the program.
- `make wave` — Open `gtkwave` on `waveform.vcd` (produce VCD in your simulator first).
- Board variant: target via `make BOARD=9k` (default) or `make BOARD=20k` (`top_9k.sv` / `top_20k.sv` handle reset polarity; `platform_clocks.sv` configures 27MHz/40.5MHz).

## Architecture

### Memory Map

- `0x0000-0x00FF`: Zero Page (256B)
- `0x0100-0x01FF`: Stack (256B)
- `0x0200-0x7BFF`: RAM (30.5KB) - Program starts at 0x0200
- `0x7C00-0x7FFF`: Shadow VRAM (1KB) - CPU-readable copy of VRAM
- `0xE000-0xE3FF`: Text VRAM (1KB) - Write-only for CPU
- `0xF000-0xFFFF`: Font ROM (4KB) - Not CPU accessible, used by LCD controller

### Custom 6502 Instructions

- `0xCF`: CVR - Clear VRAM
- `0xDF`: IFO - Info (show registers and memory for debugging)
- `0xEF`: HLT - Halt CPU
- `0xFF`: WVS - Wait for VSync

### Text Display

- 60 columns × 17 rows text mode
- 16×8 pixel font characters
- Font data from Sweet16Font (boost licensed)

## Development Workflow

1. **Assembly Development**: Edit `.s` files in `examples/`, modify `examples/Makefile` SRCS variable
2. **Auto-generation**: Assembly programs are converted to SystemVerilog via `utils/hex_fpga/` tool
3. **FPGA Build**: `include/boot_program.sv` is auto-generated and included in synthesis
4. **Device Configuration**: Select board with `BOARD=9k` (default) or `BOARD=20k` in `make`

## Coding Style & Naming Conventions

- SystemVerilog: 4-space indent, no tabs; one module per file; keep concise header comments (matches `verible-verilog-format`).
- Names: files/modules `lower_snake_case`; constants/parameters `UPPER_SNAKE_CASE`; signals `lower_snake_case`; testbenches `tb_*.sv`.
- Avoid magic numbers—use `include/consts.svh`. Keep interfaces and timing explicit.
- Do not edit generated/vendor files: `include/boot_program.sv`, `include/cpu_ifo_auto_generated.svh`, `src/gowin_*/`.

## Testing Guidelines

- Testbenches: `tb_cpu.sv`, `tb_lcd.sv`, `tb_top.sv`, `tb_lcd_pipeline.sv`, `tb_diag_simple5.sv`. Run with Verilator via `make test`; emit `waveform.vcd` for inspection and `make wave`.
- Aim for coverage of CPU instruction paths, memory, and LCD timing. Add minimal repros under `examples/` when fixing bugs.
- Optional: DSIM Studio on Linux/Windows x64 via `lcd_cpu_bsram.dpf`.

## Commit & Pull Request Guidelines

- Commit style: conventional prefixes (`feat`, `fix`, `refactor`, `docs`, `add`, `remove`, `update`, `improve`) with day reference and hardware verification status in the commit body.
- PRs must include: clear description (what/why), affected modules, testing evidence (VCD snapshot or hardware notes/logs), and reproduction steps. Link related issues.

## Configuration Tips

- Gowin EDA paths in `Makefile` (`GWSH`, `PRG`) target macOS defaults (`/Applications/GowinIDE.app/`). Adjust environment or paths if installed elsewhere.
