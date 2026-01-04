// cpu_fsm_next_pkg.sv - planned 2-process FSM next-state logic
//
// This package is a stepping stone toward the 2-process FSM described in `docs/FSM.md`.
// It provides "next-state only" logic (no side effects) so that:
// - `always_comb` can compute next state/stage deterministically
// - `always_ff` can perform registered side effects and state updates
//
// Note: this is not fully wired into `cpu.sv` yet. We will migrate state-by-state.

`include "consts_pkg.sv"

/* verilator lint_off UNUSEDSIGNAL */
package cpu_fsm_next_pkg;
    import cpu_pkg::*;
    import cpu_types_pkg::*;
    import consts_pkg::*;

    // IFO (show-info) command ROM table (generated).
    `include "cpu_ifo_auto_generated.svh"

    typedef struct packed {
        cpu_state_e   next_state;
        fetch_stage_e next_fetch_stage;
    } fsm_next_t;

    function automatic fsm_next_t calc_boot_fetch_next(
        input cpu_state_e state, input fetch_stage_e fetch_stage,
        input cpu_state_e fetch_resume_state, input cpu_state_e prev_state, input logic [7:0] dout,
        input logic [14:0] boot_idx, input logic [15:0] boot_program_length, input logic boot_write,
        input logic [9:0] v_ada, input logic [31:0] show_info_counter,
        input show_info_stage_e show_info_stage, input logic show_info_mem_read);
        fsm_next_t r;
        logic [15:0] boot_idx_u16;
        int unsigned v_ada_u32;

        boot_idx_u16 = {1'b0, boot_idx};
        v_ada_u32 = {22'd0, v_ada};

        r.next_state = state;
        r.next_fetch_stage = fetch_stage;

        unique case (state)
            INIT: begin
                r.next_state = INIT_RAM;
            end

            HALT: begin
                r.next_state = HALT;
            end

            INIT_RAM: begin
                if (!boot_write) begin
                    if (boot_idx_u16 == boot_program_length) begin
                        r.next_state = FETCH_REQ;
                        r.next_fetch_stage = FETCH_OPCODE;
                    end else begin
                        r.next_state = INIT_RAM;
                    end
                end else begin
                    r.next_state = INIT_RAM;
                end
            end

            FETCH_REQ: begin
                if (fetch_stage == FETCH_OPCODE) begin
                    r.next_state = FETCH_RECV;
                end else begin
                    r.next_state = FETCH_WAIT;
                end
            end

            FETCH_WAIT: begin
                if (fetch_stage == FETCH_DATA) begin
                    r.next_state = fetch_resume_state;
                end else begin
                    r.next_state = FETCH_RECV;
                end
            end

            FETCH_RECV: begin
                unique case (fetch_stage)
                    FETCH_OPCODE: begin
                        unique case (dout)
                            // No operand instructions
                            8'hEA,
                            8'h60,
                            8'h48,
                            8'h68,
                            8'h08,
                            8'h28,
                            8'hE8,
                            8'hC8,
                            8'hCA,
                            8'h88,
                            8'h0A,
                            8'h4A,
                            8'h2A,
                            8'h6A,
                            8'hAA,
                            8'hA8,
                            8'h8A,
                            8'h98,
                            8'hBA,
                            8'h9A,
                            8'h18,
                            8'hB8,
                            8'h38,
                            8'hCF,
                            8'hEF: begin
                                r.next_state = DECODE_EXECUTE;
                            end

                            // 1-byte operand instructions
                            8'hA9,
                            8'hA5,
                            8'hB5,
                            8'hA2,
                            8'hA6,
                            8'hB6,
                            8'hA0,
                            8'hA4,
                            8'hB4,
                            8'h85,
                            8'h95,
                            8'h81,
                            8'h91,
                            8'h86,
                            8'h96,
                            8'h84,
                            8'h94,
                            8'hE6,
                            8'hF6,
                            8'hC6,
                            8'hD6,
                            8'h69,
                            8'h65,
                            8'h75,
                            8'h61,
                            8'h71,
                            8'hE9,
                            8'hE5,
                            8'hF5,
                            8'hE1,
                            8'hF1,
                            8'h29,
                            8'h25,
                            8'h35,
                            8'h21,
                            8'h31,
                            8'h49,
                            8'h45,
                            8'h55,
                            8'h41,
                            8'h51,
                            8'h09,
                            8'h05,
                            8'h15,
                            8'h01,
                            8'h11,
                            8'h06,
                            8'h16,
                            8'h46,
                            8'h56,
                            8'h26,
                            8'h36,
                            8'h66,
                            8'h76,
                            8'h24,
                            8'hC9,
                            8'hC5,
                            8'hD5,
                            8'hC1,
                            8'hD1,
                            8'hE0,
                            8'hE4,
                            8'hC0,
                            8'hC4,
                            8'hF0,
                            8'h30,
                            8'hD0,
                            8'h10,
                            8'h50,
                            8'h70,
                            8'h90,
                            8'hB0,
                            8'hFF: begin
                                r.next_fetch_stage = FETCH_OPERAND1;
                                r.next_state = FETCH_REQ;
                            end

                            default: begin
                                r.next_fetch_stage = FETCH_OPERAND1OF2;
                                r.next_state = FETCH_REQ;
                            end
                        endcase
                    end

                    FETCH_OPERAND1: begin
                        r.next_state = DECODE_EXECUTE;
                    end

                    FETCH_OPERAND1OF2: begin
                        r.next_fetch_stage = FETCH_OPERAND2;
                        r.next_state = FETCH_REQ;
                    end

                    FETCH_OPERAND2: begin
                        r.next_state = DECODE_EXECUTE;
                    end

                    default: begin
                        // Keep defaults.
                    end
                endcase
            end

            WRITE_REQ: begin
                r.next_state = DECODE_EXECUTE;
            end

            CLEAR_VRAM: begin
                r.next_state = CLEAR_VRAM2;
            end

            CLEAR_VRAM2: begin
                if (v_ada_u32 <= (COLUMNS * ROWS)) begin
                    r.next_state = CLEAR_VRAM2;
                end else begin
                    r.next_state = FETCH_REQ;
                    r.next_fetch_stage = FETCH_OPCODE;
                end
            end

            SHOW_INFO: begin
                r.next_state = SHOW_INFO2;
            end

            SHOW_INFO2: begin
                if (show_info_stage == SHOW_INFO_EXECUTE) begin
                    if (show_info_counter == 1020) begin
                        r.next_state = prev_state;
                    end else if (show_info_mem_read) begin
                        r.next_state = FETCH_REQ;
                        r.next_fetch_stage = FETCH_DATA;
                    end else begin
                        r.next_state = SHOW_INFO2;
                    end
                end else begin
                    r.next_state = SHOW_INFO2;
                end
            end

            INIT_VRAM: begin
                if (v_ada_u32 <= (COLUMNS * ROWS)) begin
                    r.next_state = INIT_VRAM;
                end else begin
                    r.next_state = HALT;
                end
            end

            default: begin
                // Keep defaults.
            end
        endcase

        return r;
    endfunction

    function automatic logic calc_decode_transfers_next(input cpu_ctx_t cur, ref cpu_ctx_t next);
        logic handled;
        logic [7:0] tmp_val;
        handled = 1'b1;

        unique case (cur.opcode)
            8'hAA: begin  // TAX
                tmp_val = cur.ra;
                next.rx = tmp_val;
                next.flg_z = (tmp_val == 8'h00);
                next.flg_n = tmp_val[7];
            end
            8'hA8: begin  // TAY
                tmp_val = cur.ra;
                next.ry = tmp_val;
                next.flg_z = (tmp_val == 8'h00);
                next.flg_n = tmp_val[7];
            end
            8'h8A: begin  // TXA
                tmp_val = cur.rx;
                next.ra = tmp_val;
                next.flg_z = (tmp_val == 8'h00);
                next.flg_n = tmp_val[7];
            end
            8'h98: begin  // TYA
                tmp_val = cur.ry;
                next.ra = tmp_val;
                next.flg_z = (tmp_val == 8'h00);
                next.flg_n = tmp_val[7];
            end
            8'hBA: begin  // TSX
                tmp_val = cur.sp;
                next.rx = tmp_val;
                next.flg_z = (tmp_val == 8'h00);
                next.flg_n = tmp_val[7];
            end
            8'h9A: begin  // TXS
                tmp_val = cur.rx;
                next.sp = tmp_val;
            end
            default: begin
                handled = 1'b0;
            end
        endcase

        if (handled) begin
            next.cea = 0;
            next.v_cea = 0;
            next.pc = cur.pc_plus1;
            next.adb = cur.pc_plus1[14:0] & RAMW15;
            next.state = FETCH_REQ;
            next.fetch_stage = FETCH_OPCODE;
        end

        return handled;
    endfunction

    function automatic logic calc_decode_branches_next(input cpu_ctx_t cur, ref cpu_ctx_t next);
        logic handled;
        logic branch_taken;
        logic signed [15:0] offset;
        logic [15:0] target;
        logic [7:0] imm;

        handled = 1'b1;
        unique case (cur.opcode)
            8'hF0: branch_taken = cur.flg_z;  // BEQ
            8'h30: branch_taken = cur.flg_n;  // BMI
            8'hD0: branch_taken = ~cur.flg_z;  // BNE
            8'h10: branch_taken = ~cur.flg_n;  // BPL
            8'h50: branch_taken = ~cur.flg_v;  // BVC
            8'h70: branch_taken = cur.flg_v;  // BVS
            8'h90: branch_taken = ~cur.flg_c;  // BCC
            default: begin
                handled = 1'b0;
                branch_taken = 1'b0;
            end
        endcase

        if (handled) begin
            imm = cur.operands[7:0];
            offset = {{8{imm[7]}}, imm};
            target = (cur.pc_plus2 + offset) & RAMW16;
            if (branch_taken) begin
                next.pc  = target;
                next.adb = target[14:0];
            end else begin
                next.pc  = cur.pc_plus2;
                next.adb = cur.pc_plus2[14:0] & RAMW15;
            end
            next.state = FETCH_REQ;
            next.fetch_stage = FETCH_OPCODE;
        end

        return handled;
    endfunction

    function automatic cpu_ctx_t request_data_fetch(cpu_ctx_t next, logic [15:0] target_addr);
        next.adb = target_addr[14:0] & RAMW15;
        next.state = FETCH_REQ;
        next.fetch_stage = FETCH_DATA;
        next.fetch_resume_state = DECODE_EXECUTE;
        return next;
    endfunction

    function automatic cpu_ctx_t return_to_opcode_fetch(cpu_ctx_t next, logic [15:0] next_pc);
        next.pc = next_pc;
        next.adb = next_pc[14:0] & RAMW15;
        next.state = FETCH_REQ;
        next.fetch_stage = FETCH_OPCODE;
        return next;
    endfunction

    function automatic cpu_ctx_t update_logic_flags(cpu_ctx_t next, logic [7:0] value);
        next.flg_z = (value == 8'h00);
        next.flg_n = value[7];
        return next;
    endfunction

    function automatic cpu_ctx_t apply_store_write(cpu_ctx_t next, logic [15:0] target_addr,
                                                   logic [7:0] data);
        logic [31:0] target32;
        target32 = {16'd0, target_addr};
        if (target32 >= VRAM_START && target32 < (VRAM_START + (COLUMNS * ROWS))) begin
            logic [31:0] off32;
            logic [31:0] shadow32;
            off32 = target32 - VRAM_START;
            shadow32 = off32 + SHADOW_VRAM_START;
            next.v_ada = off32[9:0] & VRAMW10;
            next.v_din = data;
            next.ada = shadow32[14:0] & RAMW15;
            next.din = data;
            next.write_to_vram = 1'b1;
        end else begin
            next.ada = target_addr[14:0] & RAMW15;
            next.din = data;
            next.write_to_vram = 1'b0;
        end
        return next;
    endfunction

    function automatic cpu_ctx_t store_and_fetch(cpu_ctx_t next, logic [15:0] target_addr,
                                                 logic [7:0] data, logic [15:0] next_pc);
        next = apply_store_write(next, target_addr, data);
        next.cea = 1;
        next.v_cea = next.write_to_vram;
        next = return_to_opcode_fetch(next, next_pc);
        return next;
    endfunction

    function automatic cpu_ctx_t apply_ram_write(cpu_ctx_t next, logic [15:0] target_addr,
                                                 logic [7:0] data);
        next.ada = target_addr[14:0] & RAMW15;
        next.din = data;
        next.cea = 1;
        next.v_cea = 0;
        next.write_to_vram = 1'b0;
        return next;
    endfunction

    function automatic logic calc_decode_shifts_next(input cpu_ctx_t cur, ref cpu_ctx_t next);
        logic handled;
        logic [7:0] result;
        logic [15:0] target_addr;
        logic [7:0] zp_addr;
        logic [7:0] carry_in;

        handled = 1'b1;

        unique case (cur.opcode)
            8'h0A: begin  // ASL accumulator
                next.flg_c = cur.ra[7];
                result = cur.ra << 1;
                next.ra = result;
                next = update_logic_flags(next, result);
                next = return_to_opcode_fetch(next, cur.pc_plus1);
            end
            8'h06: begin  // ASL zero page
                target_addr = {8'h00, cur.operands[7:0]};
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, target_addr);
                end else begin
                    result = cur.dout_r << 1;
                    next.flg_c = cur.dout_r[7];
                    next = update_logic_flags(next, result);
                    next = apply_ram_write(next, target_addr, result);
                    next = return_to_opcode_fetch(next, cur.pc_plus2);
                end
            end
            8'h16: begin  // ASL zero page, X
                zp_addr = cur.operands[7:0] + cur.rx;
                target_addr = {8'h00, zp_addr};
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, target_addr);
                end else begin
                    result = cur.dout_r << 1;
                    next.flg_c = cur.dout_r[7];
                    next = update_logic_flags(next, result);
                    next = apply_ram_write(next, target_addr, result);
                    next = return_to_opcode_fetch(next, cur.pc_plus2);
                end
            end
            8'h0E: begin  // ASL absolute
                target_addr = cur.operands;
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, target_addr);
                end else begin
                    result = cur.dout_r << 1;
                    next.flg_c = cur.dout_r[7];
                    next = update_logic_flags(next, result);
                    next = apply_ram_write(next, target_addr, result);
                    next = return_to_opcode_fetch(next, cur.pc_plus3);
                end
            end
            8'h1E: begin  // ASL absolute, X
                target_addr = (cur.operands + {8'h00, cur.rx}) & 16'hFFFF;
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, target_addr);
                end else begin
                    result = cur.dout_r << 1;
                    next.flg_c = cur.dout_r[7];
                    next = update_logic_flags(next, result);
                    next = apply_ram_write(next, target_addr, result);
                    next = return_to_opcode_fetch(next, cur.pc_plus3);
                end
            end
            8'h4A: begin  // LSR accumulator
                next.flg_c = cur.ra[0];
                result = cur.ra >> 1;
                next.ra = result;
                next = update_logic_flags(next, result);
                next = return_to_opcode_fetch(next, cur.pc_plus1);
            end
            8'h46: begin  // LSR zero page
                target_addr = {8'h00, cur.operands[7:0]};
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, target_addr);
                end else begin
                    result = cur.dout_r >> 1;
                    next.flg_c = cur.dout_r[0];
                    next = update_logic_flags(next, result);
                    next = apply_ram_write(next, target_addr, result);
                    next = return_to_opcode_fetch(next, cur.pc_plus2);
                end
            end
            8'h56: begin  // LSR zero page, X
                zp_addr = cur.operands[7:0] + cur.rx;
                target_addr = {8'h00, zp_addr};
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, target_addr);
                end else begin
                    result = cur.dout_r >> 1;
                    next.flg_c = cur.dout_r[0];
                    next = update_logic_flags(next, result);
                    next = apply_ram_write(next, target_addr, result);
                    next = return_to_opcode_fetch(next, cur.pc_plus2);
                end
            end
            8'h4E: begin  // LSR absolute
                target_addr = cur.operands;
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, target_addr);
                end else begin
                    result = cur.dout_r >> 1;
                    next.flg_c = cur.dout_r[0];
                    next = update_logic_flags(next, result);
                    next = apply_ram_write(next, target_addr, result);
                    next = return_to_opcode_fetch(next, cur.pc_plus3);
                end
            end
            8'h5E: begin  // LSR absolute, X
                target_addr = (cur.operands + {8'h00, cur.rx}) & 16'hFFFF;
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, target_addr);
                end else begin
                    result = cur.dout_r >> 1;
                    next.flg_c = cur.dout_r[0];
                    next = update_logic_flags(next, result);
                    next = apply_ram_write(next, target_addr, result);
                    next = return_to_opcode_fetch(next, cur.pc_plus3);
                end
            end
            8'h2A: begin  // ROL accumulator
                carry_in = cur.flg_c ? 8'h01 : 8'h00;
                next.flg_c = cur.ra[7];
                result = (cur.ra << 1) | carry_in;
                next.ra = result;
                next = update_logic_flags(next, result);
                next = return_to_opcode_fetch(next, cur.pc_plus1);
            end
            8'h26: begin  // ROL zero page
                target_addr = {8'h00, cur.operands[7:0]};
                carry_in = cur.flg_c ? 8'h01 : 8'h00;
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, target_addr);
                end else begin
                    next.flg_c = cur.dout_r[7];
                    result = (cur.dout_r << 1) | carry_in;
                    next = update_logic_flags(next, result);
                    next = apply_ram_write(next, target_addr, result);
                    next = return_to_opcode_fetch(next, cur.pc_plus2);
                end
            end
            8'h36: begin  // ROL zero page, X
                zp_addr = cur.operands[7:0] + cur.rx;
                target_addr = {8'h00, zp_addr};
                carry_in = cur.flg_c ? 8'h01 : 8'h00;
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, target_addr);
                end else begin
                    next.flg_c = cur.dout_r[7];
                    result = (cur.dout_r << 1) | carry_in;
                    next = update_logic_flags(next, result);
                    next = apply_ram_write(next, target_addr, result);
                    next = return_to_opcode_fetch(next, cur.pc_plus2);
                end
            end
            8'h2E: begin  // ROL absolute
                target_addr = cur.operands;
                carry_in = cur.flg_c ? 8'h01 : 8'h00;
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, target_addr);
                end else begin
                    next.flg_c = cur.dout_r[7];
                    result = (cur.dout_r << 1) | carry_in;
                    next = update_logic_flags(next, result);
                    next = apply_ram_write(next, target_addr, result);
                    next = return_to_opcode_fetch(next, cur.pc_plus3);
                end
            end
            8'h3E: begin  // ROL absolute, X
                target_addr = (cur.operands + {8'h00, cur.rx}) & 16'hFFFF;
                carry_in = cur.flg_c ? 8'h01 : 8'h00;
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, target_addr);
                end else begin
                    next.flg_c = cur.dout_r[7];
                    result = (cur.dout_r << 1) | carry_in;
                    next = update_logic_flags(next, result);
                    next = apply_ram_write(next, target_addr, result);
                    next = return_to_opcode_fetch(next, cur.pc_plus3);
                end
            end
            8'h6A: begin  // ROR accumulator
                carry_in = cur.flg_c ? 8'h80 : 8'h00;
                next.flg_c = cur.ra[0];
                result = (cur.ra >> 1) | carry_in;
                next.ra = result;
                next = update_logic_flags(next, result);
                next = return_to_opcode_fetch(next, cur.pc_plus1);
            end
            8'h66: begin  // ROR zero page
                target_addr = {8'h00, cur.operands[7:0]};
                carry_in = cur.flg_c ? 8'h80 : 8'h00;
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, target_addr);
                end else begin
                    next.flg_c = cur.dout_r[0];
                    result = (cur.dout_r >> 1) | carry_in;
                    next = update_logic_flags(next, result);
                    next = apply_ram_write(next, target_addr, result);
                    next = return_to_opcode_fetch(next, cur.pc_plus2);
                end
            end
            8'h76: begin  // ROR zero page, X
                zp_addr = cur.operands[7:0] + cur.rx;
                target_addr = {8'h00, zp_addr};
                carry_in = cur.flg_c ? 8'h80 : 8'h00;
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, target_addr);
                end else begin
                    next.flg_c = cur.dout_r[0];
                    result = (cur.dout_r >> 1) | carry_in;
                    next = update_logic_flags(next, result);
                    next = apply_ram_write(next, target_addr, result);
                    next = return_to_opcode_fetch(next, cur.pc_plus2);
                end
            end
            8'h6E: begin  // ROR absolute
                target_addr = cur.operands;
                carry_in = cur.flg_c ? 8'h80 : 8'h00;
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, target_addr);
                end else begin
                    next.flg_c = cur.dout_r[0];
                    result = (cur.dout_r >> 1) | carry_in;
                    next = update_logic_flags(next, result);
                    next = apply_ram_write(next, target_addr, result);
                    next = return_to_opcode_fetch(next, cur.pc_plus3);
                end
            end
            default: begin
                handled = 1'b0;
            end
        endcase

        return handled;
    endfunction

    function automatic logic calc_decode_load_store_next(input cpu_ctx_t cur, ref cpu_ctx_t next);
        logic handled;
        logic [15:0] target_addr;
        logic [7:0] zp_addr;

        handled = 1'b1;
        unique case (cur.opcode)
            8'hA9: begin  // LDA immediate
                next.ra = cur.operands[7:0];
                next = update_logic_flags(next, next.ra);
                next = return_to_opcode_fetch(next, cur.pc_plus2);
            end
            8'hA5: begin  // LDA zero page
                target_addr = {8'h00, cur.operands[7:0]};
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, target_addr);
                end else begin
                    next.ra = cur.dout_r;
                    next = update_logic_flags(next, next.ra);
                    next = return_to_opcode_fetch(next, cur.pc_plus2);
                end
            end
            8'hB5: begin  // LDA zero page, X
                zp_addr = cur.operands[7:0] + cur.rx;
                target_addr = {8'h00, zp_addr};
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, target_addr);
                end else begin
                    next.ra = cur.dout_r;
                    next = update_logic_flags(next, next.ra);
                    next = return_to_opcode_fetch(next, cur.pc_plus2);
                end
            end
            8'hAD: begin  // LDA absolute
                target_addr = cur.operands;
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, target_addr);
                end else begin
                    next.ra = cur.dout_r;
                    next = update_logic_flags(next, next.ra);
                    next = return_to_opcode_fetch(next, cur.pc_plus3);
                end
            end
            8'hBD: begin  // LDA absolute, X
                target_addr = (cur.operands + {8'h00, cur.rx}) & 16'hFFFF;
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, target_addr);
                end else begin
                    next.ra = cur.dout_r;
                    next = update_logic_flags(next, next.ra);
                    next = return_to_opcode_fetch(next, cur.pc_plus3);
                end
            end
            8'hB9: begin  // LDA absolute, Y
                target_addr = (cur.operands + {8'h00, cur.ry}) & 16'hFFFF;
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, target_addr);
                end else begin
                    next.ra = cur.dout_r;
                    next = update_logic_flags(next, next.ra);
                    next = return_to_opcode_fetch(next, cur.pc_plus3);
                end
            end
            8'hA1: begin  // LDA (indirect, X)
                case (cur.fetched_data_bytes)
                    0: begin
                        zp_addr = cur.operands[7:0] + cur.rx;
                        target_addr = {8'h00, zp_addr};
                        next = request_data_fetch(next, target_addr);
                    end
                    1: begin
                        zp_addr = cur.operands[7:0] + cur.rx + 8'h01;
                        next.fetched_data[7:0] = cur.dout_r;
                        target_addr = {8'h00, zp_addr};
                        next = request_data_fetch(next, target_addr);
                    end
                    2: begin
                        target_addr = ({cur.dout_r, cur.fetched_data[7:0]}) & 16'hFFFF;
                        next = request_data_fetch(next, target_addr);
                    end
                    3: begin
                        next.ra = cur.dout_r;
                        next = update_logic_flags(next, next.ra);
                        next = return_to_opcode_fetch(next, cur.pc_plus2);
                    end
                    default: begin
                    end
                endcase
            end
            8'hB1: begin  // LDA (indirect), Y
                case (cur.fetched_data_bytes)
                    0: begin
                        target_addr = {8'h00, cur.operands[7:0]};
                        next = request_data_fetch(next, target_addr);
                    end
                    1: begin
                        next.fetched_data[7:0] = cur.dout_r;
                        zp_addr = cur.operands[7:0] + 8'h01;
                        target_addr = {8'h00, zp_addr};
                        next = request_data_fetch(next, target_addr);
                    end
                    2: begin
                        target_addr = ({cur.dout_r, cur.fetched_data[7:0]} + {8'h00, cur.ry}) & 16'hFFFF;
                        next = request_data_fetch(next, target_addr);
                    end
                    3: begin
                        next.ra = cur.dout_r;
                        next = update_logic_flags(next, next.ra);
                        next = return_to_opcode_fetch(next, cur.pc_plus2);
                    end
                    default: begin
                    end
                endcase
            end
            8'hA2: begin  // LDX immediate
                next.rx = cur.operands[7:0];
                next = update_logic_flags(next, next.rx);
                next = return_to_opcode_fetch(next, cur.pc_plus2);
            end
            8'hA6: begin  // LDX zero page
                target_addr = {8'h00, cur.operands[7:0]};
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, target_addr);
                end else begin
                    next.rx = cur.dout_r;
                    next = update_logic_flags(next, next.rx);
                    next = return_to_opcode_fetch(next, cur.pc_plus2);
                end
            end
            8'hB6: begin  // LDX zero page, Y
                zp_addr = cur.operands[7:0] + cur.ry;
                target_addr = {8'h00, zp_addr};
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, target_addr);
                end else begin
                    next.rx = cur.dout_r;
                    next = update_logic_flags(next, next.rx);
                    next = return_to_opcode_fetch(next, cur.pc_plus2);
                end
            end
            8'hAE: begin  // LDX absolute
                target_addr = cur.operands;
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, target_addr);
                end else begin
                    next.rx = cur.dout_r;
                    next = update_logic_flags(next, next.rx);
                    next = return_to_opcode_fetch(next, cur.pc_plus3);
                end
            end
            8'hBE: begin  // LDX absolute, Y
                target_addr = (cur.operands + {8'h00, cur.ry}) & 16'hFFFF;
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, target_addr);
                end else begin
                    next.rx = cur.dout_r;
                    next = update_logic_flags(next, next.rx);
                    next = return_to_opcode_fetch(next, cur.pc_plus3);
                end
            end
            8'hA0: begin  // LDY immediate
                next.ry = cur.operands[7:0];
                next = update_logic_flags(next, next.ry);
                next = return_to_opcode_fetch(next, cur.pc_plus2);
            end
            8'hA4: begin  // LDY zero page
                target_addr = {8'h00, cur.operands[7:0]};
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, target_addr);
                end else begin
                    next.ry = cur.dout_r;
                    next = update_logic_flags(next, next.ry);
                    next = return_to_opcode_fetch(next, cur.pc_plus2);
                end
            end
            8'hB4: begin  // LDY zero page, X
                zp_addr = cur.operands[7:0] + cur.rx;
                target_addr = {8'h00, zp_addr};
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, target_addr);
                end else begin
                    next.ry = cur.dout_r;
                    next = update_logic_flags(next, next.ry);
                    next = return_to_opcode_fetch(next, cur.pc_plus2);
                end
            end
            8'hAC: begin  // LDY absolute
                target_addr = cur.operands;
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, target_addr);
                end else begin
                    next.ry = cur.dout_r;
                    next = update_logic_flags(next, next.ry);
                    next = return_to_opcode_fetch(next, cur.pc_plus3);
                end
            end
            default: begin
                handled = 1'b0;
            end
        endcase

        return handled;
    endfunction


    localparam logic [1:0] LOGIC_AND = 2'd0;
    localparam logic [1:0] LOGIC_EOR = 2'd1;
    localparam logic [1:0] LOGIC_ORA = 2'd2;

    function automatic logic [7:0] apply_logic_op(input logic [7:0] lhs, input logic [7:0] rhs,
                                                  input logic [1:0] op_type);
        unique case (op_type)
            LOGIC_AND: return lhs & rhs;
            LOGIC_EOR: return lhs ^ rhs;
            LOGIC_ORA: return lhs | rhs;
            default:   return 8'h00;
        endcase
    endfunction

    function automatic logic calc_decode_flags_custom_next(input cpu_ctx_t cur, ref cpu_ctx_t next);
        logic handled;
        handled = 1'b1;

        unique case (cur.opcode)
            8'h18: begin  // CLC
                next.flg_c = 1'b0;
                next.pc = cur.pc_plus1;
                next.adb = cur.pc_plus1[14:0] & RAMW15;
                next.state = FETCH_REQ;
                next.fetch_stage = FETCH_OPCODE;
            end
            8'hB8: begin  // CLV
                next.flg_v = 1'b0;
                next.pc = cur.pc_plus1;
                next.adb = cur.pc_plus1[14:0] & RAMW15;
                next.state = FETCH_REQ;
                next.fetch_stage = FETCH_OPCODE;
            end
            8'h38: begin  // SEC
                next.flg_c = 1'b1;
                next.pc = cur.pc_plus1;
                next.adb = cur.pc_plus1[14:0] & RAMW15;
                next.state = FETCH_REQ;
                next.fetch_stage = FETCH_OPCODE;
            end
            8'hCF: begin  // CVR
                next.state = CLEAR_VRAM;
            end
            8'hDF: begin  // IFO
                if (cur.operands != 16'hFFFF) begin
                    next.show_info_counter = 32'h0;
                    next.prev_state = DECODE_EXECUTE;
                    next.state = SHOW_INFO;
                    next.show_info_stage = SHOW_INFO_FETCH;
                end else begin
                    next.show_info_counter = 32'h0;
                    next.pc = cur.pc_plus3;
                    next.adb = cur.pc_plus3[14:0] & RAMW15;
                    next.state = FETCH_REQ;
                    next.fetch_stage = FETCH_OPCODE;
                end
            end
            8'hEF: begin  // HLT
                next.state = HALT;
            end
            8'hFF: begin  // WVS
                unique case (cur.vsync_stage)
                    0: begin
                        next.vsync_stage = (cur.vsync_sync == 1'b1) ? 1 : 2;
                    end
                    1: begin
                        if (cur.vsync_sync == 1'b0) begin
                            next.vsync_stage = 2;
                        end
                    end
                    2: begin
                        if (cur.vsync_sync == 1'b1) begin
                            if (cur.operands[7:0] == 8'h00) begin
                                next.vsync_stage = 0;
                                next.pc = cur.pc_plus2;
                                next.adb = cur.pc_plus2[14:0] & RAMW15;
                                next.state = FETCH_REQ;
                                next.fetch_stage = FETCH_OPCODE;
                            end else begin
                                next.operands[7:0] = cur.operands[7:0] - 1'b1;
                                next.vsync_stage   = 1;
                            end
                        end
                    end
                endcase
            end
            default: begin
                handled = 1'b0;
            end
        endcase

        return handled;
    endfunction

    function automatic logic calc_decode_compare_next(input cpu_ctx_t cur, ref cpu_ctx_t next);
        logic handled;
        logic [7:0] result;

        handled = 1'b1;
        unique case (cur.opcode)
            8'hC9: begin  // CMP immediate
                result = cur.ra - cur.operands[7:0];
                next.flg_c = (cur.ra >= cur.operands[7:0]) ? 1 : 0;
                next.flg_z = (result == 8'h00);
                next.flg_n = result[7];
                next.pc = cur.pc_plus2;
                next.adb = cur.pc_plus2[14:0] & RAMW15;
                next.state = FETCH_REQ;
                next.fetch_stage = FETCH_OPCODE;
            end
            8'hE0: begin  // CPX immediate
                result = cur.rx - cur.operands[7:0];
                next.flg_c = (cur.rx >= cur.operands[7:0]) ? 1 : 0;
                next.flg_z = (result == 8'h00);
                next.flg_n = result[7];
                next.pc = cur.pc_plus2;
                next.adb = cur.pc_plus2[14:0] & RAMW15;
                next.state = FETCH_REQ;
                next.fetch_stage = FETCH_OPCODE;
            end
            8'hC0: begin  // CPY immediate
                result = cur.ry - cur.operands[7:0];
                next.flg_c = (cur.ry >= cur.operands[7:0]) ? 1 : 0;
                next.flg_z = (result == 8'h00);
                next.flg_n = result[7];
                next.pc = cur.pc_plus2;
                next.adb = cur.pc_plus2[14:0] & RAMW15;
                next.state = FETCH_REQ;
                next.fetch_stage = FETCH_OPCODE;
            end
            default: begin
                handled = 1'b0;
            end
        endcase

        return handled;
    endfunction

    function automatic logic calc_decode_logic_next(input cpu_ctx_t cur, ref cpu_ctx_t next);
        logic handled;

        handled = 1'b1;
        unique case (cur.opcode)
            8'h29: begin  // AND immediate
                logic [7:0] result = apply_logic_op(cur.ra, cur.operands[7:0], LOGIC_AND);
                next.ra = result;
                next = update_logic_flags(next, result);
                next = return_to_opcode_fetch(next, cur.pc_plus2);
            end
            8'h49: begin  // EOR immediate
                logic [7:0] result = apply_logic_op(cur.ra, cur.operands[7:0], LOGIC_EOR);
                next.ra = result;
                next = update_logic_flags(next, result);
                next = return_to_opcode_fetch(next, cur.pc_plus2);
            end
            8'h09: begin  // ORA immediate
                logic [7:0] result = apply_logic_op(cur.ra, cur.operands[7:0], LOGIC_ORA);
                next.ra = result;
                next = update_logic_flags(next, result);
                next = return_to_opcode_fetch(next, cur.pc_plus2);
            end

            8'h25, 8'h45, 8'h05: begin  // AND/EOR/ORA zero page
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, {8'h00, cur.operands[7:0]});
                end else begin
                    logic [1:0] op_type = (cur.opcode == 8'h25) ? LOGIC_AND
                                 : (cur.opcode == 8'h45) ? LOGIC_EOR
                                 : LOGIC_ORA;
                    logic [7:0] result = apply_logic_op(cur.ra, cur.dout_r, op_type);
                    next.ra = result;
                    next = update_logic_flags(next, result);
                    next = return_to_opcode_fetch(next, cur.pc_plus2);
                end
            end

            8'h35, 8'h55, 8'h15: begin  // AND/EOR/ORA zero page,X
                logic [7:0] zp_addr = cur.operands[7:0] + cur.rx;
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, {8'h00, zp_addr});
                end else begin
                    logic [1:0] op_type = (cur.opcode == 8'h35) ? LOGIC_AND
                                 : (cur.opcode == 8'h55) ? LOGIC_EOR
                                 : LOGIC_ORA;
                    logic [7:0] result = apply_logic_op(cur.ra, cur.dout_r, op_type);
                    next.ra = result;
                    next = update_logic_flags(next, result);
                    next = return_to_opcode_fetch(next, cur.pc_plus2);
                end
            end

            8'h2D, 8'h4D, 8'h0D: begin  // AND/EOR/ORA absolute
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, cur.operands);
                end else begin
                    logic [1:0] op_type = (cur.opcode == 8'h2D) ? LOGIC_AND
                                 : (cur.opcode == 8'h4D) ? LOGIC_EOR
                                 : LOGIC_ORA;
                    logic [7:0] result = apply_logic_op(cur.ra, cur.dout_r, op_type);
                    next.ra = result;
                    next = update_logic_flags(next, result);
                    next = return_to_opcode_fetch(next, cur.pc_plus3);
                end
            end

            8'h3D, 8'h5D, 8'h1D: begin  // AND/EOR/ORA absolute,X
                logic [15:0] addr = (cur.operands + {8'h00, cur.rx}) & 16'hFFFF;
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, addr);
                end else begin
                    logic [1:0] op_type = (cur.opcode == 8'h3D) ? LOGIC_AND
                                 : (cur.opcode == 8'h5D) ? LOGIC_EOR
                                 : LOGIC_ORA;
                    logic [7:0] result = apply_logic_op(cur.ra, cur.dout_r, op_type);
                    next.ra = result;
                    next = update_logic_flags(next, result);
                    next = return_to_opcode_fetch(next, cur.pc_plus3);
                end
            end

            8'h39, 8'h59, 8'h19: begin  // AND/EOR/ORA absolute,Y
                logic [15:0] addr = (cur.operands + {8'h00, cur.ry}) & 16'hFFFF;
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, addr);
                end else begin
                    logic [1:0] op_type = (cur.opcode == 8'h39) ? LOGIC_AND
                                 : (cur.opcode == 8'h59) ? LOGIC_EOR
                                 : LOGIC_ORA;
                    logic [7:0] result = apply_logic_op(cur.ra, cur.dout_r, op_type);
                    next.ra = result;
                    next = update_logic_flags(next, result);
                    next = return_to_opcode_fetch(next, cur.pc_plus3);
                end
            end

            8'h21, 8'h41, 8'h01: begin  // AND/EOR/ORA (indirect,X)
                logic [7:0] op_low = cur.operands[7:0];
                logic [7:0] zp_addr;
                unique case (cur.fetched_data_bytes)
                    0: begin
                        zp_addr = op_low + cur.rx;
                        next = request_data_fetch(next, {8'h00, zp_addr});
                    end
                    1: begin
                        next.fetched_data[7:0] = cur.dout_r;
                        zp_addr = op_low + cur.rx + 8'h01;
                        next = request_data_fetch(next, {8'h00, zp_addr});
                    end
                    2: begin
                        logic [15:0] target = ({cur.dout_r, cur.fetched_data[7:0]}) & 16'hFFFF;
                        next = request_data_fetch(next, target);
                    end
                    3: begin
                        logic [1:0] op_type = (cur.opcode == 8'h21) ? LOGIC_AND
                                   : (cur.opcode == 8'h41) ? LOGIC_EOR
                                   : LOGIC_ORA;
                        logic [7:0] result = apply_logic_op(cur.ra, cur.dout_r, op_type);
                        next.ra = result;
                        next = update_logic_flags(next, result);
                        next = return_to_opcode_fetch(next, cur.pc_plus2);
                    end
                    default: begin
                    end
                endcase
            end

            8'h31, 8'h51: begin  // AND/EOR (indirect),Y
                logic [7:0] op_low = cur.operands[7:0];
                logic [7:0] zp_addr;
                unique case (cur.fetched_data_bytes)
                    0: begin
                        next = request_data_fetch(next, {8'h00, op_low});
                    end
                    1: begin
                        next.fetched_data[7:0] = cur.dout_r;
                        zp_addr = op_low + 8'h01;
                        next = request_data_fetch(next, {8'h00, zp_addr});
                    end
                    2: begin
                        logic [15:0] target = ({cur.dout_r, cur.fetched_data[7:0]} + {8'h00, cur.ry}) & 16'hFFFF;
                        next = request_data_fetch(next, target);
                    end
                    3: begin
                        logic [1:0] op_type = (cur.opcode == 8'h31) ? LOGIC_AND : LOGIC_EOR;
                        logic [7:0] result = apply_logic_op(cur.ra, cur.dout_r, op_type);
                        next.ra = result;
                        next = update_logic_flags(next, result);
                        next = return_to_opcode_fetch(next, cur.pc_plus2);
                    end
                    default: begin
                    end
                endcase
            end

            default: begin
                handled = 1'b0;
            end
        endcase

        return handled;
    endfunction

    function automatic logic calc_decode_store_next(input cpu_ctx_t cur, ref cpu_ctx_t next);
        logic handled;
        logic [15:0] addr;

        handled = 1'b1;
        unique case (cur.opcode)
            8'h85: begin  // STA zero page
                next = store_and_fetch(next, {8'h00, cur.operands[7:0]}, cur.ra, cur.pc_plus2);
            end
            8'h95: begin  // STA zero page, X
                next = store_and_fetch(next, {8'h00, cur.operands[7:0] + cur.rx}, cur.ra,
                                       cur.pc_plus2);
            end
            8'h8D: begin  // STA absolute
                next = store_and_fetch(next, cur.operands[15:0], cur.ra, cur.pc_plus3);
            end
            8'h9D: begin  // STA absolute, X
                addr = (cur.operands[15:0] + {8'h00, cur.rx}) & 16'hFFFF;
                next = store_and_fetch(next, addr, cur.ra, cur.pc_plus3);
            end
            8'h99: begin  // STA absolute, Y
                addr = (cur.operands[15:0] + {8'h00, cur.ry}) & 16'hFFFF;
                next = store_and_fetch(next, addr, cur.ra, cur.pc_plus3);
            end
            8'h81: begin  // STA (indirect, X)
                logic [7:0] zp_addr;
                unique case (cur.fetched_data_bytes)
                    0: begin
                        zp_addr = cur.operands[7:0] + cur.rx;
                        next = request_data_fetch(next, {8'h00, zp_addr});
                    end
                    1: begin
                        next.fetched_data[7:0] = cur.dout_r;
                        zp_addr = cur.operands[7:0] + cur.rx + 8'h01;
                        next = request_data_fetch(next, {8'h00, zp_addr});
                    end
                    2: begin
                        addr = ({cur.dout_r, cur.fetched_data[7:0]}) & 16'hFFFF;
                        next = store_and_fetch(next, addr, cur.ra, cur.pc_plus2);
                    end
                    default: begin
                    end
                endcase
            end
            8'h91: begin  // STA (indirect), Y
                logic [7:0] zp_addr;
                unique case (cur.fetched_data_bytes)
                    0: begin
                        next = request_data_fetch(next, {8'h00, cur.operands[7:0]});
                    end
                    1: begin
                        next.fetched_data[7:0] = cur.dout_r;
                        zp_addr = cur.operands[7:0] + 8'h01;
                        next = request_data_fetch(next, {8'h00, zp_addr});
                    end
                    2: begin
                        addr = ({cur.dout_r, cur.fetched_data[7:0]} + {8'h00, cur.ry}) & 16'hFFFF;
                        next = store_and_fetch(next, addr, cur.ra, cur.pc_plus2);
                    end
                    default: begin
                    end
                endcase
            end
            8'h86: begin  // STX zero page
                next = store_and_fetch(next, {8'h00, cur.operands[7:0]}, cur.rx, cur.pc_plus2);
            end
            8'h96: begin  // STX zero page, Y
                logic [15:0] zp_y = {8'h00, cur.operands[7:0] + cur.ry};
                next = store_and_fetch(next, zp_y, cur.rx, cur.pc_plus2);
            end
            8'h8E: begin  // STX absolute
                next = store_and_fetch(next, cur.operands[15:0], cur.rx, cur.pc_plus3);
            end
            8'h84: begin  // STY zero page
                next = store_and_fetch(next, {8'h00, cur.operands[7:0]}, cur.ry, cur.pc_plus2);
            end
            8'h94: begin  // STY zero page, X
                logic [15:0] zp_x = {8'h00, cur.operands[7:0] + cur.rx};
                next = store_and_fetch(next, zp_x, cur.ry, cur.pc_plus2);
            end
            default: begin
                handled = 1'b0;
            end
        endcase

        return handled;
    endfunction

    function automatic logic calc_decode_control_flow_next(input cpu_ctx_t cur, ref cpu_ctx_t next);
        logic handled;
        logic [15:0] stack_addr;
        logic [15:0] ret_addr;
        logic [15:0] target_addr;
        logic [15:0] pc1;
        logic [7:0] status;
        logic [7:0] new_sp;

        handled = 1'b1;
        unique case (cur.opcode)
            8'hEA: begin  // NOP
                next = return_to_opcode_fetch(next, cur.pc_plus1);
            end
            8'h4C: begin  // JMP absolute
                next = return_to_opcode_fetch(next, cur.operands);
            end
            8'h6C: begin  // JMP indirect
                unique case (cur.fetched_data_bytes)
                    0: begin
                        next = request_data_fetch(next, {1'b0, (cur.operands[14:0] & RAMW15)});
                    end
                    1: begin
                        next.fetched_data[7:0] = cur.dout_r;
                        next = request_data_fetch(next,
                                                  {1'b0, ((cur.operands[14:0] + 1'b1) & RAMW15)});
                    end
                    2: begin
                        logic [15:0] ind_addr = ({cur.dout_r, cur.fetched_data[7:0]}) & 16'hFFFF;
                        next.fetched_data[15:8] = cur.dout_r;
                        next = return_to_opcode_fetch(next, ind_addr);
                    end
                    default: begin
                        handled = 1'b0;
                    end
                endcase
            end
            8'h20: begin  // JSR
                unique case (cur.written_data_bytes)
                    0: begin
                        stack_addr = (STACK + {8'h00, cur.sp}) & RAMW16;
                        next.sp = (cur.sp - 1'b1) & 8'hFF;
                        next.ada = stack_addr[14:0];
                        next.din = cur.pc_plus2[15:8];
                        next.cea = 1;
                        next.v_cea = 0;
                        next.state = WRITE_REQ;
                    end
                    1: begin
                        stack_addr = (STACK + {8'h00, cur.sp}) & RAMW16;
                        ret_addr = cur.pc + 16'd2;
                        next.sp = (cur.sp - 1'b1) & 8'hFF;
                        next.ada = stack_addr[14:0];
                        next.din = ret_addr[7:0];
                        next.cea = 1;
                        next.v_cea = 0;
                        next.state = WRITE_REQ;
                    end
                    2: begin
                        target_addr = cur.operands;
                        next = return_to_opcode_fetch(next, target_addr);
                    end
                    default: begin
                        handled = 1'b0;
                    end
                endcase
            end
            8'h60: begin  // RTS
                unique case (cur.fetched_data_bytes)
                    0: begin
                        new_sp = (cur.sp + 1'b1) & 8'hFF;
                        stack_addr = (STACK + {8'h00, new_sp}) & RAMW16;
                        next.sp = new_sp;
                        next = request_data_fetch(next, stack_addr);
                    end
                    1: begin
                        next.fetched_data[7:0] = cur.dout_r;
                        new_sp = (cur.sp + 1'b1) & 8'hFF;
                        stack_addr = (STACK + {8'h00, new_sp}) & RAMW16;
                        next.sp = new_sp;
                        next = request_data_fetch(next, stack_addr);
                    end
                    2: begin
                        next.fetched_data[15:8] = cur.dout_r;
                        pc1 = cur.fetched_data + 1'b1;
                        next = return_to_opcode_fetch(next, pc1 & RAMW16);
                    end
                    default: begin
                        handled = 1'b0;
                    end
                endcase
            end
            8'h48: begin  // PHA
                stack_addr = (STACK + {8'h00, cur.sp}) & RAMW16;
                next.sp = (cur.sp - 1'b1) & 8'hFF;
                next.ada = stack_addr[14:0];
                next.din = cur.ra;
                next.cea = 1;
                next.v_cea = 0;
                next = return_to_opcode_fetch(next, cur.pc_plus1);
            end
            8'h68: begin  // PLA
                if (cur.fetched_data_bytes == 0) begin
                    new_sp = (cur.sp + 1'b1) & 8'hFF;
                    stack_addr = (STACK + {8'h00, new_sp}) & RAMW16;
                    next.sp = new_sp;
                    next = request_data_fetch(next, stack_addr);
                end else begin
                    next.ra = cur.dout_r;
                    next = update_logic_flags(next, next.ra);
                    next = return_to_opcode_fetch(next, cur.pc_plus1);
                end
            end
            8'h08: begin  // PHP
                status = {
                    cur.flg_n,
                    cur.flg_v,
                    1'b1,
                    cur.flg_b,
                    cur.flg_d,
                    cur.flg_i,
                    cur.flg_z,
                    cur.flg_c
                };
                stack_addr = (STACK + {8'h00, cur.sp}) & RAMW16;
                next.sp = (cur.sp - 1'b1) & 8'hFF;
                next.ada = stack_addr[14:0];
                next.din = status;
                next.cea = 1;
                next.v_cea = 0;
                next = return_to_opcode_fetch(next, cur.pc_plus1);
            end
            default: begin
                handled = 1'b0;
            end
        endcase
        return handled;
    endfunction

    function automatic logic calc_decode_adc_sbc_next(input cpu_ctx_t cur, ref cpu_ctx_t next);
        logic handled;
        logic [15:0] target_addr;
        logic [7:0] zp_addr;

        handled = 1'b1;
        unique case (cur.opcode)
            8'h69: begin  // ADC immediate
                next = complete_adc(cur, next, cur.operands[7:0], cur.pc_plus2);
            end
            8'h65: begin  // ADC zero page
                target_addr = {8'h00, cur.operands[7:0]};
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, target_addr);
                end else begin
                    next = complete_adc(cur, next, cur.dout_r, cur.pc_plus2);
                end
            end
            8'h75: begin  // ADC zero page, X
                zp_addr = cur.operands[7:0] + cur.rx;
                target_addr = {8'h00, zp_addr};
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, target_addr);
                end else begin
                    next = complete_adc(cur, next, cur.dout_r, cur.pc_plus2);
                end
            end
            8'h6D: begin  // ADC absolute
                target_addr = cur.operands & 16'hFFFF;
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, target_addr);
                end else begin
                    next = complete_adc(cur, next, cur.dout_r, cur.pc_plus3);
                end
            end
            8'h7D: begin  // ADC absolute, X
                target_addr = (cur.operands + {8'h00, cur.rx}) & 16'hFFFF;
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, target_addr);
                end else begin
                    next = complete_adc(cur, next, cur.dout_r, cur.pc_plus3);
                end
            end
            8'h79: begin  // ADC absolute, Y
                target_addr = (cur.operands + {8'h00, cur.ry}) & 16'hFFFF;
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, target_addr);
                end else begin
                    next = complete_adc(cur, next, cur.dout_r, cur.pc_plus3);
                end
            end
            8'h61: begin  // ADC (indirect, X)
                unique case (cur.fetched_data_bytes)
                    0: begin
                        zp_addr = cur.operands[7:0] + cur.rx;
                        target_addr = {8'h00, zp_addr};
                        next = request_data_fetch(next, target_addr);
                    end
                    1: begin
                        next.fetched_data[7:0] = cur.dout_r;
                        zp_addr = cur.operands[7:0] + cur.rx + 8'h01;
                        target_addr = {8'h00, zp_addr};
                        next = request_data_fetch(next, target_addr);
                    end
                    2: begin
                        target_addr = ({cur.dout_r, cur.fetched_data[7:0]}) & 16'hFFFF;
                        next = request_data_fetch(next, target_addr);
                    end
                    3: begin
                        next.fetched_data[15:8] = cur.dout_r;
                        next = complete_adc(cur, next, cur.dout_r, cur.pc_plus2);
                    end
                    default: begin
                        handled = 1'b0;
                    end
                endcase
            end
            8'h71: begin  // ADC (indirect), Y
                unique case (cur.fetched_data_bytes)
                    0: begin
                        target_addr = {8'h00, cur.operands[7:0]};
                        next = request_data_fetch(next, target_addr);
                    end
                    1: begin
                        next.fetched_data[7:0] = cur.dout_r;
                        target_addr = {8'h00, (cur.operands[7:0] + 8'h01) & 8'hFF};
                        next = request_data_fetch(next, target_addr);
                    end
                    2: begin
                        target_addr = ({cur.dout_r, cur.fetched_data[7:0]} + {8'h00, cur.ry}) & 16'hFFFF;
                        next = request_data_fetch(next, target_addr);
                    end
                    3: begin
                        next = complete_adc(cur, next, cur.dout_r, cur.pc_plus2);
                    end
                    default: begin
                        handled = 1'b0;
                    end
                endcase
            end
            8'hE9: begin  // SBC immediate
                next = complete_sbc(cur, next, cur.operands[7:0], cur.pc_plus2);
            end
            8'hE5: begin  // SBC zero page
                target_addr = {8'h00, cur.operands[7:0]};
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, target_addr);
                end else begin
                    next = complete_sbc(cur, next, cur.dout_r, cur.pc_plus2);
                end
            end
            8'hF5: begin  // SBC zero page, X
                zp_addr = cur.operands[7:0] + cur.rx;
                target_addr = {8'h00, zp_addr};
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, target_addr);
                end else begin
                    next = complete_sbc(cur, next, cur.dout_r, cur.pc_plus2);
                end
            end
            8'hED: begin  // SBC absolute
                target_addr = cur.operands & 16'hFFFF;
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, target_addr);
                end else begin
                    next = complete_sbc(cur, next, cur.dout_r, cur.pc_plus3);
                end
            end
            8'hFD: begin  // SBC absolute, X
                target_addr = (cur.operands + {8'h00, cur.rx}) & 16'hFFFF;
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, target_addr);
                end else begin
                    next = complete_sbc(cur, next, cur.dout_r, cur.pc_plus3);
                end
            end
            8'hF9: begin  // SBC absolute, Y
                target_addr = (cur.operands + {8'h00, cur.ry}) & 16'hFFFF;
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, target_addr);
                end else begin
                    next = complete_sbc(cur, next, cur.dout_r, cur.pc_plus3);
                end
            end
            8'hE1: begin  // SBC (indirect, X)
                unique case (cur.fetched_data_bytes)
                    0: begin
                        zp_addr = cur.operands[7:0] + cur.rx;
                        target_addr = {8'h00, zp_addr};
                        next = request_data_fetch(next, target_addr);
                    end
                    1: begin
                        next.fetched_data[7:0] = cur.dout_r;
                        zp_addr = cur.operands[7:0] + cur.rx + 8'h01;
                        target_addr = {8'h00, zp_addr};
                        next = request_data_fetch(next, target_addr);
                    end
                    2: begin
                        target_addr = ({cur.dout_r, cur.fetched_data[7:0]}) & 16'hFFFF;
                        next = request_data_fetch(next, target_addr);
                    end
                    3: begin
                        next = complete_sbc(cur, next, cur.dout_r, cur.pc_plus2);
                    end
                    default: begin
                        handled = 1'b0;
                    end
                endcase
            end
            8'hF1: begin  // SBC (indirect), Y
                unique case (cur.fetched_data_bytes)
                    0: begin
                        target_addr = {8'h00, cur.operands[7:0]};
                        next = request_data_fetch(next, target_addr);
                    end
                    1: begin
                        next.fetched_data[7:0] = cur.dout_r;
                        target_addr = {8'h00, (cur.operands[7:0] + 8'h01) & 8'hFF};
                        next = request_data_fetch(next, target_addr);
                    end
                    2: begin
                        target_addr = ({cur.dout_r, cur.fetched_data[7:0]} + {8'h00, cur.ry}) & 16'hFFFF;
                        next = request_data_fetch(next, target_addr);
                    end
                    3: begin
                        next = complete_sbc(cur, next, cur.dout_r, cur.pc_plus2);
                    end
                    default: begin
                        handled = 1'b0;
                    end
                endcase
            end
            default: begin
                handled = 1'b0;
            end
        endcase

        return handled;
    endfunction

    function automatic cpu_ctx_t complete_adc(input cpu_ctx_t cur, cpu_ctx_t next,
                                              logic [7:0] operand, logic [15:0] next_pc);
        logic [8:0] temp;
        temp = (cur.ra + operand + (cur.flg_c ? 1 : 0)) & 9'h1FF;
        next.flg_c = temp[8];
        next.flg_v = (~(cur.ra[7] ^ operand[7]) & (cur.ra[7] ^ temp[7])) ? 1 : 0;
        next.ra = temp[7:0];
        next = update_logic_flags(next, next.ra);
        next = return_to_opcode_fetch(next, next_pc);
        return next;
    endfunction

    function automatic cpu_ctx_t complete_sbc(input cpu_ctx_t cur, cpu_ctx_t next,
                                              logic [7:0] operand, logic [15:0] next_pc);
        logic [8:0] temp;
        temp = (cur.ra - operand - (cur.flg_c ? 0 : 1)) & 9'h1FF;
        next.flg_c = ~temp[8];
        next.flg_v = ((cur.ra[7] ^ operand[7]) & (cur.ra[7] ^ temp[7])) ? 1 : 0;
        next.ra = temp[7:0];
        next = update_logic_flags(next, next.ra);
        next = return_to_opcode_fetch(next, next_pc);
        return next;
    endfunction

    function automatic logic calc_decode_inc_dec_next(input cpu_ctx_t cur, ref cpu_ctx_t next);
        logic handled;
        logic [15:0] target_addr;
        logic [7:0] result;
        logic [7:0] zp_addr;

        handled = 1'b1;
        unique case (cur.opcode)
            8'hE6: begin  // INC zero page
                target_addr = {8'h00, cur.operands[7:0]};
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, target_addr);
                end else begin
                    result = cur.dout_r + 1'b1;
                    next   = update_logic_flags(next, result);
                    next   = apply_ram_write(next, target_addr, result);
                    next   = return_to_opcode_fetch(next, cur.pc_plus2);
                end
            end
            8'hF6: begin  // INC zero page, X
                zp_addr = cur.operands[7:0] + cur.rx;
                target_addr = {8'h00, zp_addr};
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, target_addr);
                end else begin
                    result = cur.dout_r + 1'b1;
                    next   = update_logic_flags(next, result);
                    next   = apply_ram_write(next, target_addr, result);
                    next   = return_to_opcode_fetch(next, cur.pc_plus2);
                end
            end
            8'hEE: begin  // INC absolute
                target_addr = cur.operands & RAMW16;
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, target_addr);
                end else begin
                    result = cur.dout_r + 1'b1;
                    next   = update_logic_flags(next, result);
                    next   = apply_ram_write(next, target_addr, result);
                    next   = return_to_opcode_fetch(next, cur.pc_plus3);
                end
            end
            8'hFE: begin  // INC absolute, X
                target_addr = (cur.operands + {8'h00, cur.rx}) & 16'hFFFF;
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, target_addr);
                end else begin
                    result = cur.dout_r + 1'b1;
                    next   = update_logic_flags(next, result);
                    next   = apply_ram_write(next, target_addr, result);
                    next   = return_to_opcode_fetch(next, cur.pc_plus3);
                end
            end
            8'hC6: begin  // DEC zero page
                target_addr = {8'h00, cur.operands[7:0]};
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, target_addr);
                end else begin
                    result = cur.dout_r - 1'b1;
                    next   = update_logic_flags(next, result);
                    next   = apply_ram_write(next, target_addr, result);
                    next   = return_to_opcode_fetch(next, cur.pc_plus2);
                end
            end
            8'hD6: begin  // DEC zero page, X
                zp_addr = cur.operands[7:0] + cur.rx;
                target_addr = {8'h00, zp_addr};
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, target_addr);
                end else begin
                    result = cur.dout_r - 1'b1;
                    next   = update_logic_flags(next, result);
                    next   = apply_ram_write(next, target_addr, result);
                    next   = return_to_opcode_fetch(next, cur.pc_plus2);
                end
            end
            8'hCE: begin  // DEC absolute
                target_addr = cur.operands & RAMW16;
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, target_addr);
                end else begin
                    result = cur.dout_r - 1'b1;
                    next   = update_logic_flags(next, result);
                    next   = apply_ram_write(next, target_addr, result);
                    next   = return_to_opcode_fetch(next, cur.pc_plus3);
                end
            end
            8'hDE: begin  // DEC absolute, X
                target_addr = (cur.operands + {8'h00, cur.rx}) & 16'hFFFF;
                if (cur.fetched_data_bytes == 0) begin
                    next = request_data_fetch(next, target_addr);
                end else begin
                    result = cur.dout_r - 1'b1;
                    next   = update_logic_flags(next, result);
                    next   = apply_ram_write(next, target_addr, result);
                    next   = return_to_opcode_fetch(next, cur.pc_plus3);
                end
            end
            8'hE8: begin  // INX
                next.rx = (cur.rx + 1'b1) & 8'hFF;
                next = update_logic_flags(next, next.rx);
                next = return_to_opcode_fetch(next, cur.pc_plus1);
            end
            8'hC8: begin  // INY
                next.ry = (cur.ry + 1'b1) & 8'hFF;
                next = update_logic_flags(next, next.ry);
                next = return_to_opcode_fetch(next, cur.pc_plus1);
            end
            8'hCA: begin  // DEX
                next.rx = (cur.rx - 1'b1) & 8'hFF;
                next = update_logic_flags(next, next.rx);
                next = return_to_opcode_fetch(next, cur.pc_plus1);
            end
            8'h88: begin  // DEY
                next.ry = (cur.ry - 1'b1) & 8'hFF;
                next = update_logic_flags(next, next.ry);
                next = return_to_opcode_fetch(next, cur.pc_plus1);
            end
            default: begin
                handled = 1'b0;
            end
        endcase

        return handled;
    endfunction

    function automatic cpu_ctx_t calc_cpu_next(input cpu_ctx_t cur, input cpu_in_t in);
        cpu_ctx_t  next = cur;
        fsm_next_t fsm;

        fsm = calc_boot_fetch_next(
            cur.state,
            cur.fetch_stage,
            cur.fetch_resume_state,
            cur.prev_state,
            in.dout,
            cur.boot_idx,
            in.boot_program_length,
            cur.boot_write,
            cur.v_ada,
            cur.show_info_counter,
            cur.show_info_stage,
            cur.show_info_cmd.mem_read
        );

        next.state = fsm.next_state;
        next.fetch_stage = fsm.next_fetch_stage;

        unique case (cur.state)
            INIT: begin
                next.v_cea = 0;
                next.boot_write = 1;
            end
            INIT_VRAM: begin
                next.v_cea = 1;
                next.v_din = cur.char_code;
                next.char_code = (cur.char_code < 8'h7F) ? (cur.char_code + 1'b1) & 8'hFF : 8'h20;
                if ({22'd0, cur.v_ada} <= (COLUMNS * ROWS)) begin
                    next.v_ada = (cur.v_ada + 1'b1) & VRAMW10;
                end else begin
                    next.v_cea = 0;
                end
            end
            INIT_RAM: begin
                if (cur.boot_write) begin
                    next.boot_write = 0;
                    next.cea = 1;
                    next.ada = (PROGRAM_START15 + cur.boot_idx) & RAMW15;
                    next.din = in.boot_byte;
                end else begin
                    next.cea = 0;
                    if ({1'b0, cur.boot_idx} == in.boot_program_length) begin
                        next.v_cea = 1;
                    end else begin
                        next.boot_idx   = (cur.boot_idx + 1'b1) & RAMW15;
                        next.boot_write = 1;
                    end
                end
            end
            FETCH_REQ: begin
                next.pc_plus1 = (cur.pc + 1'b1) & RAMW16;
                next.pc_plus2 = (cur.pc + 16'd2) & RAMW16;
                next.pc_plus3 = (cur.pc + 16'd3) & RAMW16;
            end
            FETCH_WAIT: begin
                if (cur.fetch_stage == FETCH_DATA) begin
                    next.fetched_data_bytes = cur.fetched_data_bytes + 1'b1;
                end
            end
            FETCH_RECV: begin
                unique case (cur.fetch_stage)
                    FETCH_OPCODE: begin
                        next.opcode = in.dout;
                        next.fetched_data_bytes = 0;
                        next.written_data_bytes = 0;
                        next.cea = 0;
                        next.v_cea = 0;
                        if (fsm.next_fetch_stage == FETCH_OPERAND1 || fsm.next_fetch_stage == FETCH_OPERAND1OF2) begin
                            next.adb = cur.pc_plus1[14:0] & RAMW15;
                        end
                    end
                    FETCH_OPERAND1: begin
                        next.operands[7:0] = in.dout;
                    end
                    FETCH_OPERAND1OF2: begin
                        next.operands[7:0] = in.dout;
                        next.adb = cur.pc_plus2[14:0] & RAMW15;
                    end
                    FETCH_OPERAND2: begin
                        next.operands[15:8] = in.dout;
                    end
                    default: begin
                        // Keep defaults.
                    end
                endcase
            end
            WRITE_REQ: begin
                next.written_data_bytes = cur.written_data_bytes + 1'b1;
                next.cea = 0;
                next.v_cea = 0;
            end
            DECODE_EXECUTE: begin
                logic handled;
                handled = calc_decode_transfers_next(cur, next);
                if (!handled) begin
                    handled = calc_decode_flags_custom_next(cur, next);
                end
                if (!handled) begin
                    handled = calc_decode_branches_next(cur, next);
                end
                if (!handled) begin
                    handled = calc_decode_compare_next(cur, next);
                end
                if (!handled) begin
                    handled = calc_decode_logic_next(cur, next);
                end
                if (!handled) begin
                    handled = calc_decode_shifts_next(cur, next);
                end
                if (!handled) begin
                    handled = calc_decode_load_store_next(cur, next);
                end
                if (!handled) begin
                    handled = calc_decode_store_next(cur, next);
                    if (handled) begin
                        next.fetched_data_bytes = 0;
                    end
                end
                if (!handled) begin
                    handled = calc_decode_control_flow_next(cur, next);
                end
                if (!handled) begin
                    handled = calc_decode_adc_sbc_next(cur, next);
                end
                if (!handled) begin
                    handled = calc_decode_inc_dec_next(cur, next);
                end
            end
            SHOW_INFO: begin
                next.show_info_counter = 0;
                next.show_info_stage = SHOW_INFO_FETCH;
                next.cea = 0;
                next.v_cea = 0;
            end
            SHOW_INFO2: begin
                if (cur.show_info_stage == SHOW_INFO_FETCH) begin
                    next.show_info_cmd = show_info_rom[cur.show_info_counter[9:0]];
                    next.show_info_stage = SHOW_INFO_EXECUTE;
                    next.v_cea = 0;
                    next.cea = 0;
                end else begin
                    automatic show_info_cmd_t cmd;
                    automatic logic [15:0] tmp_addr;
                    automatic logic [15:0] mem_addr;
                    automatic logic [15:0] shadow_addr;

                    cmd = cur.show_info_cmd;

                    if (cmd.vram_write) begin
                        next.v_ada = cmd.v_ada;
                        next.v_cea = 1;
                        shadow_addr = ({6'd0, cmd.v_ada} + SHADOW_VRAM_START16) & RAMW16;
                        next.ada    = shadow_addr[14:0];
                        next.cea   = 1;

                        unique case (cmd.v_din_t)
                            0: begin
                                next.v_din = cmd.v_din;
                                next.din   = cmd.v_din;
                            end
                            1: begin
                                unique case (cmd.v_din)
                                    0: begin
                                        next.v_din = to_hexchar(cur.dout_r[7:4]);
                                        next.din   = to_hexchar(cur.dout_r[7:4]);
                                    end
                                    1: begin
                                        next.v_din = to_hexchar(cur.dout_r[3:0]);
                                        next.din   = to_hexchar(cur.dout_r[3:0]);
                                    end
                                    2, 3: begin
                                        // No action.
                                    end
                                    default: begin
                                        next.v_din = cur.dout_r[11-cmd.v_din] ? 8'h40 : 8'h20;
                                        next.din   = cur.dout_r[11-cmd.v_din] ? 8'h40 : 8'h20;
                                    end
                                endcase
                            end
                            2: begin
                                next.v_din = cmd.v_din[0] ? to_hexchar(cur.ra[3:0]) :
                                    to_hexchar(cur.ra[7:4]);
                                next.din = cmd.v_din[0] ? to_hexchar(cur.ra[3:0]) :
                                    to_hexchar(cur.ra[7:4]);
                            end
                            3: begin
                                next.v_din = cmd.v_din[0] ? to_hexchar(cur.rx[3:0]) :
                                    to_hexchar(cur.rx[7:4]);
                                next.din = cmd.v_din[0] ? to_hexchar(cur.rx[3:0]) :
                                    to_hexchar(cur.rx[7:4]);
                            end
                            4: begin
                                next.v_din = cmd.v_din[0] ? to_hexchar(cur.ry[3:0]) :
                                    to_hexchar(cur.ry[7:4]);
                                next.din = cmd.v_din[0] ? to_hexchar(cur.ry[3:0]) :
                                    to_hexchar(cur.ry[7:4]);
                            end
                            5: begin
                                next.v_din = cmd.v_din[0] ? to_hexchar(cur.sp[3:0]) :
                                    to_hexchar(cur.sp[7:4]);
                                next.din = cmd.v_din[0] ? to_hexchar(cur.sp[3:0]) :
                                    to_hexchar(cur.sp[7:4]);
                            end
                            6: begin
                                unique case (cmd.v_din)
                                    0: begin
                                        next.v_din = to_hexchar(cur.pc[15:12]);
                                        next.din   = to_hexchar(cur.pc[15:12]);
                                    end
                                    1: begin
                                        next.v_din = to_hexchar(cur.pc[11:8]);
                                        next.din   = to_hexchar(cur.pc[11:8]);
                                    end
                                    2: begin
                                        next.v_din = to_hexchar(cur.pc[7:4]);
                                        next.din   = to_hexchar(cur.pc[7:4]);
                                    end
                                    3: begin
                                        next.v_din = to_hexchar(cur.pc[3:0]);
                                        next.din   = to_hexchar(cur.pc[3:0]);
                                    end
                                    default: begin
                                        // No action.
                                    end
                                endcase
                            end
                            7: begin
                                tmp_addr = cur.operands + {8'h00, cmd.diff};
                                unique case (cmd.v_din)
                                    0: begin
                                        next.v_din = to_hexchar(tmp_addr[15:12]);
                                        next.din   = to_hexchar(tmp_addr[15:12]);
                                    end
                                    1: begin
                                        next.v_din = to_hexchar(tmp_addr[11:8]);
                                        next.din   = to_hexchar(tmp_addr[11:8]);
                                    end
                                    2: begin
                                        next.v_din = to_hexchar(tmp_addr[7:4]);
                                        next.din   = to_hexchar(tmp_addr[7:4]);
                                    end
                                    3: begin
                                        next.v_din = to_hexchar(tmp_addr[3:0]);
                                        next.din   = to_hexchar(tmp_addr[3:0]);
                                    end
                                    default: begin
                                        // No action.
                                    end
                                endcase
                            end
                            default: begin
                                // No action.
                            end
                        endcase
                    end else begin
                        next.v_cea = 0;
                        next.cea   = 0;
                    end

                    if (cmd.mem_read) begin
                        if (cmd.v_din_t == 4'd8) begin
                            next.adb = {5'd0, cmd.v_ada};
                        end else begin
                            mem_addr = (cur.operands + {8'h00, cmd.diff}) & RAMW16;
                            next.adb = mem_addr[14:0] & RAMW15;
                        end
                        next.fetch_resume_state = SHOW_INFO2;
                    end

                    next.show_info_counter = cur.show_info_counter + 1'b1;

                    if (cur.show_info_counter == 32'd1020) begin
                        next.show_info_counter = 0;
                        next.operands[15:0] = 16'hFFFF;
                        next.v_cea = 0;
                        next.cea = 0;
                        next.show_info_stage = SHOW_INFO_FETCH;
                    end else begin
                        next.show_info_stage = SHOW_INFO_FETCH;
                    end
                end
            end
            CLEAR_VRAM: begin
                next.v_ada = 0;
                next.v_din = 8'h20;
                next.v_cea = 1;
                next.ada   = SHADOW_VRAM_START16[14:0] & RAMW15;
                next.din   = 8'h20;
                next.cea   = 1;
            end
            CLEAR_VRAM2: begin
                logic [15:0] shadow_addr;
                if ({22'd0, cur.v_ada} <= (COLUMNS * ROWS)) begin
                    next.v_ada = (cur.v_ada + 1'b1) & VRAMW10;
                    next.v_din = 8'h20;
                    next.v_cea = 1;
                    shadow_addr = ({6'd0, cur.v_ada} + SHADOW_VRAM_START16) & RAMW16;
                    next.ada    = shadow_addr[14:0];
                    next.din   = 8'h20;
                    next.cea   = 1;
                end else begin
                    next.pc = cur.pc_plus1;
                    next.adb = cur.pc_plus1[14:0] & RAMW15;
                    next.v_cea = 0;
                    next.cea = 0;
                end
            end
            default: begin
                // Keep defaults.
            end
        endcase

        return next;
    endfunction
endpackage
/* verilator lint_on UNUSEDSIGNAL */
