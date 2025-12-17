# Day 10: 6502 Assembly Programming (Completed)

This directory holds the complete assembly exercises described in `day10/README_ja.md`/`day10/README.md`. The focus is on using the cc65 toolchain to build 6502 binaries that interact with the Tang Nano custom instructions and the LCD controller.

## Contents
- `hello_world.s`: clears VRAM with `CVR`, writes a fixed banner, and halts with `HLT`.
- `counter_display.s`: displays a hexadecimal counter plus simple animation logic on the LCD.
- `scroll_text.s`: scrolls a longer message with line clearing and delay helpers.
- `build.cfg`: cc65 linker configuration covering RAM, zero page, and VRAM regions.
- `Makefile`: builds every sample, emits Intel HEX files, and generates `include/boot_program.sv` via the helper script.
- `hex_to_sv.py`: converts Intel HEX into SystemVerilog `boot_memory` assignments so the ROM can be included in a top-level design.
- `include/boot_program.sv`: generated boot ROM for the default `hello_world` example (re-run `make include` after switching programs).

## Building the samples
### Requirements
Ensure the `ca65`/`ld65` assembler/linker and `srec_cat` are installed. On macOS you can install them via `brew install cc65 srecord`.

### Compile all programs
```bash
cd day10_completed
make
```
This depends on `build.cfg` and produces `.o`, `.bin`, and `.hex` artifacts for each sample (`hello_world`, `counter_display`, `scroll_text`).

### Build a single program
Override `PROGRAM` when invoking `make`:
```bash
make PROGRAM=scroll_text
```
This compiles only the chosen source and leaves the other build artifacts untouched.

## Generating a boot ROM include
The `include` target reuses the default `PROGRAM` (set to `hello_world` unless overridden).
```bash
make include
```
To generate a ROM for a different sample, pass `BOOT_PROGRAM`:
```bash
make include BOOT_PROGRAM=counter_display
```
This runs `hex_to_sv.py` on the corresponding `.hex` file and writes `include/boot_program.sv`, which in turn emits a simple `initial begin ... end` block that writes each non-zero byte into a `boot_memory` array.

## Using the ROM in a SystemVerilog project
Include the generated file and feed `boot_memory` into your 6502 core so it can fetch instructions starting at `$0200`. The ROOT-level Program Counter must be configured to jump into that area after reset (e.g. the sample `TOP` modules in older days). If you only need to inspect the boot sequence, read `include/boot_program.sv` to see exactly how the ASCII banner or scrolling text is laid out.

## Notes
- Each sample ends with `HLT` (`.byte $EF`) so the CPU halts when the demo finishes.
- `counter_display.s` and `scroll_text.s` rely heavily on zero-page temporaries at `$80`, `$81`, `$82`, and `$83`.
- The build process assumes the program loads at `$0200`; the `.hex` files offset addresses accordingly via `srec_cat`.
- Run `make clean` to remove generated binaries, hex files, and the `include/boot_program.sv` file (you can regenerate it later with `make include`).

## FPGA build/download
The Day 10 hardware example is now self-contained: it instantiates the Day 04–08 6502 CPU stack, plugs in a Day 07-style memory controller that intercepts `$E000–$E3FF` writes for the Day 09 VRAM/LCD pipeline, and feeds the generated assembly binary into the `boot_rom` module shown in `include/boot_program.sv`.

After running `make include` (or building one of the `.hex` targets), run one of the Gowin helpers to synthesize or flash the Tang Nano:

```bash
make build BOARD=9k
make download BOARD=20k
```

The `build`/`download` targets open `hw_9k.gprj`/`hw_20k.gprj`, compile `top_9k.sv`/`top_20k.sv`, and bundle the generated `boot_rom` along with the LCD pipeline so your program appears on the TFT.

Simulation is covered by the `test` target, which runs Verilator against `tb_tft.sv` and the entire RTL stack:

```bash
make test BOARD=9k
```

You still need `gw_sh`, `programmer_cli`, and `verilator` on your `PATH` when invoking `make build/download/test`, and the `include/boot_program.sv` file must exist before synthesizing or simulating the design.
