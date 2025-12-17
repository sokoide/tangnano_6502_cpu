# Day 04 Completed: 6502 CPU Architecture Overview

This is the completed implementation of the basic architecture and register set of the 6502 CPU.

---

🌐 Available languages:
[English](./README.md) | [日本語](./README_ja.md)

## File Structure

- `cpu_registers.sv` - 6502 register set
- `simple_decoder.sv` - Basic instruction decoder
- `flag_calculator.sv` - Flag calculation unit
- `top.sv` - Integrated test module
- `tb_cpu_registers.sv` - Register testbench
- `Makefile` - Build and test automation

## Implemented Modules

### 1. CPU Register Set

**8-bit Registers:**

- A (Accumulator): The main player in arithmetic
- X, Y (Index): For indexing
- SP (Stack Pointer): Manages the stack position
- P (Processor Status): Flag register

**16-bit Register:**

- PC (Program Counter): Address of the next instruction

**Initialization Values:**

- A, X, Y: 0x00
- SP: 0xFF (top of the stack)
- PC: 0x0200 (program start)
- P: 0x20 (interrupts disabled)

### 2. Instruction Decoder

Major instruction classifications:

- Load/Store instructions (LDA, STA, etc.)
- Transfer instructions (TAX, TAY, etc.)
- Arithmetic instructions (ADC, SBC)
- Logical operations (AND, ORA, EOR)
- Shift instructions (ASL, LSR, ROL, ROR)
- Branch instructions (BEQ, BNE, etc.)
- Jump/Subroutine (JMP, JSR, RTS)

### 3. Flag Calculation Unit

- N (Negative): Result is negative
- Z (Zero): Result is zero
- C (Carry): Carry/borrow
- V (Overflow): Signed overflow

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

## Test Contents

The register testbench tests the following:

1. Initial values at reset
2. Individual writes to each register
3. Simultaneous write operations
4. Data retention function

## Hardware Verification

### Inputs

- `rst_n`: Reset button
- `switches[3:0]`: Instruction selection and test control

### Outputs

- `debug_reg_a[7:0]`: Value of the A register
- `led_load`: Load instruction LED
- `led_store`: Store instruction LED
- `led_arithmetic`: Arithmetic instruction LED
- `led_branch`: Branch instruction LED

### Operation Modes

1. **Automatic Test Mode**: switch[3]=0
   - Sequentially writes values to the registers
   - Demonstration of instruction decoding

2. **Manual Test Mode**: switch[3]=1
   - Select an instruction with switches[2:0]
   - The corresponding LED lights up

## Learning Points

### 6502 Architecture

- Simple register set
- Memory-mapped I/O
- Fixed stack area
- Flag-driven conditional branching

### Implementation Techniques

- Multi-port register design
- Instruction classification and decoding
- Flag generation logic
- Testbench design

### Debugging Methods

- Visualization of register states
- Verification of instruction classification
- Verification by simulation

## Advanced Assignments

1. **Addressing Mode Detection**: Identify the addressing mode of an instruction
2. **Instruction Length Calculation**: Calculate the number of bytes for each instruction
3. **Illegal Instruction Handling**: Handling of undefined opcodes

Using this foundation, we will learn more detailed instruction decoding and addressing in the next Day.

---

### 4. LCD Demonstration (Day 09 Preview)

Day 04 now exposes the Day 09 LCD pipeline so you can see the character display hardware much earlier in the course:

- `lcd_demo.sv` instantiates the LCD controller plus VRAM/font ROM from the Day 09 FPGA project.
- The supporting RTL lives under `lcd/`:
  - `lcd/lcd.sv`, `lcd/font_rom.sv`, `lcd/vram.sv`: character display pipeline.
  - `lcd/tb_tft.sv`: simple testbench for the LCD domain.
- `include/consts.svh`: timing constants reused by the LCD modules.
- `sim/Gowin_rPLL9_stub.sv` mirrors the PLL stub used in the other days so you can simulate the demo locally.

To experiment with the LCD, open `lcd_demo.sv` from a new GoWin project or invoke Verilator directly with the `lcd/` sources. This early preview should make the later Day 09 system feel familiar by the time you arrive there.
