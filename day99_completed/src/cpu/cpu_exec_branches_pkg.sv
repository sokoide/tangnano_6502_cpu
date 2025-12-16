// cpu_exec_branches_pkg.sv - branch instructions
//
// Self-contained implementation of branch opcodes (BEQ/BMI/BNE/BPL/BVC/BVS/BCC).
// Called from the CPU's DECODE_EXECUTE state. Reports whether it handled the opcode.

`include "consts_pkg.sv"

package cpu_exec_branches_pkg;
  import cpu_pkg::*;
  import consts_pkg::*;

  task automatic exec_branches(
      input logic [7:0] opcode, input logic flg_c, input logic flg_z, input logic flg_v,
      input logic flg_n, ref logic [15:0] operands, ref logic signed [7:0] s_imm8,
      ref logic signed [15:0] s_offset, ref logic [15:0] addr, ref logic [15:0] pc,
      ref logic [15:0] pc_plus2, ref logic [14:0] adb, ref cpu_state_e state,
      ref fetch_stage_e fetch_stage, output logic handled);
    handled = 1'b1;
    unique case (opcode)
      // BEQ
      8'hF0: begin
        if (flg_z == 1) begin
          s_imm8 = operands[7:0];
          s_offset = {{8{s_imm8[7]}}, s_imm8};
          addr = (pc_plus2 + s_offset) & RAMW[15:0];
          pc  <= addr;
          adb <= addr[14:0];
        end else begin
          pc  <= pc_plus2;
          adb <= pc_plus2[14:0] & RAMW[14:0];
        end
        state = FETCH_REQ;
        fetch_stage = FETCH_OPCODE;
      end
      // BMI
      8'h30: begin
        if (flg_n == 1) begin
          s_imm8 = operands[7:0];
          s_offset = {{8{s_imm8[7]}}, s_imm8};
          addr = (pc_plus2 + s_offset) & RAMW[15:0];
          pc  <= addr;
          adb <= addr[14:0];
        end else begin
          pc  <= pc_plus2;
          adb <= pc_plus2[14:0] & RAMW[14:0];
        end
        state = FETCH_REQ;
        fetch_stage = FETCH_OPCODE;
      end
      // BNE
      8'hD0: begin
        if (flg_z == 0) begin
          s_imm8 = operands[7:0];
          s_offset = {{8{s_imm8[7]}}, s_imm8};
          addr = (pc_plus2 + s_offset) & RAMW[15:0];
          pc  <= addr;
          adb <= addr[14:0];
        end else begin
          pc  <= pc_plus2;
          adb <= pc_plus2[14:0] & RAMW[14:0];
        end
        state = FETCH_REQ;
        fetch_stage = FETCH_OPCODE;
      end
      // BPL
      8'h10: begin
        if (flg_n == 0) begin
          s_imm8 = operands[7:0];
          s_offset = {{8{s_imm8[7]}}, s_imm8};
          addr = (pc_plus2 + s_offset) & RAMW[15:0];
          pc  <= addr;
          adb <= addr[14:0];
        end else begin
          pc  <= pc_plus2;
          adb <= pc_plus2[14:0] & RAMW[14:0];
        end
        state = FETCH_REQ;
        fetch_stage = FETCH_OPCODE;
      end
      // BVC
      8'h50: begin
        if (flg_v == 0) begin
          s_imm8 = operands[7:0];
          s_offset = {{8{s_imm8[7]}}, s_imm8};
          addr = (pc_plus2 + s_offset) & RAMW[15:0];
          pc  <= addr;
          adb <= addr[14:0];
        end else begin
          pc  <= pc_plus2;
          adb <= pc_plus2[14:0] & RAMW[14:0];
        end
        state = FETCH_REQ;
        fetch_stage = FETCH_OPCODE;
      end
      // BVS
      8'h70: begin
        if (flg_v == 1) begin
          s_imm8 = operands[7:0];
          s_offset = {{8{s_imm8[7]}}, s_imm8};
          addr = (pc_plus2 + s_offset) & RAMW[15:0];
          pc  <= addr;
          adb <= addr[14:0];
        end else begin
          pc  <= pc_plus2;
          adb <= pc_plus2[14:0] & RAMW[14:0];
        end
        state = FETCH_REQ;
        fetch_stage = FETCH_OPCODE;
      end
      // BCC
      8'h90: begin
        if (flg_c == 0) begin
          s_imm8 = operands[7:0];
          s_offset = {{8{s_imm8[7]}}, s_imm8};
          addr = (pc_plus2 + s_offset) & RAMW[15:0];
          pc  <= addr;
          adb <= addr[14:0];
        end else begin
          pc  <= pc_plus2;
          adb <= pc_plus2[14:0] & RAMW[14:0];
        end
        state = FETCH_REQ;
        fetch_stage = FETCH_OPCODE;
      end
      default: begin
        handled = 1'b0;
      end
    endcase
  endtask
endpackage
