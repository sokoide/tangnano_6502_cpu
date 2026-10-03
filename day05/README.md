# Day 05: Program Counter, Reset, and Enable

[English](README.md) | [日本語](README_ja.md)

## Goal

Implement a 16-bit PC in `cpu.sv`. Reset it to `$0200`, increment it once on a rising edge
with `pc_enable=1`, and hold it when enable is zero. Drive `address_bus` and `debug_pc`
from the same PC. This CPU does not decode instructions yet; incrementing the PC prepares
for the instruction fetch introduced next.

## Step by Step

1. Implement the PC with an asynchronous active-low reset.
2. Update it only on an enabled rising edge. Arithmetic wraps at 16 bits.
3. Run `make test-cpu`: reset, two increments, and holds are checked.
4. Run `make sim`: it runs the LCD smoke test in addition to the CPU simulation.
5. Build with `make BOARD=9k` or `make BOARD=20k`. Hardware uses a slow display enable.
   Simulation success does not establish hardware operation.

The starter CPU test fails until its TODOs are implemented. The completed workspace uses
the same testbench with `day05_completed/cpu.sv`. Expect `$0200 → $0201 → $0202`.
The LCD A/X/Y/P/SP fields do not verify a register file in this CPU.

## Additional exercise: Register File

[`day05/cpu_registers.sv`](../day05/cpu_registers.sv) is a separate A/X/Y/SP/P exercise.
It is not connected to the CPU or LCD, and the completed workspace does not contain a
solution or unit test for it. Passing the CPU test does not complete this exercise.
Write a separate test for register reset, write enable, and hold behavior.

## Next Day

Day 06 adds A and the opcode/operand fetch for `LDA #imm`.
Day 04–09 use ROM; RAM, Zero Page, and stack arrive in Day 10.
