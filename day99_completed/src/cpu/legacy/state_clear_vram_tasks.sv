task automatic state_clear_vram_init();
    begin
        // CLEAR_VRAM side effects are now driven by `next_ctx` (computed by `calc_cpu_next`).
        v_ada <= next_ctx.v_ada;
        v_din <= next_ctx.v_din;
        v_cea <= next_ctx.v_cea;
        ada   <= next_ctx.ada;
        din   <= next_ctx.din;
        cea   <= next_ctx.cea;
    end
endtask

task automatic state_clear_vram_loop();
    begin
        // CLEAR_VRAM2 side effects are now driven by `next_ctx` (computed by `calc_cpu_next`).
        v_ada <= next_ctx.v_ada;
        v_din <= next_ctx.v_din;
        v_cea <= next_ctx.v_cea;
        ada   <= next_ctx.ada;
        din   <= next_ctx.din;
        cea   <= next_ctx.cea;
        pc    <= next_ctx.pc;
        adb   <= next_ctx.adb;
    end
endtask
