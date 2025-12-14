// cpu_exec_logic_pkg.sv - logic instructions
//
// Self-contained implementation of legacy logic opcodes:
// - AND (imm/zp/zpx/abs/absx/absy/(indx)/(indy))
// - EOR (imm/zp/zpx/abs/absx/absy/(indx)/(indy))
// - ORA (imm/zp/zpx/abs/absx/absy/(indx))
//
// Called from the CPU's DECODE_EXECUTE state. Reports whether it handled the opcode.

`include "consts_pkg.sv"

/* verilator lint_off UNUSEDSIGNAL */
package cpu_exec_logic_pkg;
    import cpu_pkg::*;
    import consts_pkg::*;

    task automatic exec_logic(
        input logic [7:0] opcode, ref logic [7:0] ra, input logic [7:0] rx, input logic [7:0] ry,
        ref logic flg_z, ref logic flg_n, ref logic [15:0] operands,
        ref logic [2:0] fetched_data_bytes, ref logic [15:0] fetched_data, input logic [7:0] dout_r,
        ref logic [15:0] pc, ref logic [15:0] pc_plus2, ref logic [15:0] pc_plus3,
        ref logic [14:0] adb, ref cpu_state_e state, ref fetch_stage_e fetch_stage,
        ref cpu_state_e next_state, output logic handled);
        handled = 1'b1;

        unique case (opcode)
            // AND immediate
            8'h29: begin
                ra = ra & operands[7:0];
                flg_z = (ra == 8'h00);
                flg_n = ra[7];
                pc <= pc_plus2;
                adb <= pc_plus2[14:0] & RAMW[14:0];
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
            end
            // AND zero page
            8'h25: begin
                if (fetched_data_bytes == 0) begin
                    adb <= {7'd0, operands[7:0]} & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                end else begin
                    ra = ra & dout_r;
                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];
                    pc <= pc_plus2;
                    adb <= pc_plus2[14:0] & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_OPCODE;
                end
            end
            // AND zero page, X
            8'h35: begin
                if (fetched_data_bytes == 0) begin
                    automatic logic [7:0] zp_addr = operands[7:0] + rx;
                    adb <= {7'd0, zp_addr} & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                end else begin
                    ra = ra & dout_r;
                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];
                    pc <= pc_plus2;
                    adb <= pc_plus2[14:0] & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_OPCODE;
                end
            end
            // AND absolute
            8'h2D: begin
                if (fetched_data_bytes == 0) begin
                    automatic logic [15:0] addr = operands[15:0] & 16'hFFFF;
                    adb <= addr[14:0] & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                end else begin
                    ra = ra & dout_r;
                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];
                    pc <= pc_plus3;
                    adb <= pc_plus3[14:0] & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_OPCODE;
                end
            end
            // AND absolute, X
            8'h3D: begin
                if (fetched_data_bytes == 0) begin
                    automatic logic [15:0] addr = (operands[15:0] + {8'h00, rx}) & 16'hFFFF;
                    adb <= addr[14:0] & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                end else begin
                    ra = ra & dout_r;
                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];
                    pc <= pc_plus3;
                    adb <= pc_plus3[14:0] & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_OPCODE;
                end
            end
            // AND absolute, Y
            8'h39: begin
                if (fetched_data_bytes == 0) begin
                    automatic logic [15:0] addr = (operands[15:0] + {8'h00, ry}) & 16'hFFFF;
                    adb <= addr[14:0] & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                end else begin
                    ra = ra & dout_r;
                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];
                    pc <= pc_plus3;
                    adb <= pc_plus3[14:0] & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_OPCODE;
                end
            end
            // AND (indirect, X)
            8'h21: begin
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
                        ra = ra & dout_r;
                        flg_z = (ra == 8'h00);
                        flg_n = ra[7];
                        pc <= pc_plus2;
                        adb <= pc_plus2[14:0] & RAMW[14:0];
                        state <= FETCH_REQ;
                        fetch_stage <= FETCH_OPCODE;
                    end
                    default: ;
                endcase
            end
            // AND (indirect), Y
            8'h31: begin
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
                        ra = ra & dout_r;
                        flg_z = (ra == 8'h00);
                        flg_n = ra[7];
                        pc <= pc_plus2;
                        adb <= pc_plus2[14:0] & RAMW[14:0];
                        state <= FETCH_REQ;
                        fetch_stage <= FETCH_OPCODE;
                    end
                    default: ;
                endcase
            end

            // EOR immediate
            8'h49: begin
                ra = ra ^ operands[7:0];
                flg_z = (ra == 8'h00);
                flg_n = ra[7];
                pc <= pc_plus2;
                adb <= pc_plus2[14:0] & RAMW[14:0];
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
            end
            // EOR zero page
            8'h45: begin
                if (fetched_data_bytes == 0) begin
                    adb <= {7'd0, operands[7:0]} & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                end else begin
                    ra = ra ^ dout_r;
                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];
                    pc <= pc_plus2;
                    adb <= pc_plus2[14:0] & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_OPCODE;
                end
            end
            // EOR zero page, X
            8'h55: begin
                if (fetched_data_bytes == 0) begin
                    automatic logic [7:0] zp_addr = operands[7:0] + rx;
                    adb <= {7'd0, zp_addr} & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                end else begin
                    ra = ra ^ dout_r;
                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];
                    pc <= pc_plus2;
                    adb <= pc_plus2[14:0] & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_OPCODE;
                end
            end
            // EOR absolute
            8'h4D: begin
                if (fetched_data_bytes == 0) begin
                    automatic logic [15:0] addr = operands[15:0] & 16'hFFFF;
                    adb <= addr[14:0] & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                end else begin
                    ra = ra ^ dout_r;
                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];
                    pc <= pc_plus3;
                    adb <= pc_plus3[14:0] & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_OPCODE;
                end
            end
            // EOR absolute, X
            8'h5D: begin
                if (fetched_data_bytes == 0) begin
                    automatic logic [15:0] addr = (operands[15:0] + {8'h00, rx}) & 16'hFFFF;
                    adb <= addr[14:0] & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                end else begin
                    ra = ra ^ dout_r;
                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];
                    pc <= pc_plus3;
                    adb <= pc_plus3[14:0] & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_OPCODE;
                end
            end
            // EOR absolute, Y
            8'h59: begin
                if (fetched_data_bytes == 0) begin
                    automatic logic [15:0] addr = (operands[15:0] + {8'h00, ry}) & 16'hFFFF;
                    adb <= addr[14:0] & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                end else begin
                    ra = ra ^ dout_r;
                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];
                    pc <= pc_plus3;
                    adb <= pc_plus3[14:0] & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_OPCODE;
                end
            end
            // EOR (indirect, X)
            8'h41: begin
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
                        ra = ra ^ dout_r;
                        flg_z = (ra == 8'h00);
                        flg_n = ra[7];
                        pc <= pc_plus2;
                        adb <= pc_plus2[14:0] & RAMW[14:0];
                        state <= FETCH_REQ;
                        fetch_stage <= FETCH_OPCODE;
                    end
                    default: ;
                endcase
            end
            // EOR (indirect), Y
            8'h51: begin
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
                        ra = ra ^ dout_r;
                        flg_z = (ra == 8'h00);
                        flg_n = ra[7];
                        pc <= pc_plus2;
                        adb <= pc_plus2[14:0] & RAMW[14:0];
                        state <= FETCH_REQ;
                        fetch_stage <= FETCH_OPCODE;
                    end
                    default: ;
                endcase
            end

            // ORA immediate
            8'h09: begin
                ra = ra | operands[7:0];
                flg_z = (ra == 8'h00);
                flg_n = ra[7];
                pc <= pc_plus2;
                adb <= pc_plus2[14:0] & RAMW[14:0];
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
            end
            // ORA zero page
            8'h05: begin
                if (fetched_data_bytes == 0) begin
                    adb <= {7'd0, operands[7:0]} & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                end else begin
                    ra = ra | dout_r;
                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];
                    pc <= pc_plus2;
                    adb <= pc_plus2[14:0] & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_OPCODE;
                end
            end
            // ORA zero page, X
            8'h15: begin
                if (fetched_data_bytes == 0) begin
                    automatic logic [7:0] zp_addr = operands[7:0] + rx;
                    adb <= {7'd0, zp_addr} & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                end else begin
                    ra = ra | dout_r;
                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];
                    pc <= pc_plus2;
                    adb <= pc_plus2[14:0] & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_OPCODE;
                end
            end
            // ORA absolute
            8'h0D: begin
                if (fetched_data_bytes == 0) begin
                    automatic logic [15:0] addr = operands[15:0] & 16'hFFFF;
                    adb <= addr[14:0] & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                end else begin
                    ra = ra | dout_r;
                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];
                    pc <= pc_plus3;
                    adb <= pc_plus3[14:0] & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_OPCODE;
                end
            end
            // ORA absolute, X
            8'h1D: begin
                if (fetched_data_bytes == 0) begin
                    automatic logic [15:0] addr = (operands[15:0] + {8'h00, rx}) & 16'hFFFF;
                    adb <= addr[14:0] & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                end else begin
                    ra = ra | dout_r;
                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];
                    pc <= pc_plus3;
                    adb <= pc_plus3[14:0] & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_OPCODE;
                end
            end
            // ORA absolute, Y
            8'h19: begin
                if (fetched_data_bytes == 0) begin
                    automatic logic [15:0] addr = (operands[15:0] + {8'h00, ry}) & 16'hFFFF;
                    adb <= addr[14:0] & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_DATA;
                    next_state <= DECODE_EXECUTE;
                end else begin
                    ra = ra | dout_r;
                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];
                    pc <= pc_plus3;
                    adb <= pc_plus3[14:0] & RAMW[14:0];
                    state <= FETCH_REQ;
                    fetch_stage <= FETCH_OPCODE;
                end
            end
            // ORA (indirect, X)
            8'h01: begin
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
                        ra = ra | dout_r;
                        flg_z = (ra == 8'h00);
                        flg_n = ra[7];
                        pc <= pc_plus2;
                        adb <= pc_plus2[14:0] & RAMW[14:0];
                        state <= FETCH_REQ;
                        fetch_stage <= FETCH_OPCODE;
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
