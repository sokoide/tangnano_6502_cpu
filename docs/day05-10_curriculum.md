# Day 05–10 Curriculum (6502 & LCD Integration)

This guide shows how to partition the `day99` project into six progressive lessons that build a 6502 CPU together with the LCD display that is already visible from Day 04.

| Day | Focus | Key modules | LCD link |
| --- | ----- | ----------- | -------- |
| **Day 05** | Registers + VRAM text buffer | `day06_completed/cpu_registers.sv`, custom sequencer | Reuses `day09_completed/vram.sv` + `day04_completed/lcd/lcd.sv` so the Tang Nano immediately shows your text |
| **Day 06** | Decoder + ALU | `day06_completed/cpu_decoder.sv`, `day06_completed/cpu_alu.sv` | Feed decoded names or ALU results back into VRAM and watch them on the existing LCD chain |
| **Day 07** | Stack + Memory interface | `day07_completed/memory_controller.sv`, `memory_interface.sv`, `stack_pointer.sv`, `simple_ram.sv` | Writes to `$E000` now update the LCD through the Day 09 pipeline |
| **Day 08** | CPU core integration | `day08_completed/cpu_core.sv`, `cpu_datapath.sv`, `cpu_control_unit.sv`, `cpu_registers.sv` | Program writes to VRAM during execution so the LCD reflects what the CPU is doing |
| **Day 09** | VRAM & LCD pipeline | `day09_completed/vram.sv`, `font_rom.sv`, `lcd.sv`, `tb_tft.sv` | Confirm VGA timing on hardware by keeping the Day 04 LCD top alive |
| **Day 10** | Assembly programming | `day10_completed/hello_world.s`, `counter_display.s`, `scroll_text.s`, toolchain (`cc65`, `srec_cat`, `hex_to_sv.py`) | The generated programs now run on the full CPU+RAM+VRAM stack and paint the LCD via Day 04/09 RTL |

Each day links back to the previous ones, reusing the Day 04 LCD wrapper (`day04_completed/top_9k.sv`, `lcd_demo.sv`, etc.) to show on-screen results immediately. This way the students always have a visual confirmation of their progress even before the final `day99` integration.

See the `[day05](../day05/README.md)`, `[day06](../day06/README.md)`, ..., `[day10](../day10/README.md)` directories for per-day instructions and hands-on tips.
