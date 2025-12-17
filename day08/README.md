# Day 08: Complete CPU Core

---

Day 08 ties together the decoder, ALU, registers, memory controller, and control unit into a functioning 6502 core.

## Learning goals

- Instantiate `day08_completed/cpu_core.sv`, `cpu_control_unit.sv`, `cpu_datapath.sv`, and `cpu_registers.sv`.
- Route the CPU’s memory writes to the VRAM region so the LCD from Day 04 displays whatever the CPU is computing.
- Observe the CPU state via debug outputs while the LCD confirms that VRAM writes produce visible text.

## Suggested RTL

- Use `day09_completed/vram.sv` + `font_rom.sv` + `day04_completed/lcd/lcd.sv` for the display path.
- Feed the CPU with a simple ROM (or hard-coded placeholder) that writes ASCII codes into `$E000-$E3FF`; the LCD will show the program’s effect.
- Add instrumentation in simulation (or on-board LEDs) to show the current opcode, PC, and status flags.

## Hands-on

1. Add a small ROM (even just a loop that writes characters) that the CPU can fetch from the RAM region.
2. Let writes to `$E000` update the Day 04 VRAM, so the LCD acts as your tracing window for the CPU’s memory traffic.
3. Refine the control signals gradually so by the end of the day your CPU can execute simple load/store and arithmetic sequences that manifest on-screen.
