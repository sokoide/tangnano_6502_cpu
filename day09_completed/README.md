# Day 09: VRAM Character Display

This completed project implements the LCD character-display system described in `day09/README.md`. It drives the 480×272 RGB TFT panel by rendering characters from a small VRAM buffer and a custom font ROM, so the finished build shows a static message generated entirely through text memory.

## Project Layout
- `hw_9k.*`, `hw_20k.*`: Gowin project files for the Tang Nano 9K/20K that target the `top` wrappers below.
- `top_9k.sv`, `top_20k.sv`: Board wrappers that wire the reset polarity and expose the display signals.
- `top_core.sv`: Instantiates the 9 MHz PLL, the `lcd` text renderer, the font ROM, and the VRAM buffer.
- `lcd.sv`: Character display controller adapted from Day 99 that fetches codes from VRAM and reads the font ROM.
- `vram.sv`: A simple dual-port buffer pre-filled with the “VRAM TEXT / CHAR LCD / FPGA SHOW” message.
- `font_rom.sv`: A synthesizable font ROM for the limited alphabet used by the demo.
- `sim/tb_tft.sv`: Smoke-test bench that ensures the display produces active video and non-black pixels.

## Building for FPGA
```bash
cd day09_completed
make BOARD=9k      # builds for Tang Nano 9K
make BOARD=20k     # builds for Tang Nano 20K
```
The `Makefile` mirrors `day08_completed/Makefile`: it finds `gw_sh`/`programmer_cli`, opens the `hw_*` `.gprj`, and copies out the `.fs` bitstream for each board. The project uses `top` as the entry point, so the Gowin GUI must target `top` when you open `hw_9k.gprj`/`hw_20k.gprj`.

## Programming the board
```bash
make download BOARD=9k
```
The download target programs the SRAM (11 overrides) with the newly generated `.fs` file using `programmer_cli`. You still need the Gowin toolchain on your `PATH`.

## Simulation
```bash
make sim BOARD=9k
```
Runs `tb_tft.sv` with Verilator. The best-case output should see `LCD_DEN` assert and non-black RGB values when the text is rendered.

## Notes
- The text renderer fetches characters at `$E000` (VRAM) and maps them through a small font ROM, matching the architecture described in the Day 09 guide.
- The VRAM module is pre-loaded with a friendly message, so the demo shows a readable string even without a CPU driving the buffer.
- `font_rom.sv` is intentionally small—only the letters that appear in the demo are defined, and all other codes produce blanks.
