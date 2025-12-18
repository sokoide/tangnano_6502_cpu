// cpu_exec_load_store_pkg.sv - load instructions
//
// Self-contained implementation of legacy opcodes present in decode_load_store.svinc:
// - LDA (imm/zp/zpx/abs/absx/absy/(indx)/(indy))
// - LDX (imm/zp/zpy/abs/absy)
// - LDY (imm/zp/zpx/abs)
//
// Called from the CPU's DECODE_EXECUTE state. Reports whether it handled the opcode.

`include "consts_pkg.sv"

/* verilator lint_off UNUSEDSIGNAL */
package cpu_exec_load_store_pkg;
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

    task automatic start_fetch_data(input logic [14:0] addr15, ref logic [14:0] adb,
                                    ref cpu_state_e state, ref fetch_stage_e fetch_stage,
                                    ref cpu_state_e fetch_resume_state);
        adb <= addr15 & RAMW[14:0];
        state = FETCH_REQ;
        fetch_stage = FETCH_DATA;
        fetch_resume_state <= DECODE_EXECUTE;
    endtask

    task automatic exec_load_store(
        input logic [7:0] opcode, ref logic [7:0] ra, ref logic [7:0] rx, ref logic [7:0] ry,
        ref logic flg_z, ref logic flg_n, ref logic [15:0] operands,
        ref logic [2:0] fetched_data_bytes, ref logic [15:0] fetched_data, input logic [7:0] dout_r,
        ref logic [15:0] pc, ref logic [15:0] pc_plus1, ref logic [15:0] pc_plus2,
        ref logic [15:0] pc_plus3, ref logic [14:0] adb, ref cpu_state_e state,
        ref fetch_stage_e fetch_stage, ref cpu_state_e fetch_resume_state, output logic handled);
        handled = 1'b1;

        unique case (opcode)
            // LDA immediate
            8'hA9: begin
                ra = operands[7:0];
                flg_z = (ra == 8'h00);
                flg_n = ra[7];
                fetch_next_opcode(2, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
            end
            // LDA zero page
            8'hA5: begin
                if (fetched_data_bytes == 0) begin
                    start_fetch_data({7'd0, operands[7:0]} & RAMW[14:0], adb, state, fetch_stage,
                                     fetch_resume_state);
                end else begin
                    ra = dout_r;
                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];
                    fetch_next_opcode(2, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
                end
            end
            // LDA zero page, X
            8'hB5: begin
                if (fetched_data_bytes == 0) begin
                    automatic logic [7:0] zp_addr = operands[7:0] + rx;
                    start_fetch_data({7'd0, zp_addr} & RAMW[14:0], adb, state, fetch_stage,
                                     fetch_resume_state);
                end else begin
                    ra = dout_r;
                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];
                    fetch_next_opcode(2, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
                end
            end
            // LDA absolute
            8'hAD: begin
                if (fetched_data_bytes == 0) begin
                    start_fetch_data(operands[14:0] & RAMW[14:0], adb, state, fetch_stage,
                                     fetch_resume_state);
                end else begin
                    ra = dout_r;
                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];
                    fetch_next_opcode(3, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
                end
            end
            // LDA absolute, X
            8'hBD: begin
                if (fetched_data_bytes == 0) begin
                    automatic logic [15:0] addr = (operands[15:0] + {8'h00, rx}) & 16'hFFFF;
                    start_fetch_data(addr[14:0] & RAMW[14:0], adb, state, fetch_stage,
                                     fetch_resume_state);
                end else begin
                    ra = dout_r;
                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];
                    fetch_next_opcode(3, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
                end
            end
            // LDA absolute, Y
            8'hB9: begin
                if (fetched_data_bytes == 0) begin
                    automatic logic [15:0] addr = (operands[15:0] + {8'h00, ry}) & 16'hFFFF;
                    start_fetch_data(addr[14:0] & RAMW[14:0], adb, state, fetch_stage,
                                     fetch_resume_state);
                end else begin
                    ra = dout_r;
                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];
                    fetch_next_opcode(3, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
                end
            end
            // LDA (indirect, X)
            8'hA1: begin
                case (fetched_data_bytes)
                    0: begin
                        automatic logic [7:0] zp_addr = operands[7:0] + rx;
                        start_fetch_data({7'd0, zp_addr} & RAMW[14:0], adb, state, fetch_stage,
                                         fetch_resume_state);
                    end
                    1: begin
                        automatic logic [7:0] zp_addr = operands[7:0] + rx + 8'h01;
                        fetched_data[7:0] = dout_r;
                        start_fetch_data({7'd0, zp_addr} & RAMW[14:0], adb, state, fetch_stage,
                                         fetch_resume_state);
                    end
                    2: begin
                        automatic logic [15:0] addr = {dout_r, fetched_data[7:0]} & 16'hFFFF;
                        start_fetch_data(addr[14:0] & RAMW[14:0], adb, state, fetch_stage,
                                         fetch_resume_state);
                    end
                    3: begin
                        ra = dout_r;
                        flg_z = (ra == 8'h00);
                        flg_n = ra[7];
                        fetch_next_opcode(2, pc, pc_plus1, pc_plus2, pc_plus3, adb, state,
                                          fetch_stage);
                    end
                    default: ;
                endcase
            end
            // LDA (indirect), Y
            8'hB1: begin
                case (fetched_data_bytes)
                    0: begin
                        start_fetch_data({7'd0, operands[7:0]} & RAMW[14:0], adb, state,
                                         fetch_stage, fetch_resume_state);
                    end
                    1: begin
                        logic [7:0] zp_addr;
                        fetched_data[7:0] = dout_r;
                        zp_addr = operands[7:0] + 8'h01;
                        start_fetch_data({7'd0, zp_addr} & RAMW[14:0], adb, state, fetch_stage,
                                         fetch_resume_state);
                    end
                    2: begin
                        automatic
                        logic [15:0]
                        addr = ({dout_r, fetched_data[7:0]} + {8'h00, ry}) & 16'hFFFF;
                        start_fetch_data(addr[14:0] & RAMW[14:0], adb, state, fetch_stage,
                                         fetch_resume_state);
                    end
                    3: begin
                        ra = dout_r;
                        flg_z = (ra == 8'h00);
                        flg_n = ra[7];
                        fetch_next_opcode(2, pc, pc_plus1, pc_plus2, pc_plus3, adb, state,
                                          fetch_stage);
                    end
                    default: ;
                endcase
            end

            // LDX immediate
            8'hA2: begin
                rx = operands[7:0];
                flg_z = (rx == 8'h00);
                flg_n = rx[7];
                fetch_next_opcode(2, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
            end
            // LDX zero page
            8'hA6: begin
                if (fetched_data_bytes == 0) begin
                    start_fetch_data({7'd0, operands[7:0]} & RAMW[14:0], adb, state, fetch_stage,
                                     fetch_resume_state);
                end else begin
                    rx = dout_r;
                    flg_z = (rx == 8'h00);
                    flg_n = rx[7];
                    fetch_next_opcode(2, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
                end
            end
            // LDX zero page, Y
            8'hB6: begin
                if (fetched_data_bytes == 0) begin
                    automatic logic [7:0] zp_addr = operands[7:0] + ry;
                    start_fetch_data({7'd0, zp_addr} & RAMW[14:0], adb, state, fetch_stage,
                                     fetch_resume_state);
                end else begin
                    rx = dout_r;
                    flg_z = (rx == 8'h00);
                    flg_n = rx[7];
                    fetch_next_opcode(2, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
                end
            end
            // LDX absolute
            8'hAE: begin
                if (fetched_data_bytes == 0) begin
                    start_fetch_data(operands[14:0] & RAMW[14:0], adb, state, fetch_stage,
                                     fetch_resume_state);
                end else begin
                    rx = dout_r;
                    flg_z = (rx == 8'h00);
                    flg_n = rx[7];
                    fetch_next_opcode(3, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
                end
            end
            // LDX absolute, Y
            8'hBE: begin
                if (fetched_data_bytes == 0) begin
                    automatic logic [15:0] addr = (operands[15:0] + {8'h00, ry}) & 16'hFFFF;
                    start_fetch_data(addr[14:0] & RAMW[14:0], adb, state, fetch_stage,
                                     fetch_resume_state);
                end else begin
                    rx = dout_r;
                    flg_z = (rx == 8'h00);
                    flg_n = rx[7];
                    fetch_next_opcode(3, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
                end
            end

            // LDY immediate
            8'hA0: begin
                ry = operands[7:0];
                flg_z = (ry == 8'h00);
                flg_n = ry[7];
                fetch_next_opcode(2, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
            end
            // LDY zero page
            8'hA4: begin
                if (fetched_data_bytes == 0) begin
                    start_fetch_data({7'd0, operands[7:0]} & RAMW[14:0], adb, state, fetch_stage,
                                     fetch_resume_state);
                end else begin
                    ry = dout_r;
                    flg_z = (ry == 8'h00);
                    flg_n = ry[7];
                    fetch_next_opcode(2, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
                end
            end
            // LDY zero page, X
            8'hB4: begin
                if (fetched_data_bytes == 0) begin
                    automatic logic [7:0] zp_addr = operands[7:0] + rx;
                    start_fetch_data({7'd0, zp_addr} & RAMW[14:0], adb, state, fetch_stage,
                                     fetch_resume_state);
                end else begin
                    ry = dout_r;
                    flg_z = (ry == 8'h00);
                    flg_n = ry[7];
                    fetch_next_opcode(2, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
                end
            end
            // LDY absolute
            8'hAC: begin
                if (fetched_data_bytes == 0) begin
                    start_fetch_data(operands[14:0] & RAMW[14:0], adb, state, fetch_stage,
                                     fetch_resume_state);
                end else begin
                    ry = dout_r;
                    flg_z = (ry == 8'h00);
                    flg_n = ry[7];
                    fetch_next_opcode(3, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
                end
            end

            default: begin
                handled = 1'b0;
            end
        endcase
    endtask
endpackage
/* verilator lint_on UNUSEDSIGNAL */
