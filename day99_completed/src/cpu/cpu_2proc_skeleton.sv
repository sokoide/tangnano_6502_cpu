// cpu_2proc_skeleton.sv - planned 2-process CPU refactor skeleton
//
// This file is intentionally not wired into the build yet.
// It exists as a compilation-unit target for the refactor described in
// `docs/MODULE_MAP.md` ("Refactor policy").
//
// End-state intent:
// - `cpu_ctx_t cur/next` (from `cpu_types_pkg`)
// - `always_comb` computes `next` from `cur` + inputs
// - `always_ff` updates `cur <= next`
// - Opcode execution is split into category packages (formatter-friendly)

`include "../../include/consts.svh"
`include "../../include/cpu_pkg.sv"
`include "cpu_types_pkg.sv"

module cpu_2proc_skeleton (
    input logic rst_n,
    input logic clk,

    input logic [7:0] dout,
    output logic [7:0] din,
    output logic [14:0] ada,
    output logic [14:0] adb,
    output logic cea,
    output logic ceb,

    output logic [9:0] v_ada,
    output logic v_cea,
    output logic [7:0] v_din,

    input logic vsync,
    input logic [7:0] boot_program[7680],
    input logic [15:0] boot_program_length
);
  import cpu_types_pkg::*;

  cpu_ctx_t cur, next;
  cpu_in_t in;

  always_comb begin
    in = '0;
    in.dout = dout;
    in.vsync = vsync;
    in.boot_program_length = boot_program_length;

    next = cur;

    din = cur.din;
    ada = cur.ada;
    adb = cur.adb;
    cea = cur.cea;
    ceb = cur.ceb;
    v_ada = cur.v_ada;
    v_cea = cur.v_cea;
    v_din = cur.v_din;
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cur <= '0;
    end else begin
      cur <= next;
    end
  end
endmodule

