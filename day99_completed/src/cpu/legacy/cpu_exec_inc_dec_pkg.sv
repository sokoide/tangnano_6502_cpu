// cpu_exec_inc_dec_pkg.sv - INC/DEC and index inc/dec
//
// Self-contained implementation of legacy opcodes present in decode_inc_dec.svinc:
// - INC (zp/zpx/abs/absx)
// - DEC (zp/zpx/abs/absx)
// - INX/INY/DEX
//
// Called from the CPU's DECODE_EXECUTE state. Reports whether it handled the opcode.

`include "consts_pkg.sv"

/* verilator lint_off UNUSEDSIGNAL */
package cpu_exec_inc_dec_pkg;
    import cpu_pkg::*;
    import consts_pkg::*;

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

    task automatic exec_inc_dec(
        input logic [7:0] opcode, ref logic [7:0] rx, ref logic [7:0] ry, ref logic flg_z,
        ref logic flg_n, ref logic [15:0] operands, ref logic [2:0] fetched_data_bytes,
        input logic [7:0] dout_r, ref logic [14:0] adb, ref logic [14:0] ada, ref logic [7:0] din,
        ref logic cea, ref logic v_cea, ref logic [15:0] pc, ref logic [15:0] pc_plus1,
        ref logic [15:0] pc_plus2, ref logic [15:0] pc_plus3, ref cpu_state_e state,
        ref fetch_stage_e fetch_stage, ref cpu_state_e fetch_resume_state, output logic handled);
        handled = 1'b1;

        unique case (opcode)
            // INC zero page
            8'hE6: begin
                if (fetched_data_bytes == 0) begin
                    adb <= {7'd0, operands[7:0]} & RAMW[14:0];
                    state = FETCH_REQ;
                    fetch_stage = FETCH_DATA;
                    fetch_resume_state <= DECODE_EXECUTE;
                end else begin
                    automatic logic [7:0] result = dout_r + 1'b1;
                    ada <= {7'd0, operands[7:0]};
                    din <= result;
                    cea   = 1;
                    v_cea = 0;
                    flg_z = (result == 8'h00);
                    flg_n = result[7];
                    fetch_next_opcode(2, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
                end
            end
            // INC zero page, X
            8'hF6: begin
                if (fetched_data_bytes == 0) begin
                    automatic logic [7:0] zp_addr = operands[7:0] + rx;
                    adb <= {7'd0, zp_addr} & RAMW[14:0];
                    state = FETCH_REQ;
                    fetch_stage = FETCH_DATA;
                    fetch_resume_state <= DECODE_EXECUTE;
                end else begin
                    automatic logic [7:0] result = dout_r + 1'b1;
                    ada <= {7'd0, operands[7:0]};  // Keep original address (legacy behavior)
                    din <= result;
                    cea   = 1;
                    v_cea = 0;
                    flg_z = (result == 8'h00);
                    flg_n = result[7];
                    fetch_next_opcode(2, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
                end
            end
            // INC absolute
            8'hEE: begin
                if (fetched_data_bytes == 0) begin
                    adb <= operands[14:0] & RAMW[14:0];
                    state = FETCH_REQ;
                    fetch_stage = FETCH_DATA;
                    fetch_resume_state <= DECODE_EXECUTE;
                end else begin
                    automatic logic [7:0] result = dout_r + 1'b1;
                    ada <= operands[14:0] & RAMW[14:0];
                    din <= result;
                    cea   = 1;
                    v_cea = 0;
                    flg_z = (result == 8'h00);
                    flg_n = result[7];
                    fetch_next_opcode(3, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
                end
            end
            // INC absolute, X
            8'hFE: begin
                if (fetched_data_bytes == 0) begin
                    automatic logic [15:0] addr = operands[15:0] + {8'h00, rx};
                    adb <= addr[14:0] & RAMW[14:0];
                    state = FETCH_REQ;
                    fetch_stage = FETCH_DATA;
                    fetch_resume_state <= DECODE_EXECUTE;
                end else begin
                    automatic logic [7:0] result = dout_r + 1'b1;
                    ada <= operands[14:0] & RAMW[14:0];  // Keep original address (legacy behavior)
                    din <= result;
                    cea   = 1;
                    v_cea = 0;
                    flg_z = (result == 8'h00);
                    flg_n = result[7];
                    fetch_next_opcode(3, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
                end
            end

            // INX
            8'hE8: begin
                rx = (rx + 1'b1) & 8'hFF;
                flg_z = (rx == 8'h00);
                flg_n = rx[7];
                fetch_next_opcode(1, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
            end
            // INY
            8'hC8: begin
                ry = (ry + 1'b1) & 8'hFF;
                flg_z = (ry == 8'h00);
                flg_n = ry[7];
                fetch_next_opcode(1, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
            end

            // DEC zero page
            8'hC6: begin
                if (fetched_data_bytes == 0) begin
                    adb <= {7'd0, operands[7:0]} & RAMW[14:0];
                    state = FETCH_REQ;
                    fetch_stage = FETCH_DATA;
                    fetch_resume_state <= DECODE_EXECUTE;
                end else begin
                    automatic logic [7:0] result = dout_r - 1'b1;
                    ada <= {7'd0, operands[7:0]};
                    din <= result;
                    cea   = 1;
                    v_cea = 0;
                    flg_z = (result == 8'h00) ? 1'd1 : 1'd0;
                    flg_n = result[7];
                    fetch_next_opcode(2, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
                end
            end
            // DEC zero page, X
            8'hD6: begin
                if (fetched_data_bytes == 0) begin
                    automatic logic [7:0] zp_addr = operands[7:0] + rx;
                    adb <= {7'd0, zp_addr} & RAMW[14:0];
                    state = FETCH_REQ;
                    fetch_stage = FETCH_DATA;
                    fetch_resume_state <= DECODE_EXECUTE;
                end else begin
                    automatic logic [7:0] result = dout_r - 1'b1;
                    ada <= {7'd0, (operands[7:0] + rx) & 8'hFF};
                    din <= result;
                    cea   = 1;
                    v_cea = 0;
                    flg_z = (result == 8'h00) ? 1'd1 : 1'd0;
                    flg_n = result[7];
                    fetch_next_opcode(2, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
                end
            end
            // DEC absolute
            8'hCE: begin
                if (fetched_data_bytes == 0) begin
                    adb <= operands[14:0] & RAMW[14:0];
                    state = FETCH_REQ;
                    fetch_stage = FETCH_DATA;
                    fetch_resume_state <= DECODE_EXECUTE;
                end else begin
                    automatic logic [7:0] result = dout_r - 1'b1;
                    ada <= operands[14:0] & RAMW[14:0];
                    din <= result;
                    cea   = 1;
                    v_cea = 0;
                    flg_z = (result == 8'h00) ? 1'd1 : 1'd0;
                    flg_n = result[7];
                    fetch_next_opcode(3, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
                end
            end
            // DEC absolute, X
            8'hDE: begin
                if (fetched_data_bytes == 0) begin
                    automatic logic [15:0] addr = operands[15:0] + {8'h00, rx};
                    adb <= addr[14:0] & RAMW[14:0];
                    state = FETCH_REQ;
                    fetch_stage = FETCH_DATA;
                    fetch_resume_state <= DECODE_EXECUTE;
                end else begin
                    automatic logic [ 7:0] result = dout_r - 1'b1;
                    automatic logic [15:0] addr = operands[15:0] + {8'h00, rx};
                    ada <= addr[14:0] & RAMW[14:0];
                    din <= result;
                    cea   = 1;
                    v_cea = 0;
                    flg_z = (result == 8'h00) ? 1'd1 : 1'd0;
                    flg_n = result[7];
                    fetch_next_opcode(3, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
                end
            end

            // DEX
            8'hCA: begin
                rx = (rx - 1'b1) & 8'hFF;
                flg_z = (rx == 8'h00);
                flg_n = rx[7];
                fetch_next_opcode(1, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
            end

            default: begin
                handled = 1'b0;
            end
        endcase
    endtask
endpackage
/* verilator lint_on UNUSEDSIGNAL */
