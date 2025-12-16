// cpu_exec_shifts_pkg.sv - shift/rotate instructions
//
// Self-contained implementation of legacy shift/rotate opcodes present in decode_shifts.svinc:
// - ASL (A/zp/zpx/abs/absx)
// - LSR (A/zp/zpx/abs/absx)
// - ROL (A/zp/zpx/abs/absx)
// - ROR (A/zp/zpx/abs)
//
// Called from the CPU's DECODE_EXECUTE state. Reports whether it handled the opcode.

`include "consts_pkg.sv"

/* verilator lint_off UNUSEDSIGNAL */
package cpu_exec_shifts_pkg;
  import cpu_pkg::*;
  import consts_pkg::*;

  task automatic exec_shifts(
      input logic [7:0] opcode, ref logic [7:0] ra, input logic [7:0] rx, ref logic flg_c,
      ref logic flg_z, ref logic flg_n, ref logic [15:0] operands,
      ref logic [2:0] fetched_data_bytes, input logic [7:0] dout_r, ref logic [15:0] pc,
      ref logic [15:0] pc_plus1, ref logic [15:0] pc_plus2, ref logic [15:0] pc_plus3,
      ref logic [14:0] ada, ref logic [7:0] din, ref logic [14:0] adb, ref logic cea,
      ref logic v_cea, ref cpu_state_e state, ref fetch_stage_e fetch_stage,
      ref cpu_state_e fetch_resume_state, output logic handled);
    handled = 1'b1;

    unique case (opcode)
      // ASL accumulator
      8'h0A: begin
        flg_c = ra[7];
        ra = ra << 1;
        flg_z = (ra == 8'h00);
        flg_n = ra[7];
        pc  <= pc_plus1;
        adb <= pc_plus1[14:0] & RAMW[14:0];
        state = FETCH_REQ;
        fetch_stage = FETCH_OPCODE;
      end
      // ASL zero page
      8'h06: begin
        if (fetched_data_bytes == 0) begin
          adb <= {7'd0, operands[7:0]} & RAMW[14:0];
          state = FETCH_REQ;
          fetch_stage = FETCH_DATA;
          fetch_resume_state <= DECODE_EXECUTE;
        end else begin
          flg_c = dout_r[7];
          din <= dout_r << 1;
          ada <= {7'd0, operands[7:0]};
          cea   = 1;
          v_cea = 0;
          flg_z = (din == 8'h00);
          flg_n = din[7];
          pc  <= pc_plus2;
          adb <= pc_plus2[14:0] & RAMW[14:0];
          state = FETCH_REQ;
          fetch_stage = FETCH_OPCODE;
        end
      end
      // ASL zero page, X
      8'h16: begin
        if (fetched_data_bytes == 0) begin
          automatic logic [7:0] zp_addr = operands[7:0] + rx;
          adb <= {7'd0, zp_addr} & RAMW[14:0];
          state = FETCH_REQ;
          fetch_stage = FETCH_DATA;
          fetch_resume_state <= DECODE_EXECUTE;
        end else begin
          automatic logic [7:0] zp_addr = operands[7:0] + rx;
          flg_c = dout_r[7];
          din <= dout_r << 1;
          ada <= {7'd0, zp_addr};
          cea   = 1;
          v_cea = 0;
          flg_z = (din == 8'h00);
          flg_n = din[7];
          pc  <= pc_plus2;
          adb <= pc_plus2[14:0] & RAMW[14:0];
          state = FETCH_REQ;
          fetch_stage = FETCH_OPCODE;
        end
      end
      // ASL absolute
      8'h0E: begin
        if (fetched_data_bytes == 0) begin
          automatic logic [15:0] addr = operands[15:0] & 16'hFFFF;
          adb <= addr[14:0] & RAMW[14:0];
          state = FETCH_REQ;
          fetch_stage = FETCH_DATA;
          fetch_resume_state <= DECODE_EXECUTE;
        end else begin
          flg_c = dout_r[7];
          din <= dout_r << 1;
          ada <= operands[14:0] & RAMW[14:0];
          cea   = 1;
          v_cea = 0;
          flg_z = (din == 8'h00);
          flg_n = din[7];
          pc  <= pc_plus3;
          adb <= pc_plus3[14:0] & RAMW[14:0];
          state = FETCH_REQ;
          fetch_stage = FETCH_OPCODE;
        end
      end
      // ASL absolute, X
      8'h1E: begin
        if (fetched_data_bytes == 0) begin
          automatic logic [15:0] addr = (operands[15:0] + {8'h00, rx}) & 16'hFFFF;
          adb <= addr[14:0] & RAMW[14:0];
          state = FETCH_REQ;
          fetch_stage = FETCH_DATA;
          fetch_resume_state <= DECODE_EXECUTE;
        end else begin
          automatic logic [15:0] addr = (operands[15:0] + {8'h00, rx}) & 16'hFFFF;
          flg_c = dout_r[7];
          din <= dout_r << 1;
          ada <= addr[14:0] & RAMW[14:0];
          cea   = 1;
          v_cea = 0;
          flg_z = (din == 8'h00);
          flg_n = din[7];
          pc  <= pc_plus3;
          adb <= pc_plus3[14:0] & RAMW[14:0];
          state = FETCH_REQ;
          fetch_stage = FETCH_OPCODE;
        end
      end

      // LSR accumulator
      8'h4A: begin
        flg_c = ra[0];
        ra = ra >> 1;
        flg_z = (ra == 8'h00);
        flg_n = 1'b0;
        pc  <= pc_plus1;
        adb <= pc_plus1[14:0] & RAMW[14:0];
        state = FETCH_REQ;
        fetch_stage = FETCH_OPCODE;
      end
      // LSR zero page
      8'h46: begin
        if (fetched_data_bytes == 0) begin
          adb <= {7'd0, operands[7:0]} & RAMW[14:0];
          state = FETCH_REQ;
          fetch_stage = FETCH_DATA;
          fetch_resume_state <= DECODE_EXECUTE;
        end else begin
          flg_c = dout_r[0];
          din <= dout_r >> 1;
          ada <= {7'd0, operands[7:0]};
          cea   = 1;
          v_cea = 0;
          flg_z = (din == 8'h00);
          flg_n = 1'b0;
          pc  <= pc_plus2;
          adb <= pc_plus2[14:0] & RAMW[14:0];
          state = FETCH_REQ;
          fetch_stage = FETCH_OPCODE;
        end
      end
      // LSR zero page, X
      8'h56: begin
        if (fetched_data_bytes == 0) begin
          automatic logic [7:0] zp_addr = operands[7:0] + rx;
          adb <= {7'd0, zp_addr} & RAMW[14:0];
          state = FETCH_REQ;
          fetch_stage = FETCH_DATA;
          fetch_resume_state <= DECODE_EXECUTE;
        end else begin
          automatic logic [7:0] zp_addr = operands[7:0] + rx;
          flg_c = dout_r[0];
          din <= dout_r >> 1;
          ada <= {7'd0, zp_addr};
          cea   = 1;
          v_cea = 0;
          flg_z = (din == 8'h00);
          flg_n = 1'b0;
          pc  <= pc_plus2;
          adb <= pc_plus2[14:0] & RAMW[14:0];
          state = FETCH_REQ;
          fetch_stage = FETCH_OPCODE;
        end
      end
      // LSR absolute
      8'h4E: begin
        if (fetched_data_bytes == 0) begin
          automatic logic [15:0] addr = operands[15:0] & 16'hFFFF;
          adb <= addr[14:0] & RAMW[14:0];
          state = FETCH_REQ;
          fetch_stage = FETCH_DATA;
          fetch_resume_state <= DECODE_EXECUTE;
        end else begin
          flg_c = dout_r[0];
          din <= dout_r >> 1;
          ada <= operands[14:0] & RAMW[14:0];
          cea   = 1;
          v_cea = 0;
          flg_z = (din == 8'h00);
          flg_n = 1'b0;
          pc  <= pc_plus3;
          adb <= pc_plus3[14:0] & RAMW[14:0];
          state = FETCH_REQ;
          fetch_stage = FETCH_OPCODE;
        end
      end
      // LSR absolute, X
      8'h5E: begin
        if (fetched_data_bytes == 0) begin
          automatic logic [15:0] addr = (operands[15:0] + {8'h00, rx}) & 16'hFFFF;
          adb <= addr[14:0] & RAMW[14:0];
          state = FETCH_REQ;
          fetch_stage = FETCH_DATA;
          fetch_resume_state <= DECODE_EXECUTE;
        end else begin
          automatic logic [15:0] addr = (operands[15:0] + {8'h00, rx}) & 16'hFFFF;
          flg_c = dout_r[0];
          din <= dout_r >> 1;
          ada <= addr[14:0] & RAMW[14:0];
          cea   = 1;
          v_cea = 0;
          flg_z = (din == 8'h00);
          flg_n = 1'b0;
          pc  <= pc_plus3;
          adb <= pc_plus3[14:0] & RAMW[14:0];
          state = FETCH_REQ;
          fetch_stage = FETCH_OPCODE;
        end
      end

      // ROL accumulator
      8'h2A: begin
        automatic logic carry_in = flg_c;
        flg_c = ra[7];
        ra = (ra << 1) | (carry_in ? 8'h01 : 8'h00);
        flg_z = (ra == 8'h00);
        flg_n = ra[7];
        pc  <= pc_plus1;
        adb <= pc_plus1[14:0] & RAMW[14:0];
        state = FETCH_REQ;
        fetch_stage = FETCH_OPCODE;
      end
      // ROL zero page
      8'h26: begin
        if (fetched_data_bytes == 0) begin
          adb <= {7'd0, operands[7:0]} & RAMW[14:0];
          state = FETCH_REQ;
          fetch_stage = FETCH_DATA;
          fetch_resume_state <= DECODE_EXECUTE;
        end else begin
          automatic logic carry_in = flg_c;
          flg_c = dout_r[7];
          din <= (dout_r << 1) | (carry_in ? 8'h01 : 8'h00);
          ada <= {7'd0, operands[7:0]};
          cea   = 1;
          v_cea = 0;
          flg_z = (din == 8'h00);
          flg_n = din[7];
          pc  <= pc_plus2;
          adb <= pc_plus2[14:0] & RAMW[14:0];
          state = FETCH_REQ;
          fetch_stage = FETCH_OPCODE;
        end
      end
      // ROL zero page, X
      8'h36: begin
        if (fetched_data_bytes == 0) begin
          automatic logic [7:0] zp_addr = operands[7:0] + rx;
          adb <= {7'd0, zp_addr} & RAMW[14:0];
          state = FETCH_REQ;
          fetch_stage = FETCH_DATA;
          fetch_resume_state <= DECODE_EXECUTE;
        end else begin
          automatic logic [7:0] zp_addr = operands[7:0] + rx;
          automatic logic carry_in = flg_c;
          flg_c = dout_r[7];
          din <= (dout_r << 1) | (carry_in ? 8'h01 : 8'h00);
          ada <= {7'd0, zp_addr};
          cea   = 1;
          v_cea = 0;
          flg_z = (din == 8'h00);
          flg_n = din[7];
          pc  <= pc_plus2;
          adb <= pc_plus2[14:0] & RAMW[14:0];
          state = FETCH_REQ;
          fetch_stage = FETCH_OPCODE;
        end
      end
      // ROL absolute
      8'h2E: begin
        if (fetched_data_bytes == 0) begin
          automatic logic [15:0] addr = operands[15:0] & 16'hFFFF;
          adb <= addr[14:0] & RAMW[14:0];
          state = FETCH_REQ;
          fetch_stage = FETCH_DATA;
          fetch_resume_state <= DECODE_EXECUTE;
        end else begin
          automatic logic carry_in = flg_c;
          flg_c = dout_r[7];
          din <= (dout_r << 1) | (carry_in ? 8'h01 : 8'h00);
          ada <= operands[14:0] & RAMW[14:0];
          cea   = 1;
          v_cea = 0;
          flg_z = (din == 8'h00);
          flg_n = din[7];
          pc  <= pc_plus3;
          adb <= pc_plus3[14:0] & RAMW[14:0];
          state = FETCH_REQ;
          fetch_stage = FETCH_OPCODE;
        end
      end
      // ROL absolute, X
      8'h3E: begin
        if (fetched_data_bytes == 0) begin
          automatic logic [15:0] addr = (operands[15:0] + {8'h00, rx}) & 16'hFFFF;
          adb <= addr[14:0] & RAMW[14:0];
          state = FETCH_REQ;
          fetch_stage = FETCH_DATA;
          fetch_resume_state <= DECODE_EXECUTE;
        end else begin
          automatic logic [15:0] addr = (operands[15:0] + {8'h00, rx}) & 16'hFFFF;
          automatic logic carry_in = flg_c;
          flg_c = dout_r[7];
          din <= (dout_r << 1) | (carry_in ? 8'h01 : 8'h00);
          ada <= addr[14:0] & RAMW[14:0];
          cea   = 1;
          v_cea = 0;
          flg_z = (din == 8'h00);
          flg_n = din[7];
          pc  <= pc_plus3;
          adb <= pc_plus3[14:0] & RAMW[14:0];
          state = FETCH_REQ;
          fetch_stage = FETCH_OPCODE;
        end
      end

      // ROR accumulator
      8'h6A: begin
        automatic logic carry_in = flg_c;
        flg_c = ra[0];
        ra = (ra >> 1) | (carry_in ? 8'h80 : 8'h00);
        flg_z = (ra == 8'h00);
        flg_n = ra[7];
        pc  <= pc_plus1;
        adb <= pc_plus1[14:0] & RAMW[14:0];
        state = FETCH_REQ;
        fetch_stage = FETCH_OPCODE;
      end
      // ROR zero page
      8'h66: begin
        if (fetched_data_bytes == 0) begin
          adb <= {7'd0, operands[7:0]} & RAMW[14:0];
          state = FETCH_REQ;
          fetch_stage = FETCH_DATA;
          fetch_resume_state <= DECODE_EXECUTE;
        end else begin
          automatic logic carry_in = flg_c;
          flg_c = dout_r[0];
          din <= (dout_r >> 1) | (carry_in ? 8'h80 : 8'h00);
          ada <= {7'd0, operands[7:0]};
          cea   = 1;
          v_cea = 0;
          flg_z = (din == 8'h00);
          flg_n = din[7];
          pc  <= pc_plus2;
          adb <= pc_plus2[14:0] & RAMW[14:0];
          state = FETCH_REQ;
          fetch_stage = FETCH_OPCODE;
        end
      end
      // ROR zero page, X
      8'h76: begin
        if (fetched_data_bytes == 0) begin
          automatic logic [7:0] zp_addr = operands[7:0] + rx;
          adb <= {7'd0, zp_addr} & RAMW[14:0];
          state = FETCH_REQ;
          fetch_stage = FETCH_DATA;
          fetch_resume_state <= DECODE_EXECUTE;
        end else begin
          automatic logic [7:0] zp_addr = operands[7:0] + rx;
          automatic logic carry_in = flg_c;
          flg_c = dout_r[0];
          din <= (dout_r >> 1) | (carry_in ? 8'h80 : 8'h00);
          ada <= {7'd0, zp_addr};
          cea   = 1;
          v_cea = 0;
          flg_z = (din == 8'h00);
          flg_n = din[7];
          pc  <= pc_plus2;
          adb <= pc_plus2[14:0] & RAMW[14:0];
          state = FETCH_REQ;
          fetch_stage = FETCH_OPCODE;
        end
      end
      // ROR absolute
      8'h6E: begin
        if (fetched_data_bytes == 0) begin
          automatic logic [15:0] addr = operands[15:0] & 16'hFFFF;
          adb <= addr[14:0] & RAMW[14:0];
          state = FETCH_REQ;
          fetch_stage = FETCH_DATA;
          fetch_resume_state <= DECODE_EXECUTE;
        end else begin
          automatic logic carry_in = flg_c;
          flg_c = dout_r[0];
          din <= (dout_r >> 1) | (carry_in ? 8'h80 : 8'h00);
          ada <= operands[14:0] & RAMW[14:0];
          cea   = 1;
          v_cea = 0;
          flg_z = (din == 8'h00);
          flg_n = din[7];
          pc  <= pc_plus3;
          adb <= pc_plus3[14:0] & RAMW[14:0];
          state = FETCH_REQ;
          fetch_stage = FETCH_OPCODE;
        end
      end

      default: begin
        handled = 1'b0;
      end
    endcase
  endtask
endpackage
/* verilator lint_on UNUSEDSIGNAL */
