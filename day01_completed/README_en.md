# Day 01 Completed: LED Blink Project

This is the completed version of the simple LED blinking project for the Tang Nano FPGA.

---

🌐 Available languages:
[English](./README.md) | [日本語](./README_ja.md)

## File Structure

-   `top.sv` - Main module (controls LED blinking)
-   `tang_nano_9k.cst` - Pin constraints for Tang Nano 9K
-   `tang_nano_20k.cst` - Pin constraints for Tang Nano 20K
-   `led_blink.gprj` - GoWin EDA project file
-   `Makefile` - Build automation

## Functionality

-   Divides the 27MHz clock with a 25-bit counter
-   Blinks the LED at approximately 0.8Hz (about 1.25-second intervals)
-   Compatible with both Tang Nano 9K and 20K

## How to Build

### For Tang Nano 9K

```bash
make BOARD=9k download
```

### For Tang Nano 20K

```bash
make BOARD=20k download
```

## Verification

After programming, confirm that the LED on the board blinks at approximately 1.25-second intervals.

## Learning Points

1.  **Basic SystemVerilog Syntax**

    -   Module definition
    -   Clock-synchronous circuits using `always_ff`
    -   Combinational circuits using `assign`

2.  **Clock Division**

    -   Divider circuit using a counter
    -   Calculation of bit width (27MHz / 2^25 ≈ 0.8Hz)

3.  **FPGA Development Flow**

    -   Synthesis
    -   Place & Route
    -   Bitstream Generation
    -   Programming

4.  **Constraint File**
    -   Specifying pin assignments
    -   Setting electrical properties
