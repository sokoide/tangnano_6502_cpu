// cpu.sv - 6502 CPU Core Implementation
//
// This module implements a complete 6502 microprocessor with custom extensions
// for FPGA-based LCD display systems. The CPU includes:
//
// Standard 6502 Features:
// - All standard addressing modes (immediate, zero page, absolute, indexed, etc.)
// - Complete instruction set except interrupt-related instructions
// - Standard registers: A, X, Y, SP, PC, and status flags (C, Z, V, N, etc.)
// - 64KB addressable memory space with configurable memory map
//
// Custom Extensions:
// - CVR (0xCF): Clear VRAM - Hardware-accelerated VRAM clearing
// - IFO (0xDF): Info/Debug - Display registers and memory for debugging
// - HLT (0xEF): Halt - Stop CPU execution while preserving LCD operation
// - WVS (0xFF): Wait VSync - Synchronize with LCD vertical refresh
//
// Memory Map Integration:
// - 0x0000-0x00FF: Zero Page (256B)
// - 0x0100-0x01FF: Stack (256B)
// - 0x0200-0x7BFF: Program RAM (30.5KB)
// - 0x7C00-0x7FFF: Shadow VRAM (1KB, read-only)
// - 0xE000-0xE3FF: Text VRAM (1KB, write-only)
//
// State Machine Architecture:
// - Multi-stage fetch/decode/execute pipeline
// - Separate states for memory operations and custom instructions
// - Proper handling of different instruction lengths and addressing modes
//
`include "../include/consts.svh"
`include "../include/cpu_pkg.sv"
`include "cpu/cpu_types_pkg.sv"
`include "cpu/cpu_fsm_next_pkg.sv"
/* verilator lint_off WIDTHEXPAND */
/* verilator lint_off WIDTHTRUNC */
module cpu (
    // Clock and Reset
    input logic rst_n,  // Active-low asynchronous reset
    input logic clk,    // System clock (40.5MHz)

    // Memory Interface
    input  logic [ 7:0] dout,  // RAM read data
    output logic [ 7:0] din,   // RAM write data
    output logic [14:0] ada,   // RAM write address (32KB space)
    output logic [14:0] adb,   // RAM read address (32KB space)
    output logic        cea,   // RAM write enable
    output logic        ceb,   // RAM read enable

    // Video Memory Interface
    output logic [9:0] v_ada,  // VRAM write address (1KB space)
    output logic       v_cea,  // VRAM write enable
    output logic [7:0] v_din,  // VRAM write data (character codes)

    // System Integration
    input logic        vsync,                      // LCD vertical sync (for WVS instruction)
    input logic [ 7:0] boot_program       [7680],  // Boot program ROM (max 30KB)
    input logic [15:0] boot_program_length         // Actual boot program size
);

  import cpu_pkg::*;
  import cpu_types_pkg::*;
  import cpu_fsm_next_pkg::*;

  cpu_ctx_t cur, next;
  cpu_in_t cpu_inputs;

  always_comb begin
    cpu_inputs = '{
        dout: dout,
        vsync: vsync,
        boot_program_length: boot_program_length,
        boot_byte: boot_program[cur.boot_idx]
    };

    next = cpu_fsm_next_pkg::calc_cpu_next(cur, cpu_inputs);

    // Always-on sequential helpers (now expressed as next-state updates).
    next.counter = (cur.counter + 1) & 32'hFFFFFFFF;
    next.dout_r = dout;
    next.vsync_meta = vsync;
    next.vsync_sync = cur.vsync_meta;

    // Drive module outputs from the registered context.
    din = cur.din;
    ada = cur.ada;
    adb = cur.adb;
    cea = cur.cea;
    ceb = cur.ceb;
    v_ada = cur.v_ada;
    v_cea = cur.v_cea;
    v_din = cur.v_din;
  end

  // Sequential logic: use an asynchronous active-low rst_n.
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cur <= '{
          pc: 16'h0200,
          pc_plus1: 16'h0000,
          pc_plus2: 16'h0000,
          pc_plus3: 16'h0000,

          ra: 8'd0,
          rx: 8'd0,
          ry: 8'd0,
          sp: 8'hFF,

          flg_c: 1'b0,
          flg_z: 1'b0,
          flg_i: 1'b0,
          flg_d: 1'b0,
          flg_b: 1'b0,
          flg_v: 1'b0,
          flg_n: 1'b0,

          din: 8'h00,
          ada: 15'h0000,
          adb: PROGRAM_START,
          cea: 1'b0,
          ceb: 1'b1,

          v_ada: 10'h0000,
          v_cea: 1'b0,
          v_din: 8'h00,

          opcode: 8'h00,
          operands: 16'h0000,

          fetched_data_bytes: 3'd0,
          fetched_data: 16'h0000,
          written_data_bytes: 3'd0,

          write_to_vram: 1'b0,
          dout_r: 8'h00,

          char_code: 8'h20,
          counter: 32'h0,
          boot_idx: 15'd0,
          boot_write: 1'b0,

          vsync_meta: 1'b0,
          vsync_sync: 1'b0,
          vsync_stage: 2'd0,

          show_info_counter: 32'd0,
          show_info_cmd: '0,

          state: INIT,
          prev_state: INIT,
          fetch_resume_state: INIT,
          next_state: INIT,
          fetch_stage: FETCH_OPCODE,
          next_fetch_stage: FETCH_OPCODE,
          show_info_stage: SHOW_INFO_FETCH
      };
    end else begin
      cur <= next;
    end
  end

  /* verilator lint_on WIDTHTRUNC */
  /* verilator lint_on WIDTHEXPAND */
endmodule
