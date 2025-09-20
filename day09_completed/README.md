# Day 09: LCD Controller System

---

🌐 Available languages:
[English](./README.md) | [日本語](./README_ja.md)

## Learning Objectives

In Day 09, we will add an LCD display controller to the 6502 CPU system and implement a system that displays CPU register values in real-time.

### What You Will Learn Today

1.  **LCD Controller Design**

    -   HD44780 compatible display control
    -   4-bit interface implementation
    -   Proper initialization sequence

2.  **Timing Control**

    -   LCD timing requirements
    -   Control with a state machine
    -   Asynchronous interface processing

3.  **System Integration**

    -   Integration of CPU and LCD
    -   Real-time data display
    -   Performance optimization

4.  **User Interface**
    -   Visualization of register values
    -   System status display
    -   Providing debug information

## Implementation Details

### 1. LCD Controller (`lcd_controller.sv`)

Low-level control of an HD44780 compatible LCD:

```systemverilog
// Initialization sequence
// 1. Wait 15ms for power stabilization
// 2. Function Set (8-bit) x 3 times
// 3. Function Set (4-bit)
// 4. Display Off -> Clear -> Entry Mode -> Display On
```

Main functions:

-   4-bit mode communication
-   Appropriate timing control (based on 27MHz)
-   Command/data switching
-   Busy state management

### 2. LCD Display (`lcd_display.sv`)

High-level display interface:

```systemverilog
// Functions
// - Display characters
// - Cursor position control
// - Clear screen
// - Supports 16x2 display
```

Features:

-   ASCII character display
-   Specify cursor position (0-31)
-   Automatic calculation of DDRAM address
-   Operation queuing

### 3. CPU + LCD System (`cpu_lcd_system.sv`)

Integrated system:

```systemverilog
// Display contents
// Line 1: "A:XX X:XX"    (Accumulator and X register)
// Line 2: "PC:XXXX"      (Program counter)
```

Real-time update:

-   Automatic update at 0.5-second intervals
-   Hexadecimal display (ASCII conversion)
-   CPU register monitoring

### 4. Top Module (`top.sv`)

Complete system:

-   CPU + Memory + LCD integration
-   Debug LED control
-   System activity display

## Hardware Connection

### LCD Connection (HD44780 compatible)

| Signal      | Tang Nano Pin | LCD Function                    |
| ----------- | ------------- | ------------------------------- |
| lcd_rs      | 71            | Register Select (0=cmd, 1=data) |
| lcd_rw      | 53            | Read/Write (always 0=write)     |
| lcd_en      | 54            | Enable pulse                    |
| lcd_data[0] | 55            | Data bit 0                      |
| lcd_data[1] | 56            | Data bit 1                      |
| lcd_data[2] | 57            | Data bit 2                      |
| lcd_data[3] | 68            | Data bit 3                      |

### Power Connection

```
LCD Pin  Connection
1 (VSS)  -> GND
2 (VDD)  -> +5V
3 (V0)   -> GND (or potentiometer for contrast)
4 (RS)   -> Pin 71
5 (RW)   -> Pin 53
6 (EN)   -> Pin 54
7-10     -> Not connected (4-bit mode)
11 (D4)  -> Pin 55
12 (D5)  -> Pin 56
13 (D6)  -> Pin 57
14 (D7)  -> Pin 68
15 (A)   -> +5V (backlight anode)
16 (K)   -> GND (backlight cathode)
```

## Switch Control

### CPU Clock Speed Control

| switches[1:0] | CPU Speed | Use                        |
| ------------- | --------- | -------------------------- |
| 00            | 1.69MHz   | Debug (slowest)            |
| 01            | 3.375MHz  | Observation (slow)         |
| 10            | 6.75MHz   | Normal operation (medium)  |
| 11            | 27MHz     | Maximum performance (fast) |

### System Settings

-   `switches[2]` - Reserved (for future expansion)
-   `switches[3]` - Reserved (for future expansion)

## Debug LEDs

| LED | Function      | Description                                        |
| --- | ------------- | -------------------------------------------------- |
| 0   | Heartbeat     | System operation display (blinks at approx. 0.6Hz) |
| 1   | System Active | On during CPU execution or LCD update              |
| 2   | LCD Ready     | On when LCD is ready for operation                 |
| 3   | Switch Echo   | Echo of switches[0]                                |
| 7:4 | Accumulator   | Lower 4 bits of the A register                     |

## Build and Execute

### Required Files

```
day09_completed/
├── lcd_controller.sv        # LCD hardware control
├── lcd_display.sv           # LCD high-level API
├── cpu_lcd_system.sv        # CPU+LCD integration
├── top.sv                   # Top-level module
├── tb_lcd_system.sv         # Testbench
├── Makefile                 # Build system
└── README_ja.md             # This document

Dependent files:
└── day08_completed/ (complete CPU core)
└── day07_completed/ (memory system)
└── day06_completed/ (ALU, decoder, status)
└── day05_completed/ (addressing modes)
```

### Build Commands

```bash
# Build for Tang Nano 9K
make tang_nano_9k

# Build for Tang Nano 20K
make tang_nano_20k

# Run simulation
make run_sim

# Write to FPGA
make program_9k    # Tang Nano 9K
make program_20k   # Tang Nano 20K

# Generate constraint file
make constraints
```

## Verification

### Initialization Sequence

1.  **Power On**: Supply power to the Tang Nano
2.  **Release Reset**: Release the reset button
3.  **LCD Initialization**: LCD ready after approx. 20ms
4.  **CPU Start**: Program execution starts from $C000

### Verifying Normal Operation

1.  **Check LEDs**:

    -   LED0 blinks at approx. 0.6Hz (heartbeat)
    -   LED1 is on during system operation
    -   LED2 is on when the LCD is ready

2.  **Check LCD Display**:

    ```
    A:42 X:00
    PC:C008
    ```

3.  **Register Value Changes**:
    -   A and X values change as the CPU executes
    -   PC value increments continuously

### Troubleshooting

#### If the LCD does not display anything

1.  **Check Wiring**:

    -   Power supply voltage (+5V, GND)
    -   Signal line connections
    -   Contrast adjustment (V0)

2.  **Check Timing**:

    -   Initialization wait time
    -   Enable pulse width
    -   Setup/hold times

3.  **Simulation**:
    ```bash
    make run_sim
    ```

#### If the CPU operates abnormally

1.  **Check Clock**: Set the CPU speed to the lowest with the switches
2.  **Monitor Registers**: Check the A value with the debug LEDs
3.  **Check Program**: Verify the ROM contents

## LCD Display Contents

### Normal Display

```
Line 1: "A:XX X:XX"
Line 2: "PC:XXXX"
```

Example:

```
A:42 X:AA
PC:C010
```

### Hexadecimal Display

-   All uppercase hexadecimal
-   Register values are 2 digits (XX)
-   PC value is 4 digits (XXXX)

## Learning Points

### LCD Interface Design

1.  **Timing Requirements**:

    -   Setup time: 40ns
    -   Hold time: 10ns
    -   Enable pulse width: 1μs or more

2.  **Initialization Sequence**:

    -   Power stabilization wait (15ms)
    -   Step-by-step execution of function settings
    -   Proper order of display control

3.  **4-bit Communication**:
    -   Sending upper/lower nibbles separately
    -   Enable pulse control
    -   Inserting appropriate delays

### System Integration

1.  **Asynchronous Interface**:

    -   Independent operation of CPU and LCD
    -   Mutual exclusion with busy state
    -   Update timing management

2.  **Real-time Performance**:

    -   Periodic data updates
    -   Minimizing impact on CPU performance
    -   Optimizing usability

3.  **Debuggability**:
    -   Multi-level status display
    -   Visual feedback
    -   Step-by-step troubleshooting

## Application Examples

### Custom Display

Customize the register display:

```systemverilog
// Also display the Y register and status register
Line 1: "A:XX Y:XX"
Line 2: "S:XX PC:XXXX"
```

### Multi-Page Display

Switch display contents with a switch:

```systemverilog
// Page 0: Registers
// Page 1: Memory contents
// Page 2: Execution statistics
```

### Message Display

Messages for specific conditions:

```systemverilog
// On error: "ERROR: HALT"
// On completion: "PROGRAM DONE"
```

## Next Steps

In Day 10, we will create actual assembly programming examples and build a complete 6502 development environment.

## Reference Materials

-   HD44780 LCD Controller Datasheet
-   6502 Register Specification
-   Tang Nano I/O Constraint Design
-   SystemVerilog Interface Design Patterns
-   Real-Time System Design Principles
