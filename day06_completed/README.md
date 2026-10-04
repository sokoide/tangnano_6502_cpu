# Day 06: Immediate LDA and Two-Stage Fetch

[English](README.md) | [日本語](README_ja.md)

## Lesson at a glance

The reference solution already implements the tasks below.

| Item | Details |
| --- | --- |
| Where to edit | Opcode/operand-fetch TODOs in cpu.sv |
| Provided foundation | PC, A, pc_enable and LCD wiring |
| Expected test results | A/PC after immediate LDA, and holding when enable=0 |
| What to observe on hardware | ROM loads A=$42, then executes NOPs |

## Goal

Implement A and a two-state opcode/operand FSM in `cpu.sv`.
`A9 42` means `LDA #$42`: `$A9` is the opcode and `$42` is the value loaded into A.
The current completed CPU implements LDA and A/PC updates. It does not update Z/N or
instantiate the separate decoder/flag modules. Arithmetic CPU flags are tested in Day 08.

## Step by Step

1. Reset PC to `$0200`, A to `$00`, and the FSM to opcode fetch.
2. Recognize `$A9` in opcode fetch and advance PC/address to its operand.
3. Save the operand into A and advance to the next opcode.
4. Use the existing `pc_enable` input and hold state when it is zero.
   The completed interface already has this input. Day 04–09 use ROM; synchronous RAM waits arrive in Day 10.
5. Run `make test-cpu` to check multiple immediate loads, PC, and enable holds.
   The completed workspace connects the same testbench to the reference CPU.
   The starter fails until its TODOs are implemented.
6. Run `make sim` separately and build with `make BOARD=9k` / `make BOARD=20k`.
   LCD output alone does not verify instruction or flag correctness.

## Memory Example

| Address | Byte        | Meaning                     |
| ------- | ----------- | --------------------------- |
| `$0200` | `$A9`       | LDA immediate opcode        |
| `$0201` | `$42`       | Operand loaded into A       |
| `$0202` | next opcode | Fetch destination after LDA |

## Additional Exercises

[`day06/simple_decoder.sv`](../day06/simple_decoder.sv) and
[`day06/flag_calculator.sv`](../day06/flag_calculator.sv) are separate component exercises.
The CPU recognizes LDA with an internal case statement and does not instantiate these
modules. Their solutions and unit tests are not included in the completed workspace;
passing `make test-cpu` does not complete them. Test Z=`result == 0` and N=`result[7]`
separately; C/V have different requirements for the later ADC/SBC instructions.

## Next Day

Day 07 adds X/Y and register transfers. Day 08 adds ADC/SBC and C/V/Z/N verification.

CPU unit tests and the hardware ROM use different inputs. The hardware expectations above are derived from `rom.sv` and the LCD wiring; they do not mean that operation has been verified on every board.

LCD VSync passes through a two-stage synchronizer into the display-write clock domain. Its rising edge starts a frame update. VRAM and font reads remain in the pixel-clock domain.
