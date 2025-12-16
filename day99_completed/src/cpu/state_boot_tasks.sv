task automatic state_boot_init();
  begin
    // INIT state side effects are now driven by `next_ctx` (computed by `calc_cpu_next`).
    v_cea      <= next_ctx.v_cea;
    boot_write <= next_ctx.boot_write;
  end
endtask

task automatic state_boot_init_vram();
  begin
    // INIT_VRAM state side effects are now driven by `next_ctx` (computed by `calc_cpu_next`).
    v_cea     <= next_ctx.v_cea;
    v_din     <= next_ctx.v_din;
    v_ada     <= next_ctx.v_ada;
    char_code <= next_ctx.char_code;
  end
endtask

task automatic state_boot_init_ram();
  begin
    // INIT_RAM state side effects are now driven by `next_ctx` (computed by `calc_cpu_next`).
    boot_write <= next_ctx.boot_write;
    cea        <= next_ctx.cea;
    ada        <= next_ctx.ada;
    din        <= next_ctx.din;
    boot_idx   <= next_ctx.boot_idx;
    v_cea      <= next_ctx.v_cea;
  end
endtask

task automatic state_boot_halt();
  begin
    // HALT keeps the CPU idle with state HALT.
  end
endtask
