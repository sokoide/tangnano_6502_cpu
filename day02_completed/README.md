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

## 🧪 What is a Testbench? (A "Unit Test" for Hardware)

A **testbench** is a SystemVerilog module that exists **only for simulation**. Its job is to "wrap around" your design (the "Design Under Test" or DUT), feed it inputs, and check if the outputs are correct. This code is **never synthesized** into an actual FPGA circuit.

A testbench typically does three things:

1. **Instantiate the DUT**: Create an instance of the module you want to test (e.g., `alu_4bit`).
2. **Provide Stimulus**: Drive the input ports of your DUT with various values. The `#10` is a simulation-only delay to give the circuit time to react.
3. **Check Results**: Use `assert` to verify that the DUT's outputs match expected values.

## 🔬 What is Verilator? (The Hardware "Transpiler")

**Verilator** is a simulator that acts like a **transpiler**. It converts your SystemVerilog code into a C++ model that behaves exactly like your hardware. This C++ code is then compiled into a normal executable program that you can run to see the test results.

The `make test` command automates this entire flow:

```mermaid
flowchart LR
    subgraph Your Code
        A["alu_4bit.sv (Your Design)"]
        B["tb_alu_4bit.sv (Your Testbench)"]
    end

    subgraph "make test" Automation
        direction LR
        C(Verilator Tool)
        D{C++ Compiler<br/>(like g++)}
        E[Executable<br/>Sim-Program]
        F[Run Program]
    end

    subgraph Result
        G["'Test Passed!' or<br/>'Test Failed!'"]
    end

    A -- feeds --> C
    B -- feeds --> C
    C -- generates --> D
    D -- compiles --> E
    E -- is run by --> F
    F -- produces --> G
```

### How to View Waveforms

To debug your design visually, you can generate a waveform file. The included `tb_alu_4bit.sv` already has the necessary lines:

```systemverilog
initial begin
    $dumpfile("tb_alu_4bit.vcd");
    $dumpvars(0, tb_alu_4bit);
    // ... rest of the test cases
end
```

After running `make test`, you can open the generated `tb_alu_4bit.vcd` file with a viewer like GTKWave:

```bash
gtkwave tb_alu_4bit.vcd
```

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
