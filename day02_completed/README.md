# Day 02 Completed: SystemVerilog Combinational Circuits

This is the completed project for designing combinational circuits in SystemVerilog.

---

🌐 Available languages:
[English](./README.md) | [日本語](./README_ja.md)

## File Structure

- `seven_seg_decoder.sv` - 7-segment decoder
- `alu_4bit.sv` - 4-bit ALU
- `mux_8to1.sv` - 8-to-1 Multiplexer
- `top.sv` - Integrated test module
- `tb_alu_4bit.sv` - ALU testbench
- `Makefile` - Build and test automation

## Implemented Modules

### 1. 7-Segment Decoder

- Converts a 4-bit input (0-F) to signals for a 7-segment display
- Active-low output (lights up at 0)
- Supports hexadecimal display

### 2. 4-bit ALU

- Four types of operations: Addition, Subtraction, AND, OR
- Flag outputs: Zero, Carry
- Overflow/underflow detection

### 3. 8-to-1 Multiplexer

- Selects one of 8 inputs
- 3-bit select signal
- Implemented using a `case` statement

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
# ALU Simulation
make test

# Display waveform (requires GTKWave)
gtkwave tb_alu_4bit.vcd
```

## Test Contents

The ALU testbench tests the following:

1. Basic addition (5 + 3 = 8)
2. Overflow (15 + 1 = 0, carry=1)
3. Basic subtraction (8 - 3 = 5)
4. Zero result (5 - 5 = 0, zero=1)
5. AND operation (12 & 10 = 8)
6. OR operation (12 | 10 = 14)

## 🧪 Simulation Flow (Verilator)

- `make test` executes `tb_alu_4bit.sv` together with `alu_4bit.sv` by invoking Verilator, producing `Vtb_alu_4bit` and running it. The simulator prints each assertion or `$display` message from the testbench.
- The testbench drives inputs with `initial begin`, waits `#10` for the combinational logic to settle, and checks counts (`assert`) before calling `$finish`.
- You can inspect the generated waveform by running `gtkwave tb_alu_4bit.vcd` after the simulation if you added `$dumpfile`/`$dumpvars`.
- Introducing new modules? Follow the same pattern: instantiate the DUT, sequence input stimuli, verify outputs with `assert`, and keep every branch assigned to avoid inferred latches.

If you need a specific Verilator version, run `VERILATOR=/path/to/verilator make test`.

## Learning Points

### SystemVerilog Syntax

- Combinational circuits using `always_comb`
- Conditional branching using `case` statements
- Specifying bit widths and carry calculation
- Testing with assertions (`assert`)

### Design Methods

- Modular design and interface definition
- Functional verification with testbenches
- Hierarchical circuit structure

### Debugging Techniques

- Verifying operation with simulation
- Signal analysis with waveforms
- Identifying problems from error messages

## Advanced Assignments

1. **BCD Decoder**: Implement a decoder for Binary Coded Decimal
2. **Priority Encoder**: Output the position of the most significant '1' bit
3. **Parity Generator**: Calculate even/odd parity

These basic modules will be important building blocks in the later CPU design.
