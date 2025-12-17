# Day 05: Registers & VRAM Text Buffer

---

Day 05 introduces the 6502 register file and a simple VRAM text buffer that feeds the LCD pipeline.

## Learning goals

- Understand how the accumulator/index registers behave and why the `PC`, `SP`, and status flags are essential.
- Build a simple state machine that writes character codes into the VRAM buffer so that `day04_completed`'s LCD pipeline immediately shows readable text.
- Observe the register state and VRAM writes on the Tang Nano (or in simulation) while the LCD renders the buffer.

## Suggested RTL

- Reuse `day06_completed/cpu_registers.sv` for the register file, wiring it to debug LEDs or a UART-style monitor.
- Connect the `day09_completed/vram.sv`, `day09_completed/font_rom.sv`, and `day04_completed/lcd/lcd.sv` chain behind `day04_completed/top_9k.sv` or `top_20k.sv`.
- Implement a tiny sequencer in `top.sv` that iterates through a hard-coded string and writes it into the VRAM addresses exposed by `day09_completed/vram.sv`. Because the LCD pipeline already runs from Day 04, the screen will show your message.

## Hands-on

1. Load `day04_completed/hw_9k.gprj` and use `top_9k.sv` as the top module.
2. Add `day06_completed/cpu_registers.sv` plus a tiny FSM that drives VRAM writes from those registers.
3. Synthesize/download; the Tang Nano now shows Day 05 text while you inspect the registers via LEDs or simulation waveforms.
4. Optional: hook up UART/LED outputs to visualize register activity while the LCD displays the text buffer.

This step sets the scene for later days where the registers, ALU, and control unit will be wired together to form a fully marching CPU.
