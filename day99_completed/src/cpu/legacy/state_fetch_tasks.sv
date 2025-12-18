task automatic state_fetch_req();
    begin
        // FETCH_REQ side effects are now driven by `next_ctx` (computed by `calc_cpu_next`).
        pc_plus1 <= next_ctx.pc_plus1;
        pc_plus2 <= next_ctx.pc_plus2;
        pc_plus3 <= next_ctx.pc_plus3;
    end
endtask

task automatic state_fetch_wait();
    begin
        // FETCH_WAIT side effects are now driven by `next_ctx` (computed by `calc_cpu_next`).
        fetched_data_bytes <= next_ctx.fetched_data_bytes;
    end
endtask

task automatic state_fetch_recv();
    begin
        // FETCH_RECV side effects are now driven by `next_ctx` (computed by `calc_cpu_next`).
        opcode             <= next_ctx.opcode;
        operands           <= next_ctx.operands;
        fetched_data_bytes <= next_ctx.fetched_data_bytes;
        written_data_bytes <= next_ctx.written_data_bytes;
        cea                <= next_ctx.cea;
        v_cea              <= next_ctx.v_cea;
        adb                <= next_ctx.adb;
    end
endtask
