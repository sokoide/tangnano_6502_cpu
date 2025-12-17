# Day 07: Memory Interface & Stack

---

Day 07 builds the memory interface, the stack pointer, and wires the registers to real RAM/VRAM.

## Learning goals

- Explore `day07_completed/memory_controller.sv`, `memory_interface.sv`, and `stack_pointer.sv` from the completed material.
- Understand the memory map (`RAM`, `VRAM`, `ROM`, and I/O`) and how read/write enables are generated.
- Keep writing to the VRAM region when memory writes happen so the Day 04 LCD pipeline immediately presents the data being stored.

## Suggested RTL

- Instantiate `day07_completed/memory_controller.sv` inside a top that includes `day06_completed/cpu_registers.sv` as the register file for PC/A/X/Y/SP.
- Drive the controller with simple sequences (e.g., write to contiguous VRAM addresses so the screen scrolls a message).
- Use `day09_completed/vram.sv`/`day09_completed/font_rom.sv` + `day04_completed/lcd/lcd.sv` to show the messages while your memory controller logic runs.

## Hands-on

1. Keep the PLL+LCD path from Day 04 on the Tang Nano target.
2. Connect the memory controller outputs back to your register array so you can peek at PC, SP, and debug data while writes go through to VRAM.
3. Add a “flash” message routine that writes `HELLO > DAY 07` into VRAM every few cycles; the LCD proves that the memory path is working before the full CPU arrives.
