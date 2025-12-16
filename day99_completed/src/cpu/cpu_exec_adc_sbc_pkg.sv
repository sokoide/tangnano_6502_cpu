// cpu_exec_adc_sbc_pkg.sv - ADC/SBC instructions
//
// Self-contained implementation of legacy opcodes present in decode_adc_sbc.svinc:
// - ADC (imm/zp/zpx/abs/absx/absy/(indx)/(indy))
// - SBC (imm/zp/zpx/abs/absx/absy/(indx))
//
// Called from the CPU's DECODE_EXECUTE state. Reports whether it handled the opcode.

`include "consts_pkg.sv"

/* verilator lint_off UNUSEDSIGNAL */
package cpu_exec_adc_sbc_pkg;
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

    task automatic exec_adc_sbc(
        input logic [7:0] opcode, ref logic [7:0] ra, input logic [7:0] rx, input logic [7:0] ry,
        ref logic flg_c, ref logic flg_v, ref logic flg_z, ref logic flg_n,
        ref logic [15:0] operands, ref logic [2:0] fetched_data_bytes,
        ref logic [15:0] fetched_data, input logic [7:0] dout_r, ref logic [15:0] pc,
        ref logic [15:0] pc_plus1, ref logic [15:0] pc_plus2, ref logic [15:0] pc_plus3,
        ref logic [14:0] adb, ref cpu_state_e state, ref fetch_stage_e fetch_stage,
        ref cpu_state_e fetch_resume_state, output logic handled);
        handled = 1'b1;

        unique case (opcode)
            // ADC immediate
            8'h69: begin
                automatic logic [8:0] temp;
                temp = (ra + dout_r + (flg_c ? 1 : 0)) & 9'h1FF;
                flg_c = temp[8];
                flg_v = (~(ra[7] ^ dout_r[7]) & (ra[7] ^ temp[7])) ? 1 : 0;
                ra = temp[7:0];
                flg_z = (ra == 8'h00);
                flg_n = ra[7];
                fetch_next_opcode(2, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
            end
            // ADC zero page
            8'h65: begin
                if (fetched_data_bytes == 0) begin
                    start_fetch_data({7'd0, operands[7:0]} & RAMW[14:0], adb, state, fetch_stage,
                                     fetch_resume_state);
                end else begin
                    automatic logic [8:0] temp;
                    temp = (ra + dout_r + (flg_c ? 1 : 0)) & 9'h1FF;
                    flg_c = temp[8];
                    flg_v = (~(ra[7] ^ dout_r[7]) & (ra[7] ^ temp[7])) ? 1 : 0;
                    ra = temp[7:0];
                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];
                    fetch_next_opcode(2, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
                end
            end
            // ADC zero page, X
            8'h75: begin
                if (fetched_data_bytes == 0) begin
                    automatic logic [7:0] zp_addr = operands[7:0] + rx;
                    start_fetch_data({7'd0, zp_addr} & RAMW[14:0], adb, state, fetch_stage,
                                     fetch_resume_state);
                end else begin
                    automatic logic [8:0] temp;
                    temp = (ra + dout_r + (flg_c ? 1 : 0)) & 9'h1FF;
                    flg_c = temp[8];
                    flg_v = (~(ra[7] ^ dout_r[7]) & (ra[7] ^ temp[7])) ? 1 : 0;
                    ra = temp[7:0];
                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];
                    fetch_next_opcode(2, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
                end
            end
            // ADC absolute
            8'h6D: begin
                if (fetched_data_bytes == 0) begin
                    start_fetch_data(operands[14:0] & RAMW[14:0], adb, state, fetch_stage,
                                     fetch_resume_state);
                end else begin
                    automatic logic [8:0] temp;
                    temp = (ra + dout_r + (flg_c ? 1 : 0)) & 9'h1FF;
                    flg_c = temp[8];
                    flg_v = (~(ra[7] ^ dout_r[7]) & (ra[7] ^ temp[7])) ? 1 : 0;
                    ra = temp[7:0];
                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];
                    fetch_next_opcode(3, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
                end
            end
            // ADC absolute, X
            8'h7D: begin
                if (fetched_data_bytes == 0) begin
                    automatic logic [15:0] addr = (operands[15:0] + {8'h00, rx}) & RAMW[15:0];
                    start_fetch_data(addr[14:0] & RAMW[14:0], adb, state, fetch_stage,
                                     fetch_resume_state);
                end else begin
                    automatic logic [8:0] temp;
                    temp = (ra + dout_r + (flg_c ? 1 : 0)) & 9'h1FF;
                    flg_c = temp[8];
                    flg_v = (~(ra[7] ^ dout_r[7]) & (ra[7] ^ temp[7])) ? 1 : 0;
                    ra = temp[7:0];
                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];
                    fetch_next_opcode(3, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
                end
            end
            // ADC absolute, Y
            8'h79: begin
                if (fetched_data_bytes == 0) begin
                    automatic logic [15:0] addr = (operands[15:0] + {8'h00, ry}) & RAMW[15:0];
                    start_fetch_data(addr[14:0] & RAMW[14:0], adb, state, fetch_stage,
                                     fetch_resume_state);
                end else begin
                    automatic logic [8:0] temp;
                    temp = (ra + dout_r + (flg_c ? 1 : 0)) & 9'h1FF;
                    flg_c = temp[8];
                    flg_v = (~(ra[7] ^ dout_r[7]) & (ra[7] ^ temp[7])) ? 1 : 0;
                    ra = temp[7:0];
                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];
                    fetch_next_opcode(3, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
                end
            end
            // ADC (indirect, X)
            8'h61: begin
                case (fetched_data_bytes)
                    0: begin
                        automatic logic [7:0] zp_addr = operands[7:0] + rx;
                        start_fetch_data({7'd0, zp_addr} & RAMW[14:0], adb, state, fetch_stage,
                                         fetch_resume_state);
                    end
                    1: begin
                        logic [7:0] zp_addr;
                        fetched_data[7:0] = dout_r;
                        zp_addr = operands[7:0] + rx + 8'h01;
                        start_fetch_data({7'd0, zp_addr} & RAMW[14:0], adb, state, fetch_stage,
                                         fetch_resume_state);
                    end
                    2: begin
                        automatic logic [15:0] addr = {dout_r, fetched_data[7:0]} & 16'hFFFF;
                        start_fetch_data(addr[14:0] & RAMW[14:0], adb, state, fetch_stage,
                                         fetch_resume_state);
                    end
                    3: begin
                        automatic logic [8:0] temp;
                        temp = (ra + dout_r + (flg_c ? 1 : 0)) & 9'h1FF;
                        flg_c = temp[8];
                        flg_v = (~(ra[7] ^ dout_r[7]) & (ra[7] ^ temp[7])) ? 1 : 0;
                        ra = temp[7:0];
                        flg_z = (ra == 8'h00);
                        flg_n = ra[7];
                        fetch_next_opcode(2, pc, pc_plus1, pc_plus2, pc_plus3, adb, state,
                                          fetch_stage);
                    end
                    default: ;
                endcase
            end
            // ADC (indirect), Y
            8'h71: begin
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
                        automatic logic [8:0] temp;
                        temp = (ra + dout_r + (flg_c ? 1 : 0)) & 9'h1FF;
                        flg_c = temp[8];
                        flg_v = (~(ra[7] ^ dout_r[7]) & (ra[7] ^ temp[7])) ? 1 : 0;
                        ra = temp[7:0];
                        flg_z = (ra == 8'h00);
                        flg_n = ra[7];
                        fetch_next_opcode(2, pc, pc_plus1, pc_plus2, pc_plus3, adb, state,
                                          fetch_stage);
                    end
                    default: ;
                endcase
            end

            // SBC immediate
            8'hE9: begin
                automatic logic [8:0] temp;
                temp = (ra - dout_r - (flg_c ? 0 : 1)) & 9'h1FF;
                flg_c = ~temp[8];
                flg_v = ((ra[7] ^ dout_r[7]) & (ra[7] ^ temp[7])) ? 1 : 0;
                ra = temp[7:0];
                flg_z = (ra == 8'h00);
                flg_n = ra[7];
                fetch_next_opcode(2, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
            end
            // SBC zero page
            8'hE5: begin
                if (fetched_data_bytes == 0) begin
                    start_fetch_data({7'd0, operands[7:0]} & RAMW[14:0], adb, state, fetch_stage,
                                     fetch_resume_state);
                end else begin
                    automatic logic [8:0] temp;
                    temp = (ra - dout_r - (flg_c ? 0 : 1)) & 9'h1FF;
                    flg_c = ~temp[8];
                    flg_v = ((ra[7] ^ dout_r[7]) & (ra[7] ^ temp[7])) ? 1 : 0;
                    ra = temp[7:0];
                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];
                    fetch_next_opcode(2, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
                end
            end
            // SBC zero page, X
            8'hF5: begin
                if (fetched_data_bytes == 0) begin
                    automatic logic [7:0] zp_addr = operands[7:0] + rx;
                    start_fetch_data({7'd0, zp_addr} & RAMW[14:0], adb, state, fetch_stage,
                                     fetch_resume_state);
                end else begin
                    automatic logic [8:0] temp;
                    temp = (ra - dout_r - (flg_c ? 0 : 1)) & 9'h1FF;
                    flg_c = ~temp[8];
                    flg_v = ((ra[7] ^ dout_r[7]) & (ra[7] ^ temp[7])) ? 1 : 0;
                    ra = temp[7:0];
                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];
                    fetch_next_opcode(2, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
                end
            end
            // SBC absolute
            8'hED: begin
                if (fetched_data_bytes == 0) begin
                    start_fetch_data(operands[14:0] & RAMW[14:0], adb, state, fetch_stage,
                                     fetch_resume_state);
                end else begin
                    automatic logic [8:0] temp;
                    temp = (ra - dout_r - (flg_c ? 0 : 1)) & 9'h1FF;
                    flg_c = ~temp[8];
                    flg_v = ((ra[7] ^ dout_r[7]) & (ra[7] ^ temp[7])) ? 1 : 0;
                    ra = temp[7:0];
                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];
                    fetch_next_opcode(3, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
                end
            end
            // SBC absolute, X
            8'hFD: begin
                if (fetched_data_bytes == 0) begin
                    automatic logic [15:0] addr = (operands[15:0] + {8'h00, rx}) & RAMW[15:0];
                    start_fetch_data(addr[14:0] & RAMW[14:0], adb, state, fetch_stage,
                                     fetch_resume_state);
                end else begin
                    automatic logic [8:0] temp;
                    temp = (ra - dout_r - (flg_c ? 0 : 1)) & 9'h1FF;
                    flg_c = ~temp[8];
                    flg_v = ((ra[7] ^ dout_r[7]) & (ra[7] ^ temp[7])) ? 1 : 0;
                    ra = temp[7:0];
                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];
                    fetch_next_opcode(3, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
                end
            end
            // SBC absolute, Y
            8'hF9: begin
                if (fetched_data_bytes == 0) begin
                    automatic logic [15:0] addr = (operands[15:0] + {8'h00, ry}) & RAMW[15:0];
                    start_fetch_data(addr[14:0] & RAMW[14:0], adb, state, fetch_stage,
                                     fetch_resume_state);
                end else begin
                    automatic logic [8:0] temp;
                    temp = (ra - dout_r - (flg_c ? 0 : 1)) & 9'h1FF;
                    flg_c = ~temp[8];
                    flg_v = ((ra[7] ^ dout_r[7]) & (ra[7] ^ temp[7])) ? 1 : 0;
                    ra = temp[7:0];
                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];
                    fetch_next_opcode(3, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
                end
            end
            // SBC (indirect, X)
            8'hE1: begin
                case (fetched_data_bytes)
                    0: begin
                        automatic logic [7:0] zp_addr = operands[7:0] + rx;
                        start_fetch_data({7'd0, zp_addr} & RAMW[14:0], adb, state, fetch_stage,
                                         fetch_resume_state);
                    end
                    1: begin
                        logic [7:0] zp_addr;
                        fetched_data[7:0] = dout_r;
                        zp_addr = operands[7:0] + rx + 8'h01;
                        start_fetch_data({7'd0, zp_addr} & RAMW[14:0], adb, state, fetch_stage,
                                         fetch_resume_state);
                    end
                    2: begin
                        automatic logic [15:0] addr = {dout_r, fetched_data[7:0]} & 16'hFFFF;
                        start_fetch_data(addr[14:0] & RAMW[14:0], adb, state, fetch_stage,
                                         fetch_resume_state);
                    end
                    3: begin
                        automatic logic [8:0] temp;
                        temp = (ra - dout_r - (flg_c ? 0 : 1)) & 9'h1FF;
                        flg_c = ~temp[8];
                        flg_v = ((ra[7] ^ dout_r[7]) & (ra[7] ^ temp[7])) ? 1 : 0;
                        ra = temp[7:0];
                        flg_z = (ra == 8'h00);
                        flg_n = ra[7];
                        fetch_next_opcode(2, pc, pc_plus1, pc_plus2, pc_plus3, adb, state,
                                          fetch_stage);
                    end
                    default: ;
                endcase
            end

            default: begin
                handled = 1'b0;
            end
        endcase
    endtask
endpackage
/* verilator lint_on UNUSEDSIGNAL */
