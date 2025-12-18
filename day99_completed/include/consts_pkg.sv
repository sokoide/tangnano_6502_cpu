// consts_pkg.sv - constants for use in packages/modules
//
// Gowin's compiler rejects references from within a package to $unit-scoped
// `localparam` definitions (as produced by including consts.svh directly).
// This file provides the same constants inside a real SystemVerilog package.

`ifndef CONSTS_PKG_SV
`define CONSTS_PKG_SV

/* verilator lint_off UNUSEDPARAM */
package consts_pkg;
    // RAM
    localparam int RAMW = 32'h00007FFF;
    // Convenience masks with explicit widths to avoid tool/lint width truncation warnings.
    localparam logic [15:0] RAMW16 = 16'h7FFF;
    localparam logic [14:0] RAMW15 = 15'h7FFF;
    localparam int VRAMW = 32'h000003FF;
    localparam logic [9:0] VRAMW10 = 10'h3FF;
    localparam int VRAM_START = 32'h0000E000;
    localparam int SHADOW_VRAM_START = 32'h00007C00;
    localparam logic [15:0] SHADOW_VRAM_START16 = 16'h7C00;
    localparam logic [15:0] STACK = 16'h0100;  // stack: 0x100-0x1FF, referenced by STACK+sp
    localparam int PROGRAM_START = 32'h00000200;
    localparam logic [14:0] PROGRAM_START15 = 15'h0200;

    // LCD Display Parameters
    localparam logic [15:0] CHAR_WIDTH = 16'd8;  // pixels per character
    localparam logic [15:0] CHAR_HEIGHT = 16'd16;  // pixels per character
    localparam int COLUMNS = 60;  // characters per row (480/8)
    localparam int ROWS = 17;  // character rows (272/16)

    // LCD Timing Parameters (for 480x272 display)
    localparam int H_PixelValid = 480;
    localparam int H_BackPorch = 43;
    localparam int H_FrontPorch = 8;  // 4+4 simplified
    localparam int PixelForHS = H_BackPorch + H_PixelValid + H_FrontPorch;

    localparam int V_PixelValid = 272;
    localparam int V_BackPorch = 12;
    localparam int V_FrontPorch = 8;  // 4+4 simplified
    localparam int PixelForVS = V_BackPorch + V_PixelValid + V_FrontPorch;
endpackage : consts_pkg
/* verilator lint_on UNUSEDPARAM */

`endif
