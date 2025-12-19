# Common Pitfalls for Software Engineers

Here are some points where software engineers often stumble when learning FPGA (SystemVerilog) because they differ from software intuition.

---

🌐 Available languages:
[English](./COMMON_PITFALLS.md) | [日本語](./COMMON_PITFALLS_ja.md)

## 1. `=` vs `<=` (Assignment Timing)

This is the biggest confusion point.

- **Software**: If you write `a = 1; b = a;`, `b` will definitely be `1` (sequential execution).
- **Hardware**: In sequential logic (`always_ff`), if you write `a <= 1; b <= a;`, **`b` gets the OLD value of `a`** (simultaneous update).

In FPGA sequential logic, all registers update simultaneously at the rising edge of the clock. `<=` (Non-blocking assignment) schedules the value for the "next moment" and does not update immediately within the block.

See [SystemVerilog Cheatsheet](./SYSTEMVERILOG_CHEATSHEET.md) for details.

## 2. Chattering (Bouncing Buttons)

- **Software**: You assume `if (keyPressed)` triggers once.
- **Hardware**: Physical buttons bounce mechanically, switching "ON/OFF/ON/OFF..." rapidly when pressed (Chattering).

If you feed this directly into a clock input `always_ff @(posedge button)` or use it as a counter enable, **a single press might register as dozens of clicks**.
You need a "Debounce" circuit (a filter that waits for the signal to stabilize) to handle this.

## 3. No "Printf" Debugging

- **Software**: When stuck, you stick `console.log` or `printf` to see variables.
- **Hardware**: There is no console inside an FPGA.

**What can you do?**

1. **Simulation**: You can use `$display()` inside your testbench (`make test`). This is your primary tool.
2. **On Hardware**: You must output signals to an LED, or use a "Visual Debugger" like the LCD circuit we build in Day 04 to display values on a screen.

## 4. Uninitialized Variables (The Dreaded "X")

- **Software**: Variables are usually initialized to 0 or null, or cause compile errors.
- **Hardware**: In simulation, uninitialized registers are in the "**X (Undefined)**" state.

`X` + `1` results in `X`. It is critical to use the reset signal (`rst_n`) correctly to initialize all registers to a known value (like `0`) at startup.
Note that on real hardware, `X` doesn't exist; it will randomly be `0` or `1`. This is common cause of "It works on the board but fails in simulation" (or vice versa).

## 5. Inferring Latches

- **Software**: If you write `if (flag) val = 1;`, it's obvious that if `flag` is false, nothing happens.
- **Hardware**: If you do this in combinational logic (`always_comb`), it implies "keep the previous value if flag is false", which creates a memory element called a **Latch**. This is usually unintentional and causes timing bugs.

**Solution**: In `always_comb`, always provide an `else` branch, or set a default value at the top (`val = 0;`), so that **the value is determined in all possible paths**.
