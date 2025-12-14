// cpu_exec_control_flow_pkg.sv - control flow + stack ops
//
// Self-contained implementation of legacy opcodes present in decode_control_flow.svinc:
// - NOP
// - JMP (abs/ind)
// - JSR / RTS
// - PHA / PLA
// - PHP
//
// Called from the CPU's DECODE_EXECUTE state. Reports whether it handled the opcode.

`include "consts_pkg.sv"

/* verilator lint_off UNUSEDSIGNAL */
package cpu_exec_control_flow_pkg;
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
        state <= FETCH_REQ;
        fetch_stage <= FETCH_OPCODE;
    endtask

    task automatic start_fetch_data(input logic [14:0] addr15, ref logic [14:0] adb,
                                    ref cpu_state_e state, ref fetch_stage_e fetch_stage,
                                    ref cpu_state_e next_state);
        adb <= addr15 & RAMW[14:0];
        state <= FETCH_REQ;
        fetch_stage <= FETCH_DATA;
        next_state <= DECODE_EXECUTE;
    endtask

    task automatic exec_control_flow(
        input logic [7:0] opcode, ref logic [15:0] pc, ref logic [15:0] pc_plus1,
        ref logic [15:0] pc_plus2, ref logic [15:0] pc_plus3, ref logic [14:0] adb,
        ref cpu_state_e state, ref fetch_stage_e fetch_stage, ref cpu_state_e next_state,
        ref logic [15:0] operands, ref logic [2:0] fetched_data_bytes,
        ref logic [15:0] fetched_data, input logic [7:0] dout_r, ref logic [2:0] written_data_bytes,
        ref logic [7:0] sp, ref logic [14:0] ada, ref logic [7:0] din, ref logic cea,
        ref logic v_cea, ref logic [7:0] ra, ref logic flg_c, ref logic flg_z, ref logic flg_i,
        ref logic flg_d, ref logic flg_b, ref logic flg_v, ref logic flg_n, output logic handled);
        handled = 1'b1;

        unique case (opcode)
            // NOP
            8'hEA: begin
                fetch_next_opcode(1, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
            end
            // JMP absolute
            8'h4C: begin
                automatic logic [15:0] jmp_addr = operands[15:0] & RAMW[15:0];
                pc <= jmp_addr;
                adb <= jmp_addr[14:0] & RAMW[14:0];
                state <= FETCH_REQ;
                fetch_stage <= FETCH_OPCODE;
            end
            // JMP indirect
            8'h6C: begin
                case (fetched_data_bytes)
                    0: begin
                        start_fetch_data(operands[14:0] & RAMW[14:0], adb, state, fetch_stage,
                                         next_state);
                    end
                    1: begin
                        fetched_data[7:0] = dout_r;
                        start_fetch_data((operands[14:0] + 15'd1) & RAMW[14:0], adb, state,
                                         fetch_stage, next_state);
                    end
                    2: begin
                        automatic logic [15:0] ind_addr = {dout_r, fetched_data[7:0]} & RAMW[15:0];
                        fetched_data[15:8] = dout_r;
                        pc <= ind_addr;
                        adb <= ind_addr[14:0] & RAMW[14:0];
                        state <= FETCH_REQ;
                        fetch_stage <= FETCH_OPCODE;
                    end
                    default: ;
                endcase
            end
            // JSR absolute
            8'h20: begin
                case (written_data_bytes)
                    0: begin
                        logic [15:0] stack_addr;
                        stack_addr = (STACK + {8'h00, sp}) & RAMW[15:0];
                        ada <= stack_addr[14:0] & RAMW[14:0];
                        sp = sp - 1'd1;
                        din <= pc_plus2[15:8];
                        cea <= 1;
                        v_cea = 0;
                        state <= WRITE_REQ;
                    end
                    1: begin
                        logic [15:0] stack_addr;
                        logic [15:0] ret_addr;
                        stack_addr = (STACK + {8'h00, sp}) & RAMW[15:0];
                        ret_addr   = pc + 16'd2;
                        ada <= stack_addr[14:0] & RAMW[14:0];
                        sp = sp - 1'd1;
                        din <= ret_addr[7:0];
                        cea <= 1;
                        v_cea = 0;
                        state <= WRITE_REQ;
                    end
                    2: begin
                        automatic logic [15:0] jsr_addr = operands[15:0] & RAMW[15:0];
                        pc <= jsr_addr;
                        adb <= jsr_addr[14:0] & RAMW[14:0];
                        state <= FETCH_REQ;
                        fetch_stage <= FETCH_OPCODE;
                    end
                    default: ;
                endcase
            end
            // RTS
            8'h60: begin
                case (fetched_data_bytes)
                    0: begin
                        logic [15:0] stack_addr;
                        sp = sp + 1'd1;
                        stack_addr = (STACK + {8'h00, sp}) & RAMW[15:0];
                        start_fetch_data(stack_addr[14:0] & RAMW[14:0], adb, state, fetch_stage,
                                         next_state);
                    end
                    1: begin
                        logic [15:0] stack_addr;
                        fetched_data[7:0] = dout_r;
                        sp = sp + 1'd1;
                        stack_addr = (STACK + {8'h00, sp}) & RAMW[15:0];
                        start_fetch_data(stack_addr[14:0] & RAMW[14:0], adb, state, fetch_stage,
                                         next_state);
                    end
                    2: begin
                        logic [15:0] pc1;
                        fetched_data[15:8] = dout_r;
                        pc1 = fetched_data + 16'd1;
                        pc <= pc1 & RAMW[15:0];
                        adb <= pc1[14:0] & RAMW[14:0];
                        state <= FETCH_REQ;
                        fetch_stage <= FETCH_OPCODE;
                    end
                    default: ;
                endcase
            end
            // PHA
            8'h48: begin
                logic [15:0] stack_addr;
                stack_addr = (STACK + {8'h00, sp}) & RAMW[15:0];
                ada <= stack_addr[14:0] & RAMW[14:0];
                sp = sp - 1'd1;
                din <= ra;
                cea   = 1;
                v_cea = 0;
                fetch_next_opcode(1, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
            end
            // PLA
            8'h68: begin
                if (fetched_data_bytes == 0) begin
                    logic [15:0] stack_addr;
                    sp = sp + 1'd1;
                    stack_addr = (STACK + {8'h00, sp}) & RAMW[15:0];
                    start_fetch_data(stack_addr[14:0] & RAMW[14:0], adb, state, fetch_stage,
                                     next_state);
                end else begin
                    ra = dout_r;
                    flg_z = (ra == 8'h00);
                    flg_n = ra[7];
                    fetch_next_opcode(1, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
                end
            end
            // PHP
            8'h08: begin
                logic [15:0] stack_addr;
                stack_addr = (STACK + {8'h00, sp}) & RAMW[15:0];
                ada <= stack_addr[14:0] & RAMW[14:0];
                sp = sp - 1'd1;
                din <= {flg_n, flg_v, 1'b1, flg_b, flg_d, flg_i, flg_z, flg_c};
                cea   = 1;
                v_cea = 0;
                fetch_next_opcode(1, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage);
            end

            default: begin
                handled = 1'b0;
            end
        endcase
    endtask
endpackage
/* verilator lint_on UNUSEDSIGNAL */
