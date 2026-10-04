# Day 03 Completed: SystemVerilog Sequential Circuits

This is the completed project for designing sequential circuits in SystemVerilog.

---

🌐 Available languages:
[English](./README.md) | [日本語](./README_ja.md)

## File Structure

- `counter_8bit.sv` - 8-bit up counter
- `pwm_generator.sv` - PWM signal generator
- `traffic_light.sv` - Traffic light controller (state machine)
- `shift_register.sv` - 8-bit shift register
- `clock_divider.sv` - Variable clock divider
- `top_9k.sv` / `top_20k.sv` - Board wrappers (inputs tied to constants)
- `top_core.sv` - Internal circuit integration
- `tb_traffic_light.sv` - Traffic light testbench
- `Makefile` - Build and test automation

## Implemented Modules

### 1. 8-bit Counter

- Up counter with enable control
- Overflow detection
- Asynchronous reset support

### 2. PWM Generator

- 8-bit duty cycle control (0-255)
- Generation with a continuous counter
- Variable pulse width output

### 3. Traffic Light Controller

- 3-state FSM (Red -> Green -> Yellow -> Red)
- Timer-based automatic transitions
- Can be verified in real-time

### 4. Shift Register

- 8-bit left shift register
- Parallel load function
- Serial input/output support

### 5. Clock Divider

- Variable division ratio (1-15)
- 50% duty cycle for even ratios; floor(N/2)/N for odd ratios
- High-precision division

## How to Build and Test

### Simulation Test

```bash
make test
```

#### Simulator notes

- Simulator: Verilator (cross-platform, works on macOS/Linux/Windows).
- Output: runs `tb_traffic_light.sv` and generates `tb_traffic_light.vcd` (open with `gtkwave tb_traffic_light.vcd`).
- Requirement: `verilator` must be in `PATH` (macOS example: `brew install verilator`).

### FPGA Build & Download

```bash
# Tang Nano 9K
make BOARD=9k download

# Tang Nano 20K
make BOARD=20k download
```

### Individual Tests

```bash
# Traffic light simulation
make test

# Display waveform
gtkwave tb_traffic_light.vcd
```

## Hardware Verification

The board top exposes only `clk`, `ResetButton`, and `led[5:0]`. There are no switch inputs or seven-segment display. `top_9k.sv` and `top_20k.sv` tie `top_core.sv`'s `switches` input to `4'b0` and leave its PWM output unconnected.

Inside `top_core.sv`, traffic-light state and low counter bits are mapped to the six LED signals. Check that the reset button restores the initial state and that the LEDs change as the circuits run. Internal signals such as `count_out`, `pwm_out`, shift output, and divided clock are not exposed on board pins.

## Learning Points

### SystemVerilog Sequential Circuits

- Synchronous circuit design using `always_ff`
- State definition using `typedef enum`
- Implementation of asynchronous reset
- Clock domain design

### State Machine Design

- Implementation of state transition diagrams
- Timer-based control
- Separation of combinational and sequential logic

### Practical Circuit Design

- PWM control techniques
- Shift register applications
- Clock division techniques
- Multi-module integration

## Advanced Assignments

1. **UART Transmitter**: State machine for serial communication
2. **Variable-Length Shift Register**: Dynamic bit-width control
3. **Multi-Stage Clock Divider**: More flexible frequency generation

These sequential circuits play an important role in the control part and timing control of the CPU.

The divider is disabled at ratio 0, bypasses the input clock at 1, and divides by 2..15. Change the ratio during reset. Prefer the original clock plus a clock enable for slowing internal logic.
