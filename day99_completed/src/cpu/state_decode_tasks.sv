task automatic state_decode_execute();
  begin
    // DECODE_EXECUTE is now driven by the combinational next-context.
    // `next_ctx` is computed in `cpu.sv` (always_comb) via `calc_cpu_next(cur,in)`.
    ra                 <= next_ctx.ra;
    rx                 <= next_ctx.rx;
    ry                 <= next_ctx.ry;
    sp                 <= next_ctx.sp;
    flg_c              <= next_ctx.flg_c;
    flg_z              <= next_ctx.flg_z;
    flg_i              <= next_ctx.flg_i;
    flg_d              <= next_ctx.flg_d;
    flg_b              <= next_ctx.flg_b;
    flg_v              <= next_ctx.flg_v;
    flg_n              <= next_ctx.flg_n;
    pc                 <= next_ctx.pc;
    pc_plus1           <= next_ctx.pc_plus1;
    pc_plus2           <= next_ctx.pc_plus2;
    pc_plus3           <= next_ctx.pc_plus3;
    adb                <= next_ctx.adb;
    ada                <= next_ctx.ada;
    din                <= next_ctx.din;
    cea                <= next_ctx.cea;
    ceb                <= next_ctx.ceb;
    v_ada              <= next_ctx.v_ada;
    v_din              <= next_ctx.v_din;
    v_cea              <= next_ctx.v_cea;
    write_to_vram      <= next_ctx.write_to_vram;
    opcode             <= next_ctx.opcode;
    operands           <= next_ctx.operands;
    fetched_data       <= next_ctx.fetched_data;
    fetched_data_bytes <= next_ctx.fetched_data_bytes;
    written_data_bytes <= next_ctx.written_data_bytes;
    char_code          <= next_ctx.char_code;
    counter            <= next_ctx.counter;
    boot_idx           <= next_ctx.boot_idx;
    boot_write         <= next_ctx.boot_write;
    fetch_resume_state <= next_ctx.fetch_resume_state;
    prev_state         <= next_ctx.prev_state;
    show_info_counter  <= next_ctx.show_info_counter;
    show_info_cmd      <= next_ctx.show_info_cmd;
    show_info_stage    <= next_ctx.show_info_stage;
    vsync_stage        <= next_ctx.vsync_stage;

    next_state = next_ctx.state;
    next_fetch_stage = next_ctx.fetch_stage;
  end
endtask
