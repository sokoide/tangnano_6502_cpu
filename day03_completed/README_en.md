# Day 03 Completed: SystemVerilog Sequential Circuits

This is the completed project for designing sequential circuits in SystemVerilog.

---

🌐 Available languages:
[English](./README.md) | [日本語](./README_ja.md)

## File Structure

-   `counter_8bit.sv` - 8-bit up counter
-   `pwm_generator.sv` - PWM signal generator
-   `traffic_light.sv` - Traffic light controller (state machine)
-   `shift_register.sv` - 8-bit shift register
-   `clock_divider.sv` - Variable clock divider
-   `top.sv` - Integrated test module
-   `tb_traffic_light.sv` - Traffic light testbench
-   `Makefile` - Build and test automation

## Implemented Modules

### 1. 8-bit Counter

-   Up counter with enable control
-   Overflow detection
-   Asynchronous reset support

### 2. PWM Generator

-   8-bit duty cycle control (0-255)
-   Generation with a continuous counter
-   Variable pulse width output

### 3. Traffic Light Controller

-   3-state FSM (Red -> Green -> Yellow -> Red)
-   Timer-based automatic transitions
-   Can be verified in real-time

### 4. Shift Register

-   8-bit left shift register
-   Parallel load function
-   Serial input/output support

### 5. Clock Divider

-   Variable division ratio (1-15)
-   50% duty cycle
-   High-precision division

## How to Build and Test

### Simulation Test

```bash
make test
```

### FPGA Build

```bash
# Tang Nano 9K
make BOARD=9k download

# Tang Nano 20K
make BOARD=20k download
```

### Individual Tests

```bash
# Traffic light simulation
make sim

# Display waveform
gtkwave tb_traffic_light.vcd
```

## Hardware Verification

### Inputs

-   `rst_n`: Reset button
-   `switches[3:0]`: Control switches

### Outputs

-   `count_out[7:0]`: Counter value (for LED or 7-segment display)
-   `pwm_out`: PWM signal output
-   `red_led`, `yellow_led`, `green_led`: Traffic light LEDs
-   `shift_serial_out`: Shift register output
-   `div_clk_out`: Divided clock output

## Learning Points

### SystemVerilog Sequential Circuits

-   Synchronous circuit design using `always_ff`
-   State definition using `typedef enum`
-   Implementation of asynchronous reset
-   Clock domain design

### State Machine Design

-   Implementation of state transition diagrams
-   Timer-based control
-   Separation of combinational and sequential logic

### Practical Circuit Design

-   PWM control techniques
-   Shift register applications
-   Clock division techniques
-   Multi-module integration

## Advanced Assignments

1.  **UART Transmitter**: State machine for serial communication
2.  **Variable-Length Shift Register**: Dynamic bit-width control
3.  **Multi-Stage Clock Divider**: More flexible frequency generation

These sequential circuits play an important role in the control part and timing control of the CPU.
