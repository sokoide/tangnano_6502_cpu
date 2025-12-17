# Day 06: Decoder & ALU

---

Day 06 combines the opcode decoder with the ALU so the processor can interpret instructions.

## Learning goals

- Feed opcode patterns into `day06_completed/cpu_decoder.sv` and observe the decoded control signals.
- Drive the `day06_completed/cpu_alu.sv` with register outputs plus immediate operands.
- Keep the LCD pipeline from Day 04 alive so any result stored into VRAM is visible immediately.

## Suggested RTL

- Build a lightweight testbench (or interactive top) that sequences through canonical opcodes, feeding them to the decoder and ALU.
- Route the ALU outputs through `day08_completed/cpu_registers.sv` (or the standalone register file) so you can display results on both LEDs and the LCD text buffer: have the top module write decoded results or status flags into VRAM as ASCII digits.
- Use `day09_completed/vram.sv` and `day04_completed/lcd/lcd.sv` just as in Day 05 so the screen reflects ALU work.

## Hands-on

1. Keep `top_9k.sv`/`top_20k.sv` on the Tang Nano target and add your Day 06 top module.
2. Cycle through different opcode encodings (LDA, ADC, SBC, AND, ORA, etc.) and observe the debug outputs plus a VRAM text region showing the decoded opcode name and ALU result.
3. This confirmational loop lets you check that the decoder and ALU are correct before pulling them into a control unit.
