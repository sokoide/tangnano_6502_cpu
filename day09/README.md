# Day 09: VRAM + LCD Display System

---

Day 09 focuses on the VRAM buffer, font ROM, and TFT timing chain that translate memory writes into characters on the LCD.

## Learning goals

- Dive into `day09_completed/vram.sv`, `font_rom.sv`, and `lcd.sv` to understand how the VRAM address space is traversed and pixels are emitted.
- Use the completed modules to generate a static or scrolling banner that proves the character pipeline is working.
- Keep monitoring the VRAM contents on the LCD so you can see the effect of every write cycle.

## Suggested RTL

- Sensibly gate writes to the VRAM range (`0xE000`–`0xE3FF`) from your Day 08 CPU core or from a simple sequencer.
- Let the Day 04 LCD pipeline (`day04_completed` resources) drive the actual panel so the characters appear in real time.
- Optionally extend `vram.sv` to accept DMA-style bursts or simple hardware cursors for more advanced demos.

## Hands-on

1. Use the `day09_completed` Makefile to synthesize the VRAM/LCD design and confirm it lights up your panel with a sample message.
2. If you prefer reading via simulation, run `day09_completed/tb_tft.sv` with Verilator; it asserts once non-black pixels appear.
3. When the VRAM pipeline is stable, start injecting characters from the CPU (Day 08) so the display is genuinely driven by code.
