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
`day10_completed` delegates the actual FPGA bitstream build to `day99_completed`. After running `make PROGRAM=<demo> include`, use the board-aware helper targets to compile or flash the Tang Nano with the freshly generated ROM:

```bash
make build BOARD=9k
make download BOARD=20k
```

Both targets temporarily replace `day99_completed/include/boot_program.sv` with the one generated here, invoke `make -C ../day99_completed BOARD=<board>` to build/program the bitstream, and restore the original include file afterwards. You still need the Gowin tools (`gw_sh`, `programmer_cli`) on your `PATH` as described in `day99_completed/Makefile`.
