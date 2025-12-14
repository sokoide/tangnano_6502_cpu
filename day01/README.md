# Day 01: Tang Nano + GoWin EDA Basics

---

🌐 Available languages:
[English](./README.md) | [日本語](./README_ja.md)

## 🎯 Learning Objectives

- Understand the basic specifications of Tang Nano 9K/20K
- Master the basic operations of GoWin EDA
- Create a blinking LED project as the first HDL project
- Learn the basic workflow of FPGA development

## 📚 Preparation

### Hardware

- Tang Nano 9K or Tang Nano 20K
- USB-C Cable
- PC (Windows/Linux/macOS)

### Software

- GoWin EDA (Download and install from the official website)

## 📖 Theory

### A Note for Software Engineers: Thinking in Hardware

If you're coming from a software background, the biggest mental shift is this: **you are not writing a program.** You are **describing a hardware circuit.**

- **Sequential vs. Parallel:** A CPU runs instructions one by one. In an FPGA, everything you describe happens **at the same time (in parallel)**, unless you explicitly tell it to happen in sequence using a clock.
- **Code describes structure, not execution:** Your SystemVerilog code describes how components are wired together. An `assign led = a & b;` statement doesn't "run" once; it creates a physical AND gate connected to `a`, `b`, and `led`.
- **The Clock is King:** The clock signal (`clk`) is what brings order to the parallelism. It allows you to create sequential logic (e.g., "on the next clock tick, increment this counter"). This is what the `always_ff @(posedge clk)` block does.

Keep this in mind as you learn. You are a circuit designer, not just a programmer!

#### Analogy: The Build Process

- **Synthesis** $\approx$ **Compilation**: Checks syntax and translates your code into low-level logic primitives (gates, LUTs).
- **Place & Route** $\approx$ **Linking + Physical Layout**: Decides exactly *where* on the chip each piece of logic goes and connects the physical wires. This is computationally intensive, which is why it often takes longer than software compilation!

### Tang Nano Basic Specifications

**Tang Nano 9K:**

- FPGA: Gowin GW1NR-9C
- Logic Elements: 8,640 LUT4
- Memory: 468Kbit BSRAM
- PLLs: 2
- I/O Pins: 63

**Tang Nano 20K:**

- FPGA: Gowin GW2AR-18C
- Logic Elements: 20,736 LUT4
- Memory: 828Kbit BSRAM
- PLLs: 4
- I/O Pins: 107

### Glossary (first-time FPGA terms)

This Day introduces a few terms you’ll keep seeing later. Here’s what they mean.

#### RTL (Register-Transfer Level)

**RTL** is the style of HDL code where you describe:

- **Registers** (state updated on a clock edge), and
- **Combinational logic** (pure “wires/logic” between registers).

In practice, your `.sv` files (like `top.sv`) are RTL.

#### LUT / FF / (Block) RAM

FPGA chips are built from configurable building blocks:

- **LUT (Look-Up Table)**: implements small boolean logic (like AND/OR/XOR and small truth tables).
  Many designs are “mapped” into LUTs.
- **FF (Flip-Flop)**: a 1-bit register that stores state and updates on a clock edge (`posedge`/`negedge`).
- **RAM / BSRAM (Block SRAM)**: on-chip memory blocks (used for ROM/RAM/FIFOs, etc.).

Later, when we say “Synthesis maps RTL into LUT/FF/RAM”, this is what we mean.

#### Pull-up / Pull-down (why inputs need them)

If an input pin is not driven by anything, it can “float” and randomly read as 0 or 1.
A **pull-up** biases it weakly toward 1, and a **pull-down** biases it weakly toward 0.

```mermaid
flowchart LR
  subgraph Floating
    F[Input pin] --> Q1["can read 0 or 1<br/>(unstable)"]
  end
  subgraph Pull-up
    PU[Input pin] --> R1[weak resistor to VCC] --> ONE[stable '1' when not driven]
  end
  subgraph Pull-down
    PD[Input pin] --> R0[weak resistor to GND] --> ZERO[stable '0' when not driven]
  end
```

On FPGA pins, pull-ups/downs are often configured via constraints (see `PULL_MODE` below).

### Basic FPGA Development Flow

```mermaid
flowchart TD
  A["RTL in SystemVerilog<br/>(top.sv)"] --> B["Synthesis<br/>RTL → LUT/FF/RAM netlist"]
  B --> C[Place & Route<br/>place cells + route wires]
  C --> D["Bitstream generation<br/>(.fs)"]
  D --> E[Programming<br/>download to FPGA]
```

1. **Design (RTL)** - Describe the logic in HDL (Hardware Description Language)
2. **Synthesis** - Convert RTL into a logic netlist (LUT/FF/RAM)
3. **Place & Route** - Map the netlist to the physical resources within the FPGA
4. **Bitstream Generation** - Generate the binary file to be written to the FPGA
5. **Programming** - Write the bitstream to the FPGA

## 🛠️ Practice: Blinking LED Project

If you want to run this on real hardware with minimal setup friction, use the working reference project in `day01_completed/`:
This completed project contains board-specific files for both Tang Nano 9K and 20K, which is the recommended way to run the examples.

```bash
cd day01_completed
make help
make BOARD=9k download   # or BOARD=20k
```

Board notes (9K/20K tool paths, device selection, etc.): see `docs/BOARD_SETUP.md`.

### Step 1: Create Project

1. Launch GoWin EDA
2. Select "File" → "New Project"
3. Project name: `led_blink`
4. Device selection:
    - Tang Nano 9K: `GW1NR-LV9QN88PC6/I5`
    - Tang Nano 20K: `GW2AR-LV18QN88C8/I7`

### Step 2: Create HDL Code

Create a `top.sv` file and write the following code:

```systemverilog
module top (
    input  wire clk,     // 27MHz clock
    output wire led      // LED output
);

    // Clock divider for visible blinking (approx. 1Hz)
    logic [24:0] counter;

    always_ff @(posedge clk) begin
        counter <= counter + 1;
    end

    // Blink LED (use the most significant bit of the counter)
    assign led = counter[24];

endmodule
```

#### `wire`, `logic`, `always_ff`, `posedge`, `assign` (what they mean)

This small module already contains most of the “core grammar” you’ll use later:

```mermaid
flowchart LR
  CLK((clk)) --> FF["FFs: counter register<br/>always_ff @ posedge clk"]
  FF -->|"counter[24]"| COMB[combinational wiring<br/>assign led = ...]
  COMB --> LED((led))
```

- `wire`: A data type that represents a physical wire. It can be continuously driven by something (like the output of a logic gate) but cannot store a value on its own. It must be driven by an `assign` statement or a module output.
- `logic`: The modern SystemVerilog data type that can be used for both wires and registers. As a rule for beginners, **you should prefer `logic` over `reg`**. It can be driven by `assign` (making it a wire) or used in an `always` block (making it a register).
- `reg`: The older Verilog data type for a variable that stores a value, used inside an `always` block. While you see it in the example, `logic` is generally recommended for new SystemVerilog code.
- `always_ff @(posedge clk)`: This describes a block of logic that is **sequential and clocked**. The code inside this block only executes on the rising edge (0 to 1 transition) of the `clk` signal. This is how you create **registers** (like flip-flops) that hold state.
- `assign`: This keyword creates **combinational logic**. It describes a relationship that is always true, like a direct wire connection or a logic gate. For example, `assign led = counter[24];` creates a wire that connects the 25th bit of the `counter` register directly to the `led` output.

**Important Rule for Software Engineers:**

- Think of `always_ff` as creating a component that has **memory** (state). It only changes when the clock "ticks".
- Think of `assign` as creating a component with **no memory**. Its output changes *instantly* whenever its inputs change. This is the essence of parallel hardware.
- Use `<=` (non-blocking assignment) inside `always_ff` so all registers update together on the clock edge.

### Step 3: Create Constraint File

Create a `tang_nano.cst` file:

**Tang Nano 9K:**

```
IO_LOC "clk" 52;
IO_LOC "led" 10;
IO_PORT "clk" IO_TYPE=LVCMOS33 PULL_MODE=NONE;
IO_PORT "led" IO_TYPE=LVCMOS18;
```

**Tang Nano 20K:**

```
IO_LOC "clk" 4;
IO_LOC "led" 15;
IO_PORT "clk" IO_TYPE=LVCMOS33 PULL_MODE=UP;
IO_PORT "led" IO_TYPE=LVCMOS33;
```

#### What is a `.cst` file? What are `IO_TYPE` / `PULL_MODE`?

A `.cst` file tells the FPGA tools how your top-level ports connect to real pins and what electrical settings to use.

- `IO_LOC "name" <pin>;` maps a port name to a physical pin number.
- `IO_PORT "name" ...;` sets electrical properties.

Common options:

- `IO_TYPE=LVCMOS33` / `LVCMOS18`: the I/O voltage standard (3.3V / 1.8V).
- `PULL_MODE=UP|DOWN|NONE`:
  - `UP`: weak pull-up (helps prevent floating inputs).
  - `DOWN`: weak pull-down.
  - `NONE`: no pull resistor.

Clock input pins are normally driven strongly by the board oscillator, so `PULL_MODE=NONE` is typical.

### Step 4: Synthesize and Place & Route

1. Run "Process" → "Synthesize"
2. Confirm there are no errors
3. Run "Process" → "Place & Route"

### Step 5: Programming

1. Select "Process" → "Program Device"
2. Connect the Tang Nano via USB
3. Run "SRAM Program"
4. Confirm that the LED blinks at approximately 0.8-second intervals

## 🔧 Troubleshooting

### Common Issues

1. **Device not recognized**

    - Check if the USB driver is installed correctly
    - Check if the switch on the Tang Nano is in the correct position

2. **Synthesis error**

    - Check for syntax errors in the SystemVerilog code
    - Confirm that the module name and file name match

3. **Place & Route error**
    - Check if the pin numbers in the constraint file are correct
    - Confirm that the constraint file corresponds to the board you are using

## 📝 Assignments

### Basic Assignments

1. Try changing the blinking speed (by changing the bit position of the counter)
2. Make two LEDs blink alternately
3. Change the brightness of the LED using PWM

### Advanced Assignments

1. Control the blinking speed of the LED with a switch input
2. Display a counter on a 7-segment display
3. Display various colors with an RGB LED

## 📚 What I Learned Today

- [ ] Basic specifications of Tang Nano
- [ ] Basic operations of GoWin EDA
- [ ] Basic syntax of SystemVerilog
- [ ] Understanding of the FPGA development flow
- [ ] Role of the constraint file
- [ ] On-device testing

## 🎯 Preview for Tomorrow

In Day 02, we will learn in detail about combinational circuits in SystemVerilog:

- How to use `always_comb`
- Conditional branching (if-else, case)
- Logical operations and bit manipulation
- Connections between modules

**Preparation task**: Review the basics of binary, hexadecimal, and logical operations.
