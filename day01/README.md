# Day 01: Tang Nano + GoWin EDA Basics

---

🌐 Available languages:
[English](./README.md) | [日本語](./README_ja.md)

## 🎯 Learning Objectives

-   Understand the basic specifications of Tang Nano 9K/20K
-   Master the basic operations of GoWin EDA
-   Create a blinking LED project as the first HDL project
-   Learn the basic workflow of FPGA development

## 📚 Preparation

### Hardware

-   Tang Nano 9K or Tang Nano 20K
-   USB-C Cable
-   PC (Windows/Linux/macOS)

### Software

-   GoWin EDA (Download and install from the official website)

## 📖 Theory

### Tang Nano Basic Specifications

**Tang Nano 9K:**

-   FPGA: Gowin GW1NR-9C
-   Logic Elements: 8,640 LUT4
-   Memory: 468Kbit BSRAM
-   PLLs: 2
-   I/O Pins: 63

**Tang Nano 20K:**

-   FPGA: Gowin GW2AR-18C
-   Logic Elements: 20,736 LUT4
-   Memory: 828Kbit BSRAM
-   PLLs: 4
-   I/O Pins: 107

### Basic FPGA Development Flow

1.  **Design** - Describe the logic in HDL (Hardware Description Language)
2.  **Synthesis** - Convert HDL code into a logic circuit
3.  **Place & Route** - Map the logic circuit to the physical resources within the FPGA
4.  **Bitstream Generation** - Generate the binary file to be written to the FPGA
5.  **Programming** - Write the bitstream to the FPGA

## 🛠️ Practice: Blinking LED Project

If you want to run this on real hardware with minimal setup friction, use the working reference project in `day01_completed/`:

```bash
cd day01_completed
make help
make BOARD=9k download   # or BOARD=20k
```

Board notes (9K/20K tool paths, device selection, etc.): see `docs/BOARD_SETUP.md`.

### Step 1: Create Project

1.  Launch GoWin EDA
2.  Select "File" → "New Project"
3.  Project name: `led_blink`
4.  Device selection:
    -   Tang Nano 9K: `GW1NR-LV9QN88PC6/I5`
    -   Tang Nano 20K: `GW2AR-LV18QN88C8/I7`

### Step 2: Create HDL Code

Create a `top.sv` file and write the following code:

```systemverilog
module top (
    input  wire clk,     // 27MHz clock
    output wire led      // LED output
);

    // Clock divider for visible blinking (approx. 1Hz)
    reg [24:0] counter;

    always_ff @(posedge clk) begin
        counter <= counter + 1;
    end

    // Blink LED (use the most significant bit of the counter)
    assign led = counter[24];

endmodule
```

### Step 3: Create Constraint File

Create a `tang_nano.cst` file:

**Tang Nano 9K:**

```
IO_LOC "clk" 52;
IO_PORT "clk" PULL_MODE=UP;
IO_LOC "led" 10;
```

**Tang Nano 20K:**

```
IO_LOC "clk" 4;
IO_PORT "clk" PULL_MODE=UP;
IO_LOC "led" 15;
```

### Step 4: Synthesize and Place & Route

1.  Run "Process" → "Synthesize"
2.  Confirm there are no errors
3.  Run "Process" → "Place & Route"

### Step 5: Programming

1.  Select "Process" → "Program Device"
2.  Connect the Tang Nano via USB
3.  Run "SRAM Program"
4.  Confirm that the LED blinks at approximately 0.8-second intervals

## 🔧 Troubleshooting

### Common Issues

1.  **Device not recognized**

    -   Check if the USB driver is installed correctly
    -   Check if the switch on the Tang Nano is in the correct position

2.  **Synthesis error**

    -   Check for syntax errors in the SystemVerilog code
    -   Confirm that the module name and file name match

3.  **Place & Route error**
    -   Check if the pin numbers in the constraint file are correct
    -   Confirm that the constraint file corresponds to the board you are using

## 📝 Assignments

### Basic Assignments

1.  Try changing the blinking speed (by changing the bit position of the counter)
2.  Make two LEDs blink alternately
3.  Change the brightness of the LED using PWM

### Advanced Assignments

1.  Control the blinking speed of the LED with a switch input
2.  Display a counter on a 7-segment display
3.  Display various colors with an RGB LED

## 📚 What I Learned Today

-   [ ] Basic specifications of Tang Nano
-   [ ] Basic operations of GoWin EDA
-   [ ] Basic syntax of SystemVerilog
-   [ ] Understanding of the FPGA development flow
-   [ ] Role of the constraint file
-   [ ] On-device testing

## 🎯 Preview for Tomorrow

In Day 02, we will learn in detail about combinational circuits in SystemVerilog:

-   How to use `always_comb`
-   Conditional branching (if-else, case)
-   Logical operations and bit manipulation
-   Connections between modules

**Preparation task**: Review the basics of binary, hexadecimal, and logical operations.
