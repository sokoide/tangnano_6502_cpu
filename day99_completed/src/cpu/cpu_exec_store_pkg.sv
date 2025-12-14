// cpu_exec_store_pkg.sv - store instructions
//
// Self-contained implementation of legacy store opcodes present in decode_store.svinc:
// - STA (zp/zpx/abs/absx/absy/(indx)/(indy))
// - STX (zp/zpy/abs)
// - STY (zp/zpx)
//
// Called from the CPU's DECODE_EXECUTE state. Reports whether it handled the opcode.

`include "consts_pkg.sv"

/* verilator lint_off UNUSEDSIGNAL */
package cpu_exec_store_pkg;
  import cpu_pkg::*;
  import consts_pkg::*;

  task automatic do_store_write(input logic [15:0] target_addr, input logic [7:0] data,
                                ref logic [9:0] v_ada, ref logic [7:0] v_din, ref logic [14:0] ada,
                                ref logic [7:0] din, ref logic write_to_vram);
    logic [31:0] target32;
    target32 = {16'd0, target_addr};
    if (target32 >= VRAM_START && target32 < (VRAM_START + (COLUMNS * ROWS))) begin
      logic [31:0] off32;
      logic [31:0] shadow32;
      off32 = target32 - VRAM_START;
      shadow32 = off32 + SHADOW_VRAM_START;
      v_ada <= off32[9:0] & VRAMW[9:0];
      v_din <= data;
      ada   <= shadow32[14:0] & RAMW[14:0];
      din   <= data;
      write_to_vram = 1'b1;
    end else begin
      ada <= target_addr[14:0] & RAMW[14:0];
      din <= data;
      write_to_vram = 1'b0;
    end
  endtask

  task automatic fetch_next_opcode(input logic [1:0] pc_offset, ref logic [15:0] pc,
                                   ref logic [15:0] pc_plus1, ref logic [15:0] pc_plus2,
                                   ref logic [15:0] pc_plus3, ref logic [14:0] adb,
                                   ref cpu_state_e state, ref fetch_stage_e fetch_stage);
    unique case (pc_offset)
      1: begin
        pc  <= pc_plus1;
        adb <= pc_plus1[14:0] & RAMW[14:0];
      end
      2: begin
        pc  <= pc_plus2;
        adb <= pc_plus2[14:0] & RAMW[14:0];
      end
      default: begin
        pc  <= pc_plus3;
        adb <= pc_plus3[14:0] & RAMW[14:0];
      end
    endcase
    state = FETCH_REQ;
    fetch_stage = FETCH_OPCODE;
  endtask

  task automatic exec_store(
      input logic [7:0] opcode, input logic [7:0] ra, input logic [7:0] rx, input logic [7:0] ry,
      ref logic [15:0] operands, ref logic [2:0] fetched_data_bytes, ref logic [15:0] fetched_data,
      input logic [7:0] dout_r, ref logic [9:0] v_ada, ref logic [7:0] v_din, ref logic v_cea,
      ref logic [14:0] ada, ref logic [7:0] din, ref logic cea, ref logic write_to_vram,
      ref logic [15:0] pc, ref logic [15:0] pc_plus1, ref logic [15:0] pc_plus2,
      ref logic [15:0] pc_plus3, ref logic [14:0] adb, ref cpu_state_e state,
      ref fetch_stage_e fetch_stage, ref cpu_state_e fetch_resume_state, output logic handled);
    handled = 1'b1;

    unique case (opcode)
      // STA zero page
      8'h85: begin
        ada <= {7'd0, operands[7:0]};
        din <= ra;
        cea   = 1;
        v_cea = 0;
        fetch_next_opcode(2, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
      end
      // STA zero page, X
      8'h95: begin
        automatic logic [7:0] zp_addr = operands[7:0] + rx;
        ada <= {7'd0, zp_addr};
        din <= ra;
        cea   = 1;
        v_cea = 0;
        fetch_next_opcode(2, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
      end
      // STA absolute
      8'h8D: begin
        automatic logic [15:0] addr = operands[15:0] & 16'hFFFF;
        do_store_write(addr, ra, v_ada, v_din, ada, din, write_to_vram);
        cea   = 1;
        v_cea = write_to_vram;
        fetch_next_opcode(3, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
      end
      // STA absolute, X
      8'h9D: begin
        automatic logic [15:0] addr = (operands[15:0] + {8'h00, rx}) & 16'hFFFF;
        do_store_write(addr, ra, v_ada, v_din, ada, din, write_to_vram);
        cea   = 1;
        v_cea = write_to_vram;
        fetch_next_opcode(3, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
      end
      // STA absolute, Y
      8'h99: begin
        automatic logic [15:0] addr = (operands[15:0] + {8'h00, ry}) & 16'hFFFF;
        do_store_write(addr, ra, v_ada, v_din, ada, din, write_to_vram);
        cea   = 1;
        v_cea = write_to_vram;
        fetch_next_opcode(3, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
      end
      // STA (indirect, X)
      8'h81: begin
        case (fetched_data_bytes)
          0: begin
            automatic logic [7:0] zp_addr = operands[7:0] + rx;
            adb <= {7'd0, zp_addr} & RAMW[14:0];
            state = FETCH_REQ;
            fetch_stage = FETCH_DATA;
            fetch_resume_state <= DECODE_EXECUTE;
          end
          1: begin
            logic [7:0] zp_addr;
            fetched_data[7:0] = dout_r;
            zp_addr = operands[7:0] + rx + 8'h01;
            adb <= {7'd0, zp_addr} & RAMW[14:0];
            state = FETCH_REQ;
            fetch_stage = FETCH_DATA;
            fetch_resume_state <= DECODE_EXECUTE;
          end
          2: begin
            automatic logic [15:0] addr = {dout_r, fetched_data[7:0]} & 16'hFFFF;
            do_store_write(addr, ra, v_ada, v_din, ada, din, write_to_vram);
            cea   = 1;
            v_cea = write_to_vram;
            fetch_next_opcode(2, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
          end
          default: ;
        endcase
      end
      // STA (indirect), Y
      8'h91: begin
        case (fetched_data_bytes)
          0: begin
            adb <= {7'd0, operands[7:0]} & RAMW[14:0];
            state = FETCH_REQ;
            fetch_stage = FETCH_DATA;
            fetch_resume_state <= DECODE_EXECUTE;
          end
          1: begin
            logic [7:0] zp_addr;
            fetched_data[7:0] = dout_r;
            zp_addr = operands[7:0] + 8'h01;
            adb <= {7'd0, zp_addr} & RAMW[14:0];
            state = FETCH_REQ;
            fetch_stage = FETCH_DATA;
            fetch_resume_state <= DECODE_EXECUTE;
          end
          2: begin
            automatic logic [15:0] addr = ({dout_r, fetched_data[7:0]} + {8'h00, ry}) & 16'hFFFF;
            do_store_write(addr, ra, v_ada, v_din, ada, din, write_to_vram);
            cea   = 1;
            v_cea = write_to_vram;
            fetch_next_opcode(2, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
          end
          default: ;
        endcase
      end

      // STX zero page
      8'h86: begin
        ada <= {7'd0, operands[7:0]};
        din <= rx;
        cea   = 1;
        v_cea = 0;
        fetch_next_opcode(2, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
      end
      // STX zero page, Y
      8'h96: begin
        automatic logic [7:0] zp_addr = operands[7:0] + ry;
        ada <= {7'd0, zp_addr};
        din <= rx;
        cea   = 1;
        v_cea = 0;
        fetch_next_opcode(2, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
      end
      // STX absolute
      8'h8E: begin
        automatic logic [15:0] addr = operands[15:0] & 16'hFFFF;
        do_store_write(addr, rx, v_ada, v_din, ada, din, write_to_vram);
        cea   = 1;
        v_cea = write_to_vram;
        fetch_next_opcode(3, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
      end

      // STY zero page
      8'h84: begin
        ada <= {7'd0, operands[7:0]};
        din <= ry;
        cea   = 1;
        v_cea = 0;
        fetch_next_opcode(2, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
      end
      // STY zero page, X
      8'h94: begin
        automatic logic [7:0] zp_addr = operands[7:0] + rx;
        ada <= {7'd0, zp_addr};
        din <= ry;
        cea   = 1;
        v_cea = 0;
        fetch_next_opcode(2, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
      end

      default: begin
        handled = 1'b0;
      end
    endcase
  endtask
endpackage
/* verilator lint_on UNUSEDSIGNAL */
