// cpu_exec_transfers_pkg.sv - register transfer instructions
//
// This package holds a self-contained, formatter-friendly implementation of
// transfer opcodes (TAX/TAY/TXA/TYA/TSX/...). It is called from the CPU's
// DECODE_EXECUTE state and reports whether it handled the current opcode.

`include "consts_pkg.sv"

package cpu_exec_transfers_pkg;
    import cpu_pkg::*;
    import consts_pkg::*;

    task automatic exec_transfers(input logic [7:0] opcode, ref logic [7:0] ra, ref logic [7:0] rx,
                                  ref logic [7:0] ry, ref logic [7:0] sp, ref logic flg_z,
                                  ref logic flg_n, ref logic [15:0] pc, ref logic [15:0] pc_plus1,
                                  ref logic [14:0] adb, ref cpu_state_e state,
                                  ref fetch_stage_e fetch_stage, output logic handled);
        handled = 1'b1;
        unique case (opcode)
            // TAX
            8'hAA: begin
                rx = ra;
                flg_z = (rx == 8'h00);
                flg_n = rx[7];
            end
            // TAY
            8'hA8: begin
                ry = ra;
                flg_z = (ry == 8'h00);
                flg_n = ry[7];
            end
            // TXA
            8'h8A: begin
                ra = rx;
                flg_z = (ra == 8'h00);
                flg_n = ra[7];
            end
            // TYA
            8'h98: begin
                ra = ry;
                flg_z = (ra == 8'h00);
                flg_n = ra[7];
            end
            // TSX
            8'hBA: begin
                rx = sp;
                flg_z = (rx == 8'h00);
                flg_n = rx[7];
            end
            // TXS (does not affect flags)
            8'h9A: begin
                sp = rx;
            end
            default: begin
                handled = 1'b0;
            end
        endcase

        if (handled) begin
            // Equivalent of fetch_opcode(1'b1).
            pc  <= pc_plus1;
            adb <= pc_plus1[14:0] & RAMW[14:0];
            state = FETCH_REQ;
            fetch_stage = FETCH_OPCODE;
        end
    endtask
endpackage
