# Debugging Guide for FPGA Development

Hardware debugging requires a different mindset than software debugging. You can't just pause execution anywhere or print logs to a console easily. This guide introduces the tools and techniques to effectively debug your designs.

---

🌐 Available languages:
[English](./DEBUGGING_GUIDE.md) | [日本語](./DEBUGGING_GUIDE_ja.md)

## 1. Simulation (Verilator)

**"Simulate first, hardware later."**
This is the golden rule. Debugging on hardware is slow and gives limited visibility. Simulation allows you to see every signal at every nanosecond.

### Running Tests

The project uses `make test` to compile and run your SystemVerilog code using Verilator.

```bash
make test
```

### Viewing Waveforms (GTKWave)

If a test fails or you want to verify internal behavior:

1. Run `make test`. This generates a `.vcd` (Value Change Dump) file.
2. Open the file with GTKWave:

    ```bash
    gtkwave tb_alu_4bit.vcd  # Example filename
    ```

### How to Read Waveforms

- **Clock Edge:** Look for the vertical line where `clk` goes from 0 to 1 (rising edge). This is when `always_ff` updates happen.
- **Pre-reset state:** At the very beginning (time 0), signals might be `x` (unknown/red) or random. Check if your reset signal (`rst_n`) properly initializes them to 0.
- **Latency:** Remember that sequential logic updates *after* the clock edge. If you see an input change right at the clock edge, the output of a register will change slightly after (in simulation steps).

## 2. Hardware Debugging

Once simulation passes, you move to the real FPGA. If it doesn't work here, use these techniques:

### 💡 The "L-Chika" (LED Blink) Debug

The on-board LEDs are your best friends.

- **Status Indicators:** Assign internal flags (e.g., `Zero Flag`, `State == WAIT`) to LEDs.
- **Heartbeat:** Always have one LED blinking (driven by a counter) to prove the clock is running and the FPGA is configured.

### 🖥️ LCD Debugging (The "Hardware Printf")

From Day 04 onwards, we build an LCD controller. This is effectively your "standard output".

- **Info Instruction (`IFO`):** In Day 18, we implement a custom instruction to dump register values to the screen.
- **Visualizing Memory:** Map specific memory regions to the screen to watch data change in real-time.

### 🛑 Slowing Down the Clock

The 6502 CPU logic is complex. Running at 27MHz makes it impossible to see what's happening with LEDs.

- **Clock Divider:** Use a slower clock enable signal (e.g., 1Hz or 10Hz) for the CPU logic while keeping the LCD/HDMI clock fast. This lets you watch the instruction execution flow step-by-step on the LEDs or LCD.

## 3. Common Issues Checklist

### Simulation works, but Hardware doesn't?

1. **Reset Logic:**
    - Is your reset signal `active low` (`rst_n`) or `active high` (`rst`)?
    - Did you press the reset button on the board?
2. **Clock Stability:**
    - Are you using the correct pin for the clock?
    - Did you configure the PLL correctly?
3. **Floating Inputs:**
    - Do all input buttons have `PULL_MODE=UP/DOWN` in the `.cst` file? Floating inputs cause erratic behavior.
4. **Timing Violations:**
    - (Advanced) If logic is too complex between registers, it might not finish within one clock cycle. The synthesis report usually warns about "Timing Constraints".

### "Logic is behaving weirdly"

1. **Inferred Latches:** Did you miss an `else` or `default` case in an `always_comb` block?
2. **Bit Width Mismatch:** Are you assigning a 4-bit value to a 3-bit wire? (e.g., `logic [2:0] x = 4'b1111;` -> `x` becomes `111`).
3. **Sensitivity List:** In Verilog, `always @(a)` might miss updates if `b` changes. SystemVerilog's `always_comb` fixes this automatically. **Always use `always_comb`!**
