# FPGA / SystemVerilog Glossary

---

🌐 Available languages:
[English](./GLOSSARY.md) | [日本語](./GLOSSARY_ja.md)

## Hardware Concepts

| Term      | Definition                                                                          |
| --------- | ----------------------------------------------------------------------------------- |
| **FPGA**  | Field-Programmable Gate Array. A chip with reconfigurable logic blocks.             |
| **RTL**   | Register-Transfer Level. HDL code describing registers and combinational logic.     |
| **LUT**   | Look-Up Table. Small truth tables implementing combinational logic.                 |
| **FF**    | Flip-Flop. A 1-bit register that updates on a clock edge.                           |
| **BSRAM** | Block Static RAM. Dedicated on-chip memory blocks inside the FPGA.                  |
| **PLL**   | Phase-Locked Loop. Generates precise clock frequencies from a reference.            |
| **FSM**   | Finite State Machine. A design pattern for sequential circuits with defined states. |

## SystemVerilog Keywords

| Term              | Definition                                                                  |
| ----------------- | --------------------------------------------------------------------------- |
| **`logic`**       | Modern data type for both wires and registers. Preferred over `wire`/`reg`. |
| **`always_ff`**   | Sequential logic block triggered on clock edges. Creates registers.         |
| **`always_comb`** | Combinational logic block. No clock; outputs react instantly to inputs.     |
| **`assign`**      | Continuous assignment for combinational logic (wiring).                     |
| **`posedge`**     | Positive (rising) edge of a signal (0 → 1 transition).                      |
| **`negedge`**     | Negative (falling) edge of a signal (1 → 0 transition).                     |
| **`<=`**          | Non-blocking assignment. Used in `always_ff` for concurrent updates.        |
| **`=`**           | Blocking assignment. Used in `always_comb` or testbenches.                  |

## Development Process

| Term              | Definition                                                            |
| ----------------- | --------------------------------------------------------------------- |
| **Synthesis**     | Converting RTL code into a netlist of logic primitives (LUTs, FFs).   |
| **Place & Route** | Mapping logic onto physical FPGA resources and connecting wires.      |
| **Bitstream**     | Binary file programmed into the FPGA to configure its logic.          |
| **Testbench**     | Simulation-only code that tests a hardware module (like a unit test). |
| **DUT**           | Design Under Test. The module being tested in a testbench.            |
| **Waveform**      | Time-based graph of signal values during simulation.                  |

## 6502 CPU Terms

| Term                | Definition                                                            |
| ------------------- | --------------------------------------------------------------------- |
| **PC**              | Program Counter. Holds the address of the next instruction.           |
| **SP**              | Stack Pointer. Points to the current position in the stack.           |
| **ALU**             | Arithmetic Logic Unit. Performs math and logic operations.            |
| **Zero Page**       | Memory addresses `$0000`-`$00FF`. Fast access with 1-byte addresses.  |
| **Opcode**          | Operation code. The byte that specifies which instruction to execute. |
| **Addressing Mode** | How the CPU determines the operand's memory location.                 |
