task automatic state_write_req_handler();
    begin
        // WRITE_REQ side effects are now driven by `next_ctx` (computed by `calc_cpu_next`).
        written_data_bytes <= next_ctx.written_data_bytes;
        cea                <= next_ctx.cea;
        v_cea              <= next_ctx.v_cea;
    end
endtask
