# Day 10: Assembly Programming Examples

---

🌐 Available languages:
[English](./README.md) | [日本語](./README_ja.md)

## Learning Objectives

In Day 10, we will build a complete 6502 development environment and demonstrate the capabilities of the 6502 CPU through actual assembly programming examples.

### What You Will Learn Today

1.  **Practical Assembly Programming**

    -   8 different program examples
    -   Practical use of the 6502 instruction set
    -   Understanding of programming patterns

2.  **Program Selection System**

    -   Dynamic program selection
    -   Execution time control
    -   System state management

3.  **Advanced LCD Display**

    -   Multiple display modes
    -   Real-time information updates
    -   User interface

4.  **Complete Development Environment**
    -   Comprehensive debugging features
    -   Performance monitoring
    -   Educational feedback

## Implementation Details

### 1. Assembly Examples ROM (`assembly_examples.sv`)

A ROM containing 8 program examples:

#### Program List

| No  | Address | Program Name          | Learning Content                                   |
| --- | ------- | --------------------- | -------------------------------------------------- |
| 0   | $C000   | Basic Arithmetic      | Basic arithmetic operations (addition/subtraction) |
| 1   | $C020   | Loop with Counter     | Loop control and counters                          |
| 2   | $C040   | Data Manipulation     | Bit manipulation and shift operations              |
| 3   | $C060   | Subroutine with Stack | Subroutines and the stack                          |
| 4   | $C080   | Array Processing      | Array processing and indexing                      |
| 5   | $C0C0   | String Operations     | String manipulation                                |
| 6   | $C0E0   | Math Functions        | Math functions (multiplication)                    |
| 7   | $C100   | I/O Operations        | I/O operations                                     |

#### Program Details

**Program 0: Basic Arithmetic**

```assembly
    CLC          ; Clear carry
    LDA #10      ; Load 10 into A
    ADC #5       ; Add 5 (A=15)
    STA $80      ; Store result in $80
    ADC #20      ; Add 20 (A=35)
    STA $81      ; Store result in $81
```

**Program 1: Loop with Counter**

```assembly
    LDA #0       ; Initialize counter
    STA $90      ; Store counter in $90
loop:
    LDA $90      ; Load counter
    CLC
    ADC #1       ; Increment
    STA $90      ; Store
    CMP #10      ; Compare with 10
    BMI loop     ; Continue if less than 10
```

**Program 2: Data Manipulation**

```assembly
    LDA #$AA     ; Load bit pattern
    AND #$F0     ; Mask upper nibble
    STA $A0      ; Store
    LDA #$55     ; Different pattern
    AND #$0F     ; Mask lower nibble
    ORA $A0      ; Combine
    ASL A        ; Shift left
```

### 2. Program Selector (`program_selector.sv`)

Program selection control:

```systemverilog
// Functions
// - Program selection with switches
// - Start button control
// - CPU reset management
// - Execution state monitoring
```

Features:

-   Supports 16 program addresses
-   Automatic reset sequence
-   Execution state feedback

### 3. Enhanced LCD Display (`enhanced_lcd_display.sv`)

Four display modes:

#### Mode 0: CPU Register Display

```
A:42 X:00 Y:AA
PC:C008 RUN
```

#### Mode 1: Program Information

```
PROG 0: ARITHMETIC
NV-BDIZC
```

#### Mode 2: System Status

```
STATUS: 24
MODE: CPU REG
```

#### Mode 3: Memory View

```
MEMORY VIEW
[C008]=3F
```

### 4. Complete System (`top.sv`)

Integrated system:

-   CPU + Memory + LCD + Program selection
-   Variable CPU clock control
-   Comprehensive debug output

## Hardware Control

### Switch Functions

| Switch        | Function          | Description                  |
| ------------- | ----------------- | ---------------------------- |
| switches[3:0] | Program Selection | Select program 0-7           |
| switches[3:2] | Display Mode      | Switch LCD display content   |
| switches[1:0] | CPU Speed         | Control clock division ratio |

### Button Control

-   `program_start_btn`: Start/reset program

### CPU Speed Control

| switches[1:0] | Speed   | Frequency | Use                        |
| ------------- | ------- | --------- | -------------------------- |
| 00            | Slowest | 0.84MHz   | Step execution observation |
| 01            | Slow    | 1.69MHz   | Detailed operation check   |
| 10            | Medium  | 3.375MHz  | Normal debugging           |
| 11            | Fast    | 6.75MHz   | Performance check          |

### Debug LEDs

| LED | Function        | Description                              |
| --- | --------------- | ---------------------------------------- |
| 0   | Heartbeat       | System operation check (blinks at 0.6Hz) |
| 1   | Program Running | On when program is running               |
| 2   | LCD Ready       | On when LCD is ready for operation       |
| 3   | Start Button    | State of the start button                |
| 7:4 | Current Program | Currently selected program number        |

## Build and Execute

### Required Files

```
day10_completed/
├── assembly_examples.sv     # Assembly program ROM
├── program_selector.sv      # Program selection control
├── enhanced_lcd_display.sv  # Enhanced LCD control
├── top.sv                   # Integrated system
├── tb_assembly_system.sv    # System testbench
├── Makefile                 # Complete build system
└── README_ja.md             # This document

Dependencies:
├── day09_completed/ (LCD controller)
├── day08_completed/ (CPU core)
├── day07_completed/ (memory system)
├── day06_completed/ (ALU, decoder)
├── day05_completed/ (addressing modes)
└── day01-04_completed/ (basic components)
```

### Build Commands

```bash
# Complete build for Tang Nano 9K
make tang_nano_9k

# Complete build for Tang Nano 20K
make tang_nano_20k

# Comprehensive simulation
make run_sim

# FPGA programming
make program_9k    # Tang Nano 9K
make program_20k   # Tang Nano 20K

# Generate documentation
make docs

# Generate constraint file
make constraints
```

### Verification Procedure

1.  **System Initialization**

    ```
    - Power on
    - Release reset button
    - Confirm LCD initialization is complete (LED2 on)
    ```

2.  **Program Selection**

    ```
    - Select program with switches[3:0] (0-7)
    - Confirm selected program with LEDs 7:4
    ```

3.  **Program Execution**

    ```
    - Press program_start_btn
    - Confirm program execution with LED1
    - Monitor CPU state on the LCD
    ```

4.  **Switch Display Mode**
    ```
    - Select mode with switches[3:2]
    - Confirm display content changes on the LCD
    ```

## Programming Study

### Basic Patterns

#### 1. Arithmetic Operations

```assembly
CLC          ; Clear carry flag
LDA #operand1
ADC #operand2  ; Add
STA result    ; Store result
```

#### 2. Loop Control

```assembly
    LDA #init_value
loop:
    ; Loop body
    CLC
    ADC #increment
    CMP #limit
    BCC loop      ; Continue condition
```

#### 3. Bit Manipulation

```assembly
LDA data
AND #mask     ; Bit mask
ORA #pattern  ; Set bits
EOR #toggle   ; Toggle bits
```

#### 4. Subroutines

```assembly
    JSR subroutine  ; Call
    ; Processing after return

subroutine:
    PHA            ; Save registers
    ; Subroutine body
    PLA            ; Restore registers
    RTS            ; Return
```

#### 5. Array Processing

```assembly
    LDY #0         ; Initialize index
loop:
    LDA data,Y     ; Load array element
    STA result,Y   ; Store array element
    INY            ; Increment index
    CPY #size      ; Compare size
    BNE loop       ; Continue
```

### Advanced Techniques

#### 1. Conditional Branching

```assembly
    LDA value
    CMP #threshold
    BCS greater_equal  ; value >= threshold
    ; Processing for value < threshold
    JMP end
greater_equal:
    ; Processing for value >= threshold
end:
```

#### 2. Data Tables

```assembly
    LDX index
    LDA table,X    ; Table lookup

table:
    .byte $00, $01, $04, $09, $10  ; Square number table
```

#### 3. String Manipulation

```assembly
    LDY #0
string_loop:
    LDA source,Y
    BEQ string_end    ; Check for null terminator
    STA dest,Y
    INY
    JMP string_loop
string_end:
    STA dest,Y        ; Also copy null terminator
```

## Debugging and Troubleshooting

### Common Issues

#### 1. Program does not run

-   **Check**:
    -   Reset signal (rst_n)
    -   Clock supply
    -   Program selection
    -   Start button operation

#### 2. Result is not as expected

-   **Debug methods**:
    -   Check register values on the LCD display
    -   Observe by setting the CPU speed to the lowest
    -   Trace with step execution

#### 3. Abnormal LCD display

-   **Countermeasures**:
    -   Check wiring
    -   Check power supply voltage
    -   Check initialization sequence

### Utilizing Simulation

```bash
# Run detailed simulation
make run_sim

# Test a specific program
# Specify program number in the testbench
```

## Applications and Customization

### Adding Programs

1.  **Edit assembly_examples.sv**:

    -   Add a new program address
    -   Write machine code

2.  **Update program_selector.sv**:

    -   Extend the PROGRAM_ADDRESSES array

3.  **Modify enhanced_lcd_display.sv**:
    -   Add to the PROGRAM_NAMES array

### Customizing the Display

```systemverilog
// Custom display example
// Line 1: "CUSTOM MODE"
// Line 2: "DATA: XXXX"
```

### Adding New Features

-   **Breakpoints**: Stop at a specific PC value
-   **Memory Dump**: Display memory contents
-   **Execution Statistics**: Display instruction count
-   **Error Detection**: Detect illegal instructions

## Learning Outcomes

### Acquired Skills

1.  **6502 Assembly Programming**

    -   Understanding of the basic instruction set
    -   Acquisition of programming patterns
    -   Improved debugging skills

2.  **System Design**

    -   Hardware/software integration
    -   User interface design
    -   Building a real-time system

3.  **FPGA Development**
    -   Implementation of a large-scale system
    -   Constraint design
    -   Verification methods

### Practical Applications

-   **Embedded system development**
-   **Retro computing**
-   **Educational CPU design**
-   **Prototyping environment**

## Next Steps

### Advanced Assignments

1.  **Instruction Set Extension**

    -   Add new instructions
    -   Extended addressing modes

2.  **Add Peripherals**

    -   Timer/Counter
    -   UART communication
    -   SPI/I2C interface

3.  **Operating System**
    -   Implement a simple kernel
    -   Task scheduler
    -   Device drivers

### Related Projects

-   **Complete 8-bit computer reproduction**
-   **Apple II / Commodore 64 emulator**
-   **Custom CPU architecture design**

## Reference Materials

-   6502 Instruction Set Reference
-   Assembly Language Programming Techniques
-   Retro Computing Resources
-   FPGA Design Best Practices
-   SystemVerilog Advanced Topics

---

**Complete!** In this 10-day curriculum, you have built a complete 6502 CPU development environment, from basic LED blinking. This system is a practical educational tool that can be used for both actual 6502 programming study and FPGA development.
