task automatic state_show_info_init();
  begin
    // SHOW_INFO side effects are now driven by `next_ctx` (computed by `calc_cpu_next`).
    show_info_counter <= next_ctx.show_info_counter;
    show_info_stage   <= next_ctx.show_info_stage;
    cea               <= next_ctx.cea;
    v_cea             <= next_ctx.v_cea;
  end
endtask

task automatic state_show_info_step();
  begin
    // SHOW_INFO2 side effects are now driven by `next_ctx` (computed by `calc_cpu_next`).
    show_info_cmd      <= next_ctx.show_info_cmd;
    show_info_stage    <= next_ctx.show_info_stage;
    show_info_counter  <= next_ctx.show_info_counter;
    operands           <= next_ctx.operands;

    v_ada              <= next_ctx.v_ada;
    v_din              <= next_ctx.v_din;
    v_cea              <= next_ctx.v_cea;
    ada                <= next_ctx.ada;
    din                <= next_ctx.din;
    cea                <= next_ctx.cea;

    adb                <= next_ctx.adb;
    fetch_resume_state <= next_ctx.fetch_resume_state;
  end
endtask
