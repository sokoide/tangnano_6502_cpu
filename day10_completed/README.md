# Day 10: 480×272 RGB TFT Bring-up

---

🌐 Available languages:
[English](./README.md) | [日本語](./README_ja.md)

## What this day is

Day 10 uses the same **480×272 RGB TFT panel** as `day99_completed` (RGB565 + `LCD_DEN` + `LCD_CLK`).

This directory outputs **animated color bars** to validate:

- Pin wiring
- Pixel clock generation (~9MHz)
- `LCD_DEN` active area timing

## Build and Download

Use the Makefile to build the animated color bars for each board:

```bash
make BOARD=9k download
make BOARD=20k download
```

## Simulation (Verilator)

```bash
make test
```

This is a smoke test that checks `LCD_DEN` toggles and RGB outputs are non-zero at least once. In simulation, the PLL is stubbed (so `LCD_CLK` is effectively the same as `XTAL_IN`).

## Wiring

Use the same wiring as `day99_completed`:

- `LCD_CLK`, `LCD_DEN`
- `LCD_R[4:0]`, `LCD_G[5:0]`, `LCD_B[4:0]`

Pin assignments:

- `day10_completed/tft_9k.cst`
- `day10_completed/tft_20k.cst`

## Files

- `day10_completed/top.sv` (timing + animated bars)
- `day10_completed/tft_9k.gprj`, `day10_completed/tft_20k.gprj`
- `day10_completed/gowin_rpll_9k/gowin_rpll9.v`, `day10_completed/gowin_rpll_20k/gowin_rpll9.v`
