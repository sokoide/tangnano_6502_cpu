// cpu_fsm_next_pkg.sv - planned 2-process FSM next-state logic
//
// This package is a stepping stone toward the 2-process FSM described in `docs/FSM.md`.
// It provides "next-state only" logic (no side effects) so that:
// - `always_comb` can compute next state/stage deterministically
// - `always_ff` can perform registered side effects and state updates
//
// Note: this is not fully wired into `cpu.sv` yet. We will migrate state-by-state.

`include "consts_pkg.sv"

package cpu_fsm_next_pkg;
    import cpu_pkg::*;
    import cpu_types_pkg::*;
    import consts_pkg::*;

    typedef struct packed {
        cpu_state_e   next_state;
        fetch_stage_e next_fetch_stage;
    } fsm_next_t;

    function automatic logic uses_pure_next(input cpu_state_e state);
        unique case (state)
            // DECODE_EXECUTE still relies on legacy "next_state" writes from exec tasks.
            DECODE_EXECUTE: return 1'b0;
            default: return 1'b1;
        endcase
    endfunction

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
            next.adb = cur.pc_plus1[14:0] & RAMW;
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
            target = (cur.pc_plus2 + offset) & RAMW;
            if (branch_taken) begin
                next.pc  = target;
                next.adb = target[14:0];
            end else begin
                next.pc  = cur.pc_plus2;
                next.adb = cur.pc_plus2[14:0] & RAMW;
            end
            next.state = FETCH_REQ;
            next.fetch_stage = FETCH_OPCODE;
        end

        return handled;
    endfunction

    function automatic cpu_ctx_t request_data_fetch(cpu_ctx_t next, logic [15:0] target_addr);
        next.adb = target_addr & RAMW;
        next.state = FETCH_REQ;
        next.fetch_stage = FETCH_DATA;
        next.fetch_resume_state = DECODE_EXECUTE;
        return next;
    endfunction

    function automatic cpu_ctx_t return_to_opcode_fetch(cpu_ctx_t next, logic [15:0] next_pc);
        next.pc = next_pc;
        next.adb = next_pc & RAMW;
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
            next.v_ada = off32[9:0] & VRAMW;
            next.v_din = data;
            next.ada = shadow32[14:0] & RAMW;
            next.din = data;
            next.write_to_vram = 1'b1;
        end else begin
            next.ada = target_addr[14:0] & RAMW;
            next.din = data;
            next.write_to_vram = 1'b0;
        end
        return next;
    endfunction

    function automatic cpu_ctx_t store_and_fetch(cpu_ctx_t next, logic [15:0] target_addr,
                                                logic [7:0] data, logic [15:0] next_pc);
        next = apply_store_write(next, target_addr, data);
        next.cea   = 1;
        next.v_cea = next.write_to_vram;
        next = return_to_opcode_fetch(next, next_pc);
        return next;
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
                next.adb = cur.pc_plus1[14:0] & RAMW;
                next.state = FETCH_REQ;
                next.fetch_stage = FETCH_OPCODE;
            end
            8'hB8: begin  // CLV
                next.flg_v = 1'b0;
                next.pc = cur.pc_plus1;
                next.adb = cur.pc_plus1[14:0] & RAMW;
                next.state = FETCH_REQ;
                next.fetch_stage = FETCH_OPCODE;
            end
            8'h38: begin  // SEC
                next.flg_c = 1'b1;
                next.pc = cur.pc_plus1;
                next.adb = cur.pc_plus1[14:0] & RAMW;
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
                    next.adb = cur.pc_plus3[14:0] & RAMW;
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
                                next.adb = cur.pc_plus2[14:0] & RAMW;
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
                next.adb = cur.pc_plus2[14:0] & RAMW;
                next.state = FETCH_REQ;
                next.fetch_stage = FETCH_OPCODE;
            end
            8'hE0: begin  // CPX immediate
                result = cur.rx - cur.operands[7:0];
                next.flg_c = (cur.rx >= cur.operands[7:0]) ? 1 : 0;
                next.flg_z = (result == 8'h00);
                next.flg_n = result[7];
                next.pc = cur.pc_plus2;
                next.adb = cur.pc_plus2[14:0] & RAMW;
                next.state = FETCH_REQ;
                next.fetch_stage = FETCH_OPCODE;
            end
            8'hC0: begin  // CPY immediate
                result = cur.ry - cur.operands[7:0];
                next.flg_c = (cur.ry >= cur.operands[7:0]) ? 1 : 0;
                next.flg_z = (result == 8'h00);
                next.flg_n = result[7];
                next.pc = cur.pc_plus2;
                next.adb = cur.pc_plus2[14:0] & RAMW;
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
                next = store_and_fetch(next, {8'h00, cur.operands[7:0] + cur.rx}, cur.ra, cur.pc_plus2);
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
                next.char_code = (cur.char_code < 8'h7F) ? (cur.char_code + 1) & 8'hFF : 8'h20;
                if (cur.v_ada <= (COLUMNS * ROWS)) begin
                    next.v_ada = (cur.v_ada + 1) & VRAMW;
                end else begin
                    next.v_cea = 0;
                end
            end
            INIT_RAM: begin
                if (cur.boot_write) begin
                    next.boot_write = 0;
                    next.cea = 1;
                    next.ada = (PROGRAM_START + cur.boot_idx) & RAMW;
                    next.din = in.boot_byte;
                end else begin
                    next.cea = 0;
                    if (cur.boot_idx == in.boot_program_length) begin
                        next.v_cea = 1;
                    end else begin
                        next.boot_idx   = (cur.boot_idx + 1) & RAMW;
                        next.boot_write = 1;
                    end
                end
            end
            FETCH_REQ: begin
                next.pc_plus1 = (cur.pc + 16'd1) & RAMW;
                next.pc_plus2 = (cur.pc + 16'd2) & RAMW;
                next.pc_plus3 = (cur.pc + 16'd3) & RAMW;
            end
            FETCH_WAIT: begin
                if (cur.fetch_stage == FETCH_DATA) begin
                    next.fetched_data_bytes = cur.fetched_data_bytes + 1;
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
                            next.adb = cur.pc_plus1 & RAMW;
                        end
                    end
                    FETCH_OPERAND1: begin
                        next.operands[7:0] = in.dout;
                    end
                    FETCH_OPERAND1OF2: begin
                        next.operands[7:0] = in.dout;
                        next.adb = cur.pc_plus2 & RAMW;
                    end
                    FETCH_OPERAND2: begin
                        next.operands[15:8] = in.dout;
                    end
                    default: begin
                        // Keep defaults.
                    end
                endcase
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
                    handled = calc_decode_store_next(cur, next);
                    if (handled) begin
                        next.fetched_data_bytes = 0;
                    end
                end
            end
            default: begin
                // Keep defaults.
            end
        endcase

        return next;
    endfunction
endpackage
