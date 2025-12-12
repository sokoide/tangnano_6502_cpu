# Day 09: 480×272 RGB TFT Bring-up

---

🌐 Available languages:
[English](./README.md) | [日本語](./README_ja.md)

## What this day is

This day targets the **480×272 RGB TFT panel** (RGB565 + `LCD_DEN` + `LCD_CLK`) used in this repo’s later examples (e.g. `day99_completed`).

The bitstream shows **RGB color bars** so you can validate:
- Pin wiring
- Pixel clock generation
- `LCD_DEN` timing (SYNC-DE mode)

## LCD basics (480×272)

- Resolution: 480×272
- Interface: RGB565 (R=5bit, G=6bit, B=5bit)
- Control: `LCD_DEN` + `LCD_CLK` (no HS/VS pins in this example)
- Pixel clock: ~9MHz (generated from 27MHz via PLL)

## Build and Download

```bash
make BOARD=9k download
make BOARD=20k download
```

If the LCD stays blank, first confirm the **heartbeat LED** is blinking (pin is defined in `tft_*.cst`).

## Wiring

Use the same wiring as `day99_completed`:
- `LCD_CLK`, `LCD_DEN`
- `LCD_R[4:0]`, `LCD_G[5:0]`, `LCD_B[4:0]`

Pin assignments are in:
- `day09_completed/tft_9k.cst`
- `day09_completed/tft_20k.cst`

## Files

- `day09_completed/top.sv` (timing + color bars)
- `day09_completed/tft_9k.gprj`, `day09_completed/tft_20k.gprj`
- `day09_completed/gowin_rpll_9k/gowin_rpll9.v`, `day09_completed/gowin_rpll_20k/gowin_rpll9.v`

