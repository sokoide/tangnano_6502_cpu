// cpu_exec_flags_custom_pkg.sv - flag ops + custom extensions
//
// This package holds a self-contained, formatter-friendly implementation of:
// - Flag ops: CLC/SEC/CLV
// - Custom extensions: CVR/IFO/HLT/WVS
//
// Called from the CPU's DECODE_EXECUTE state. Reports whether it handled the opcode.

`include "consts_pkg.sv"

package cpu_exec_flags_custom_pkg;
  import cpu_pkg::*;
  import consts_pkg::*;

  task automatic exec_flags_custom(
      input logic [7:0] opcode, ref logic flg_c, ref logic flg_v, ref logic [15:0] operands,
      ref logic [31:0] show_info_counter, ref cpu_state_e prev_state, ref cpu_state_e state,
      ref show_info_stage_e show_info_stage, ref logic [1:0] vsync_stage, input logic vsync_sync,
      ref logic [15:0] pc, ref logic [15:0] pc_plus1, ref logic [15:0] pc_plus2,
      ref logic [15:0] pc_plus3, ref logic [14:0] adb, ref fetch_stage_e fetch_stage,
      output logic handled);
    handled = 1'b1;
    unique case (opcode)
      // CLC
      8'h18: begin
        flg_c = 1'b0;
        pc  <= pc_plus1;
        adb <= pc_plus1[14:0] & RAMW[14:0];
        state = FETCH_REQ;
        fetch_stage = FETCH_OPCODE;
      end
      // CLV
      8'hB8: begin
        flg_v = 1'b0;
        pc  <= pc_plus1;
        adb <= pc_plus1[14:0] & RAMW[14:0];
        state = FETCH_REQ;
        fetch_stage = FETCH_OPCODE;
      end
      // SEC
      8'h38: begin
        flg_c = 1'b1;
        pc  <= pc_plus1;
        adb <= pc_plus1[14:0] & RAMW[14:0];
        state = FETCH_REQ;
        fetch_stage = FETCH_OPCODE;
      end

      // Custom instructions (not in 6502)
      // CVR: clear VRAM
      8'hCF: begin
        state = CLEAR_VRAM;
      end
      // IFO: show registers and memory at $0000-$007F
      8'hDF: begin
        if (operands[15:0] != 16'hFFFF) begin
          show_info_counter <= 0;
          prev_state <= DECODE_EXECUTE;
          state = SHOW_INFO;
          show_info_stage <= SHOW_INFO_FETCH;
        end else begin
          show_info_counter <= 0;
          pc <= pc_plus3;
          adb <= pc_plus3[14:0] & RAMW[14:0];
          state = FETCH_REQ;
          fetch_stage = FETCH_OPCODE;
        end
      end
      // HLT: halt
      8'hEF: begin
        state = HALT;
      end
      // WVS: wait for vsync
      8'hFF: begin
        case (vsync_stage)
          0: begin
            if (vsync_sync == 1'b1) begin
              vsync_stage <= 1;
            end else begin
              vsync_stage <= 2;
            end
          end
          1: begin
            if (vsync_sync == 1'b0) begin
              vsync_stage <= 2;
            end
          end
          2: begin
            if (vsync_sync == 1'b1) begin
              if (operands[7:0] == 0) begin
                vsync_stage <= 0;
                pc <= pc_plus2;
                adb <= pc_plus2[14:0] & RAMW[14:0];
                state = FETCH_REQ;
                fetch_stage = FETCH_OPCODE;
              end else begin
                operands[7:0] = operands[7:0] - 1'b1;
                vsync_stage   = 1;
              end
            end
          end
        endcase
      end

      default: begin
        handled = 1'b0;
      end
    endcase
  endtask
endpackage
