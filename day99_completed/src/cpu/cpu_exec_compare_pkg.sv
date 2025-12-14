// cpu_exec_compare_pkg.sv - compare/bit instructions
//
// Self-contained implementation of:
// - CMP/CPX/CPY (subset present in legacy decode_compare.svinc)
// - BIT (zp/abs)
//
// Called from the CPU's DECODE_EXECUTE state. Reports whether it handled the opcode.

`include "consts_pkg.sv"

/* verilator lint_off UNUSEDSIGNAL */
package cpu_exec_compare_pkg;
    import cpu_pkg::*;
    import consts_pkg::*;

    task automatic exec_compare(
        input logic [7:0] opcode, ref logic [7:0] ra, ref logic [7:0] rx, ref logic [7:0] ry,
        ref logic flg_c, ref logic flg_z, ref logic flg_v, ref logic flg_n,
        ref logic [15:0] operands, ref logic [2:0] fetched_data_bytes,
        ref logic [15:0] fetched_data, input logic [7:0] dout_r, ref logic [15:0] pc,
        ref logic [15:0] pc_plus2, ref logic [15:0] pc_plus3, ref logic [14:0] adb,
        ref cpu_state_e state, ref fetch_stage_e fetch_stage, ref cpu_state_e next_state,
        output logic handled);
        handled = 1'b1;

        unique case (opcode)
            // CMP immediate
            8'hC9: begin
                automatic logic [7:0] result = ra - operands[7:0];
                flg_c = (ra >= operands[7:0]) ? 1 : 0;
                flg_z = (result == 8'h00);
                flg_n = result[7];
                pc <= pc_plus2;
                adb <= pc_plus2[14:0] & RAMW[14:0];
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
            end

            // BIT zero page
            8'h24: begin
                if (fetched_data_bytes == 0) begin
                    adb <= {7'd0, operands[7:0]} & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                end else begin
                    flg_z = ((ra & dout_r) == 8'h00);
                    flg_n = dout_r[7];
                    flg_v = dout_r[6];
                    pc <= pc_plus2;
                    adb <= pc_plus2[14:0] & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_OPCODE;
                end
            end

            // BIT absolute
            8'h2C: begin
                if (fetched_data_bytes == 0) begin
                    automatic logic [15:0] addr = operands[15:0] & 16'hFFFF;
                    adb <= addr[14:0] & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                end else begin
                    flg_z = ((ra & dout_r) == 8'h00);
                    flg_n = dout_r[7];
                    flg_v = dout_r[6];
                    pc <= pc_plus3;
                    adb <= pc_plus3[14:0] & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_OPCODE;
                end
            end

            // CMP zero page
            8'hC5: begin
                if (fetched_data_bytes == 0) begin
                    adb <= {7'd0, operands[7:0]} & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                end else begin
                    automatic logic [7:0] result = ra - dout_r;
                    flg_c = (ra >= dout_r) ? 1 : 0;
                    flg_z = (result == 8'h00);
                    flg_n = result[7];
                    pc <= pc_plus2;
                    adb <= pc_plus2[14:0] & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_OPCODE;
                end
            end

            // CMP zero page, X
            8'hD5: begin
                if (fetched_data_bytes == 0) begin
                    automatic logic [7:0] zp_addr = operands[7:0] + rx;
                    adb <= {7'd0, zp_addr} & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                end else begin
                    automatic logic [7:0] result = ra - dout_r;
                    flg_c = (ra >= dout_r) ? 1 : 0;
                    flg_z = (result == 8'h00);
                    flg_n = result[7];
                    pc <= pc_plus2;
                    adb <= pc_plus2[14:0] & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_OPCODE;
                end
            end

            // CMP absolute
            8'hCD: begin
                if (fetched_data_bytes == 0) begin
                    automatic logic [15:0] addr = operands[15:0] & 16'hFFFF;
                    adb <= addr[14:0] & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                end else begin
                    automatic logic [7:0] result = ra - dout_r;
                    flg_c = (ra >= dout_r) ? 1 : 0;
                    flg_z = (result == 8'h00);
                    flg_n = result[7];
                    pc <= pc_plus3;
                    adb <= pc_plus3[14:0] & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_OPCODE;
                end
            end

            // CMP absolute, X
            8'hDD: begin
                if (fetched_data_bytes == 0) begin
                    automatic logic [15:0] addr = (operands[15:0] + {8'h00, rx}) & 16'hFFFF;
                    adb <= addr[14:0] & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                end else begin
                    automatic logic [7:0] result = ra - dout_r;
                    flg_c = (ra >= dout_r) ? 1 : 0;
                    flg_z = (result == 8'h00);
                    flg_n = result[7];
                    pc <= pc_plus3;
                    adb <= pc_plus3[14:0] & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_OPCODE;
                end
            end

            // CMP absolute, Y
            8'hD9: begin
                if (fetched_data_bytes == 0) begin
                    automatic logic [15:0] addr = (operands[15:0] + {8'h00, ry}) & 16'hFFFF;
                    adb <= addr[14:0] & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                end else begin
                    automatic logic [7:0] result = ra - dout_r;
                    flg_c = (ra >= dout_r) ? 1 : 0;
                    flg_z = (result == 8'h00);
                    flg_n = result[7];
                    pc <= pc_plus3;
                    adb <= pc_plus3[14:0] & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_OPCODE;
                end
            end

            // CMP (indirect, X)
            8'hC1: begin
                case (fetched_data_bytes)
                    0: begin
                        automatic logic [7:0] zp_addr = operands[7:0] + rx;
                        adb <= {7'd0, zp_addr} & RAMW[14:0];
                        state <= FETCH_REQ;
                        fetch_stage <= FETCH_DATA;
                        next_state <= DECODE_EXECUTE;
                    end
                    1: begin
                        logic [7:0] zp_addr;
                        fetched_data[7:0] = dout_r;
                        zp_addr = operands[7:0] + rx + 8'h01;
                        adb <= {7'd0, zp_addr} & RAMW[14:0];
                        state <= FETCH_REQ;
                        fetch_stage <= FETCH_DATA;
                        next_state <= DECODE_EXECUTE;
                    end
                    2: begin
                        automatic logic [15:0] addr = {dout_r, fetched_data[7:0]} & 16'hFFFF;
                        adb <= addr[14:0] & RAMW[14:0];
                        state <= FETCH_REQ;
                        fetch_stage <= FETCH_DATA;
                        next_state <= DECODE_EXECUTE;
                    end
                    3: begin
                        automatic logic [7:0] result = ra - dout_r;
                        flg_c = (ra >= dout_r) ? 1 : 0;
                        flg_z = (result == 8'h00);
                        flg_n = result[7];
                        pc <= pc_plus2;
                        adb <= pc_plus2[14:0] & RAMW[14:0];
                        state <= FETCH_REQ;
                        fetch_stage <= FETCH_OPCODE;
                    end
                    default: ;
                endcase
            end

            // CMP (indirect), Y
            8'hD1: begin
                case (fetched_data_bytes)
                    0: begin
                        adb <= {7'd0, operands[7:0]} & RAMW[14:0];
                        state <= FETCH_REQ;
                        fetch_stage <= FETCH_DATA;
                        next_state <= DECODE_EXECUTE;
                    end
                    1: begin
                        logic [7:0] zp_addr;
                        fetched_data[7:0] = dout_r;
                        zp_addr = operands[7:0] + 8'h01;
                        adb <= {7'd0, zp_addr} & RAMW[14:0];
                        state <= FETCH_REQ;
                        fetch_stage <= FETCH_DATA;
                        next_state <= DECODE_EXECUTE;
                    end
                    2: begin
                        automatic
                        logic [15:0]
                        addr = ({dout_r, fetched_data[7:0]} + {8'h00, ry}) & 16'hFFFF;
                        adb <= addr[14:0] & RAMW[14:0];
                        state <= FETCH_REQ;
                        fetch_stage <= FETCH_DATA;
                        next_state <= DECODE_EXECUTE;
                    end
                    3: begin
                        automatic logic [7:0] result = ra - dout_r;
                        flg_c = (ra >= dout_r) ? 1 : 0;
                        flg_z = (result == 8'h00);
                        flg_n = result[7];
                        pc <= pc_plus2;
                        adb <= pc_plus2[14:0] & RAMW[14:0];
                        state <= FETCH_REQ;
                        fetch_stage <= FETCH_OPCODE;
                    end
                    default: ;
                endcase
            end

            // CPX immediate
            8'hE0: begin
                automatic logic [7:0] result = rx - operands[7:0];
                flg_c = (rx >= operands[7:0]) ? 1 : 0;
                flg_z = (result == 8'h00);
                flg_n = result[7];
                pc <= pc_plus2;
                adb <= pc_plus2[14:0] & RAMW[14:0];
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
            end

            // CPX zero page
            8'hE4: begin
                if (fetched_data_bytes == 0) begin
                    adb <= {7'd0, operands[7:0]} & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                end else begin
                    automatic logic [7:0] result = rx - dout_r;
                    flg_c = (rx >= dout_r) ? 1 : 0;
                    flg_z = (result == 8'h00);
                    flg_n = result[7];
                    pc <= pc_plus2;
                    adb <= pc_plus2[14:0] & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_OPCODE;
                end
            end

            // CPX absolute
            8'hEC: begin
                if (fetched_data_bytes == 0) begin
                    automatic logic [15:0] addr = operands[15:0] & 16'hFFFF;
                    adb <= addr[14:0] & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                end else begin
                    automatic logic [7:0] result = rx - dout_r;
                    flg_c = (rx >= dout_r) ? 1 : 0;
                    flg_z = (result == 8'h00);
                    flg_n = result[7];
                    pc <= pc_plus3;
                    adb <= pc_plus3[14:0] & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_OPCODE;
                end
            end

            // CPY immediate
            8'hC0: begin
                automatic logic [7:0] result = ry - operands[7:0];
                flg_c = (ry >= operands[7:0]) ? 1 : 0;
                flg_z = (result == 8'h00);
                flg_n = result[7];
                pc <= pc_plus2;
                adb <= pc_plus2[14:0] & RAMW[14:0];
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
            end

            // CPY zero page
            8'hC4: begin
                if (fetched_data_bytes == 0) begin
                    adb <= {7'd0, operands[7:0]} & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                end else begin
                    automatic logic [7:0] result = ry - dout_r;
                    flg_c = (ry >= dout_r) ? 1 : 0;
                    flg_z = (result == 8'h00);
                    flg_n = result[7];
                    pc <= pc_plus2;
                    adb <= pc_plus2[14:0] & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_OPCODE;
                end
            end

            default: begin
                handled = 1'b0;
            end
        endcase
    endtask
endpackage
/* verilator lint_on UNUSEDSIGNAL */
