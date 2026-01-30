# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a step-by-step FPGA learning curriculum for implementing a MOS 6502 CPU from scratch in SystemVerilog on Tang Nano 9K/20K boards. The project progresses from basic digital circuits (Day 01-04) through a complete 6502 CPU implementation (Day 05-18) to a final integrated system (Day 99).

**Key Learning Progression:**

- **Phase 1 (Day 01-04)**: Environment setup, ALU, state machines, LCD debug infrastructure
- **Phase 2 (Day 05-10)**: CPU core implementation - registers, memory access, ALU, branching, stack
- **Phase 3 (Day 11-15)**: Addressing modes and data processing instructions
- **Phase 4 (Day 16-18)**: Advanced addressing modes (indexed, indirect) and custom instructions
- **Day 99**: Complete integrated system with LCD display, VRAM, and assembly toolchain

## Directory Structure

```
dayXX/              - Student workspace (starter code, edit here)
dayXX_completed/    - Reference solutions (working implementations)
docs/               - Learning resources (cheatsheets, guides, glossaries)
```

**Daily Workflow Pattern:**

1. Read `dayXX/README.md` for learning objectives
2. Edit `.sv` files in `dayXX/`
3. Run `make test` (Verilator simulation) - unit test equivalent
4. Run `make download` (FPGA programming) - production deployment equivalent

## Build Commands

### Per-Day Development (Typical Workflow)

```bash
cd dayXX                    # Enter workspace directory
make                        # Build FPGA bitstream
make test                   # Run simulation tests
make download               # Program Tang Nano board
make clean                  # Clean build artifacts
```

### Batch Operations (From Repository Root)

```bash
make                        # Build all day*_completed projects
make test                   # Run all simulations
make clean                  # Clean all projects
make format                 # Format markdown and SystemVerilog files
make BOARD=20k              # Target Tang Nano 20K (default: 9K)
```

### Assembly Programming (Day 10+)

```bash
cd examples                 # Contains 6502 assembly programs
make clean && make          # Build assembly (ca65/cc65 toolchain)
# Edit SRCS variable in examples/Makefile to select program
```

## Architecture Overview

### System Block Diagram

```
┌─────────────────────────────────────────────────┐
│  Tang Nano FPGA (9K or 20K)                     │
│                                                 │
│  ┌──────────────┐       ┌──────────────────┐    │
│  │ 6502 CPU     │◄─────┤ 32KB RAM (SDPB)  │    │
│  │ 40.5MHz      │       │ 0x0200-0x7BFF    │    │
│  └──────┬───────┘       └──────────────────┘    │
│         │                                       │
│         ├──────────────┐                        │
│         │              │                        │
│         ▼              ▼                        │
│  ┌──────────┐   ┌─────────────┐                │
│  │ 1KB VRAM │◄──┤ Font ROM    │                │
│  │ 0xE000   │   │ 4KB (pROM)  │                │
│  └────┬─────┘   └─────────────┘                │
│       │                                         │
│       ▼                                         │
│  ┌─────────────┐                               │
│  │ LCD Control │  480×272 display              │
│  │ 9MHz        │  60×17 text mode               │
│  └─────────────┘                               │
│                                                 │
│  27MHz XTAL → PLL40 (40.5MHz CPU/MEM)           │
│           → PLL9 (9MHz LCD)                     │
└─────────────────────────────────────────────────┘
```

### Memory Map

```
0x0000-0x00FF  Zero Page (256B) - Fast 8-bit addressing
0x0100-0x01FF  Stack (256B) - Hardware stack
0x0200-0x7BFF  Program RAM (30.5KB) - Main program memory
0x7C00-0x7FFF  Shadow VRAM (1KB) - CPU-readable VRAM copy
0x8000-0xDFFF  Unmapped (24KB) - Available for expansion
0xE000-0xE3FF  Text VRAM (1KB) - CPU-writable display memory
0xE400-0xEFFF  Unmapped (3KB) - Future expansion
0xF000-0xFFFF  Font ROM (4KB) - LCD controller only, not CPU-accessible
```

### Clock Domains

- **27MHz**: Crystal oscillator input
- **40.5MHz**: CPU and memory operations (via PLL40)
- **9MHz**: LCD pixel clock (via PLL9)

**Critical**: Always use proper synchronizers for clock domain crossings (e.g., VRAM read address from LCD domain to memory domain).

### Custom 6502 Instructions (Day 17+)

- `0xCF` **CVR**: Clear VRAM - Hardware-accelerated screen clear
- `0xDF` **IFO**: Info/Debug - Display registers and memory contents
- `0xEF` **HLT**: Halt CPU (LCD controller continues)
- `0xFF` **WVS**: Wait VSync - Synchronize with display refresh

## Board Variants

**Tang Nano 9K vs 20K Differences:**

- Device: `GW1NR-9C` vs `GW2AR-18C`
- Reset polarity: `rst_n = ResetButton` (9K) vs `rst_n = !ResetButton` (20K)
- Top-level wrapper: `top_9k.sv` vs `top_20k.sv`
- PLL configuration: Different Gowin PLL primitives

Build system handles board selection via `BOARD=9k|20k` variable.

## CPU Implementation Patterns

### State Machine Architecture (Day 99)

The Day 99 CPU uses a **2-process FSM** pattern for safe refactoring:

- `always_comb`: Computes `next = calc_cpu_next(cur, inputs)`
- `always_ff`: Updates `cur <= next` on clock edge

**Key Files:**

- `src/cpu.sv`: Main CPU module with state register
- `src/cpu/cpu_fsm_next_pkg.sv`: Combinational next-state logic
- `src/cpu/cpu_types_pkg.sv`: Type definitions (cpu_ctx_t, cpu_in_t)

### Educational vs Production Architecture

- **Day 06-18**: Educational, step-by-step build-up with modular boundaries optimized for learning clarity
- **Day 99**: Integrated system with converged 2-process FSM for maintenance safety

For understanding incremental learning, use day06-18. For production-oriented patterns, reference day99.

## Common Development Patterns

### Adding CPU Instructions

1. Define instruction in appropriate category package (e.g., `calc_decode_transfers_next`)
2. Handle operand fetch in `FETCH_RECV` state
3. Implement execution in `DECODE_EXECUTE` state
4. Update `docs/INSTRUCTIONS.md` documentation

### Memory-Mapped I/O

```systemverilog
// VRAM write example (Day 07+)
if (addr >= VRAM_START && addr <= VRAM_END) begin
    v_ada <= addr - VRAM_START;  // Map to 1KB VRAM space
    v_din <= data;
    v_cea <= 1;  // Enable VRAM write
    write_to_vram <= 1'b1;
end
```

### Testbench Structure

```systemverilog
module tb_<module>;
    logic clk, rst_n;
    // DUT signals

    <module>_name dut (.*);

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_<module>);

        // Reset sequence
        rst_n = 0; #100; rst_n = 1;

        // Test logic
        @(...)
        assert(condition) else $error("...");

        #1000 $finish;
    end

    always #5 clk = ~clk;  // 100MHz clock
endmodule
```

## Toolchain Details

### Required Tools

- **Gowin EDA**: FPGA synthesis and programming (`gw_sh`, `programmer_cli`)
- **Verilator**: Fast SystemVerilog simulator for unit testing
- **cc65/ca65**: 6502 assembler and toolchain
- **GTKwave**: Waveform viewer for `*.vcd` files
- **srecord**: Intel HEX conversion utilities

### Tool Path Configuration

Makefiles auto-detect macOS Gowin installation at `/Applications/GowinIDE.app/`. Override via:

```bash
make GWSH=/path/to/gw_sh PRG=/path/to/programmer_cli download
```

## Learning Resources

- **SystemVerilog Cheatsheet**: `docs/SYSTEMVERILOG_CHEATSHEET.md`
- **Common Pitfalls**: `docs/COMMON_PITFALLS.md` - Hardware mindset shifts
- **Debugging Guide**: `docs/DEBUGGING_GUIDE.md` - Waveform analysis techniques
- **Glossary**: `docs/GLOSSARY.md` - FPGA terminology
- **Instruction Reference**: `day99_completed/docs/INSTRUCTIONS.md`

## Code Style Conventions

- **Indentation**: 4 spaces (enforced by verible-verilog-format)
- **Line length**: ~100 columns
- **Naming**:
  - Modules/files: `lower_snake_case`
  - Constants/parameters: `UPPER_SNAKE_CASE`
  - Signals: `lower_snake_case`
  - Testbenches: `tb_*.sv`
- **Structure**: One module per file, concise headers

## Key Implementation Notes

### Day 04-09 vs Day 10+ Memory Models

- **Day 04-09**: Simple program ROM (`rom.sv`), no RAM
- **Day 10+**: Full memory system with BSRAM RAM, Zero Page, Stack

### Boot Process (Day 10+)

1. CPU copies `boot_program` array to RAM at 0x0200 (INIT_RAM state)
2. Sets PC to 0x0200
3. Begins normal fetch/decode/execute cycle

The `boot_program` array is auto-generated from assembly source via:

```
assembly (ca65) → binary (ld65) → Intel HEX (srec_cat) → SystemVerilog (hex_fpga Go tool)
```

### LCD Display System

- **60×17 text mode** (480×272 pixels / 16×8 font)
- **Character rendering**: Hardware fetches from VRAM, looks up font bitmap
- **Timing**: 9MHz pixel clock, ~58 FPS refresh rate

## Testing Strategy

1. **Simulation First**: Use `make test` / Verilator before hardware testing
2. **Waveform Analysis**: Use GTKwave on `*.vcd` files to debug timing issues
3. **Incremental Validation**: Test each instruction/category before integration
4. **Hardware Verification**: Confirm with `make download` after simulation passes

## Common Issues

### Reset Polarity

- **9K**: Active-high button → `rst_n = ResetButton`
- **20K**: Active-low button → `rst_n = !ResetButton`
- Always check board variant in `top_*.sv`

### Clock Domain Crossings

Use 2-stage synchronizers for signals crossing clock domains:

```systemverilog
always_ff @(posedge dst_clk) begin
    sync1 <= src_signal;
    sync2 <= sync1;  // Use sync2
end
```

### Memory-Mapped I/O Timing

VRAM writes must account for LCD read access:

- CPU writes to VRAM via port A (write-only)
- LCD reads via port B (read-only)
- Shadow VRAM at 0x7C00-0x7FFF allows CPU to read display contents

## Commit Message Style

Follow conventional commits:

- `feat:` - New feature/instruction
- `fix:` - Bug fix
- `refactor:` - Code restructuring without behavior change
- `docs:` - Documentation updates
- `test:` - Test additions
- `improve:` - General improvements
- `update:` - General updates

Include day reference and hardware verification status in commit body.
