task automatic state_decode_execute();
    begin
        cea = 0;
        v_cea = 0;
        write_to_vram = 0;  // Clear flag unless set by sta_write below

        /* verilator lint_off BLKSEQ */
        /* verilator lint_off UNUSEDSIGNAL */
        begin
            logic transfers_handled;
            logic flags_custom_handled;
            logic branches_handled;
            logic compare_handled;
            logic logic_handled;
            logic shifts_handled;
            logic store_handled;
            logic inc_dec_handled;
            logic control_flow_handled;
            logic load_store_handled;
            logic adc_sbc_handled;
            transfers_handled = 1'b0;
            flags_custom_handled = 1'b0;
            branches_handled = 1'b0;
            compare_handled = 1'b0;
            logic_handled = 1'b0;
            shifts_handled = 1'b0;
            store_handled = 1'b0;
            inc_dec_handled = 1'b0;
            control_flow_handled = 1'b0;
            load_store_handled = 1'b0;
            adc_sbc_handled = 1'b0;
            cpu_exec_transfers_pkg::exec_transfers(opcode, ra, rx, ry, sp, flg_z, flg_n, pc,
                                                   pc_plus1, adb, state, fetch_stage,
                                                   transfers_handled);

            if (!transfers_handled) begin
                cpu_exec_flags_custom_pkg::exec_flags_custom(
                    opcode, flg_c, flg_v, operands, show_info_counter, prev_state, state,
                    show_info_stage, vsync_stage, vsync_sync, pc, pc_plus1, pc_plus2, pc_plus3, adb,
                    fetch_stage, flags_custom_handled);
            end

            if (!transfers_handled && !flags_custom_handled) begin
                cpu_exec_branches_pkg::exec_branches(opcode, flg_c, flg_z, flg_v, flg_n, operands,
                                                     s_imm8, s_offset, addr, pc, pc_plus2, adb,
                                                     state, fetch_stage, branches_handled);
            end

            if (!transfers_handled && !flags_custom_handled && !branches_handled) begin
                cpu_exec_compare_pkg::exec_compare(opcode, ra, rx, ry, flg_c, flg_z, flg_v, flg_n,
                                                   operands, fetched_data_bytes, fetched_data,
                                                   dout_r, pc, pc_plus2, pc_plus3, adb, state,
                                                   fetch_stage, next_state, compare_handled);
            end

            if (!transfers_handled && !flags_custom_handled && !branches_handled && !compare_handled) begin
                cpu_exec_logic_pkg::exec_logic(opcode, ra, rx, ry, flg_z, flg_n, operands,
                                               fetched_data_bytes, fetched_data, dout_r, pc,
                                               pc_plus2, pc_plus3, adb, state, fetch_stage,
                                               next_state, logic_handled);
            end

            if (!transfers_handled && !flags_custom_handled && !branches_handled && !compare_handled && !logic_handled) begin
                cpu_exec_shifts_pkg::exec_shifts(opcode, ra, rx, flg_c, flg_z, flg_n, operands,
                                                 fetched_data_bytes, dout_r, pc, pc_plus1, pc_plus2,
                                                 pc_plus3, ada, din, adb, cea, v_cea, state,
                                                 fetch_stage, next_state, shifts_handled);
            end

            if (!transfers_handled && !flags_custom_handled && !branches_handled && !compare_handled && !logic_handled && !shifts_handled) begin
                cpu_exec_store_pkg::exec_store(opcode, ra, rx, ry, operands, fetched_data_bytes,
                                               fetched_data, dout_r, v_ada, v_din, v_cea, ada, din,
                                               cea, write_to_vram, pc, pc_plus1, pc_plus2, pc_plus3,
                                               adb, state, fetch_stage, next_state, store_handled);
            end

            if (!transfers_handled && !flags_custom_handled && !branches_handled && !compare_handled && !logic_handled && !shifts_handled && !store_handled) begin
                cpu_exec_inc_dec_pkg::exec_inc_dec(opcode, rx, ry, flg_z, flg_n, operands,
                                                   fetched_data_bytes, dout_r, adb, ada, din, cea,
                                                   v_cea, pc, pc_plus1, pc_plus2, pc_plus3, state,
                                                   fetch_stage, next_state, inc_dec_handled);
            end

            if (!transfers_handled && !flags_custom_handled && !branches_handled && !compare_handled
            && !logic_handled && !shifts_handled && !store_handled && !inc_dec_handled) begin
                cpu_exec_control_flow_pkg::exec_control_flow(
                    opcode, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage, next_state,
                    operands, fetched_data_bytes, fetched_data, dout_r, written_data_bytes, sp, ada,
                    din, cea, v_cea, ra, flg_c, flg_z, flg_i, flg_d, flg_b, flg_v, flg_n,
                    control_flow_handled);
            end

            if (!transfers_handled && !flags_custom_handled && !branches_handled && !compare_handled
            && !logic_handled && !shifts_handled && !store_handled && !inc_dec_handled
            && !control_flow_handled) begin
                cpu_exec_load_store_pkg::exec_load_store(
                    opcode, ra, rx, ry, flg_z, flg_n, operands, fetched_data_bytes, fetched_data,
                    dout_r, pc, pc_plus1, pc_plus2, pc_plus3, adb, state, fetch_stage, next_state,
                    load_store_handled);
            end

            if (!transfers_handled && !flags_custom_handled && !branches_handled && !compare_handled
            && !logic_handled && !shifts_handled && !store_handled && !inc_dec_handled
            && !control_flow_handled && !load_store_handled) begin
                cpu_exec_adc_sbc_pkg::exec_adc_sbc(opcode, ra, rx, ry, flg_c, flg_v, flg_z, flg_n,
                                                   operands, fetched_data_bytes, fetched_data,
                                                   dout_r, pc, pc_plus1, pc_plus2, pc_plus3, adb,
                                                   state, fetch_stage, next_state, adc_sbc_handled);
            end

            if (!transfers_handled && !flags_custom_handled && !branches_handled && !compare_handled
            && !logic_handled && !shifts_handled && !store_handled && !inc_dec_handled
            && !control_flow_handled && !load_store_handled && !adc_sbc_handled) begin
                case (opcode)
                    /* verilator lint_off VARHIDDEN */
                    /* verilator lint_on VARHIDDEN */
                    // support more instructions here

                    default: ;  // No operation.
                endcase
            end
        end
        /* verilator lint_on UNUSEDSIGNAL */
        /* verilator lint_on BLKSEQ */
    end
endtask
