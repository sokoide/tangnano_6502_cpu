# Day 04: LCD Pipeline Preview

---

🌐 Available languages:  
[English](./README.md) | [日本語](./README_ja.md)

## 🎯 Focus

Day 04 is dedicated to the LCD display pipeline that will reappear in Day 09.  
No CPU work today—just get eyes on the actual 480×272 TFT output so the later CPU exercises feel grounded in something visible.

- Inspect the 9 MHz pixel clock coming from `Gowin_rPLL9`.
- Step through the VRAM → font ROM → RGB output flow in `lcd.sv`.
- Use `top_9k.sv` / `top_20k.sv` to drive the TFT connector directly with the new LCD RTL.

## 📁 Key files in this lesson

- `top_9k.sv` / `top_20k.sv`: Board wrappers that wire the reset/clock inputs and expose the LCD pins.
- `lcd_demo.sv`: Lightweight top that chains `Gowin_rPLL9`, `lcd`, `font_rom`, and `vram`.
- `lcd/`: Reused Day 09 RTL (`lcd.sv`, `vram.sv`, `font_rom.sv`, plus `tb_tft.sv` for simulation).
- `include/consts.svh`: Timing constants for the 480×272 character grid.
- `gowin_rpll_9k/` and `gowin_rpll_20k/`: PLL modules that generate the pixel clock for each board.
- `tang_nano_9k.cst` / `tang_nano_20k.cst`: TFT pin assignments for RGB, DEN, CLK, XTAL, and ResetButton.

## 🛠️ Building and flashing

1. Open the `day04_completed/hw_9k.gprj` (or `hw_20k.gprj`) in GoWin and set `top_9k`/`top_20k` as the top module.
2. The `.gprj` already lists every file, so you can run synthesis/place-and-route directly.
3. The `tang_nano_*` `.cst` files already map the TFT connector (no `clk` or `led` pins are referenced any more).
4. Use the normal GoWin workflow to generate `.fs` and `programmer_cli` to download it—the TFT will immediately show text produced by VRAM.

## 🧪 Simulation

You can simulate this pipeline with Verilator:

```bash
cd day04_completed
verilator -Wall --sv --trace -cc lcd/tb_tft.sv lcd/lcd.sv lcd/vram.sv lcd/font_rom.sv sim/Gowin_rPLL9_stub.sv --exe -o Vtb_tft
./Vtb_tft
```

The bench asserts once `LCD_DEN` goes active and a non-black pixel appears.

## 💡 Learning notes

- `vram.sv` stores the text buffer and feeds character codes into `lcd.sv`.
- `font_rom.sv` converts the 8-bit codes into bitmaps.
- `lcd.sv` stitches characters together with pixel-accurate timing to drive RGB/DEN/CLK.
- The PLL ensures the pixel domain runs at 9 MHz just like on the real panel.

This preview lets you confirm the display pipeline before you tackle the CPU/VRAM integration in the subsequent days.
