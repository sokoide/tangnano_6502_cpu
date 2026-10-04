# From Day18 to Day99

Day18 and Day99 do not use the same CPU file unchanged. Start in `day99_completed`, run `make test`, and build for your board.

| Item | Day18 | Day99 |
| --- | --- | --- |
| CPU control | FSM and instruction handling in one `always_ff` in `cpu.sv` | A two-process FSM: `calc_cpu_next` computes the next state from the current `cpu_ctx_t`, and `always_ff` captures it |
| Arithmetic and decode | Implemented inside the CPU | Implemented in `cpu_fsm_next_pkg.sv`. The independent `cpu_alu.sv` / `cpu_decoder.sv` modules are not connected to the CPU |
| Boot | `boot_loader.sv` copies 256 bytes from `rom.sv` to `$0200` | The CPU initializes RAM from the assembled boot image |
| VRAM | Not connected to the CPU address space; CVR/IFO control the LCD display FSM | CPU writes characters to `$E000–$E3FF`; the readable shadow copy is at `$7C00–$7FFF` |
| WVS count | `max(1,N)` edges; zero also waits once | `N+1` edges; zero waits once and one waits twice |
| Unsupported opcodes | Depends on each day's default handling | Stops with a fault instead of silently executing an instruction outside the subset |

Day18 `WVS #$3A` waits for 58 edges. In Day99, use operand `$39` for the same count. Standard 6502 assemblers do not recognize the custom instructions; encode them with `.byte`, as the examples do.

## Synchronous RAM read timing

Day10–18 CPUs use `memory_ready` and `step_pending` to handle read waits and execution permission. The table shows a representative request. Nonblocking assignments read values from before the clock edge, so a CPU cannot capture the new RAM output at the same edge that produces it.

| Edge | CPU | Synchronous RAM |
| --- | --- | --- |
| t0 | FSM outputs the requested address, `memory_ready=0` | Reads the address present before the edge |
| t1 | Waits, sets `memory_ready=1`, and saves an enable request | Reads the address issued at t0 and updates its output |
| t2 | Advances the FSM using the t1 result if enable or a saved request is present | Reads the current address |

RAM accepts writes when `write_en` is asserted with a valid address and data. In Day18, `memory_hold` stalls the CPU while the display FSM uses RAM.

The CPU unit tests' `assign data_in = mem[address_bus]` is an asynchronous read model. Passing those tests alone does not verify BSRAM latency. In the reference solutions, `make test-sync` checks continuous execution and intermittent enable using synchronous RAM. Day99 additionally uses a registered read path.

## Run your own program

```bash
cd day99_completed
make prog PROG=simple   # Generate boot ROM from examples/simple.s
make BOARD=9k          # Synthesis and place-and-route; use BOARD=20k for 20K
make BOARD=9k download
```

Edit `examples/*.s` rather than generated files. Check the [instruction contract](../day99_completed/docs/INSTRUCTIONS.md) for supported instructions and memory layout before writing a program. Interrupts, decimal arithmetic and complete NMOS 6502 cycle compatibility are outside the scope.

Verify simulation, place-and-route timing, and board startup/display separately.
