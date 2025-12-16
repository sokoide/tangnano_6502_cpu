task automatic state_write_req_handler();
  begin
    written_data_bytes <= written_data_bytes + 1'd1;
    cea <= 0;
    v_cea <= 0;
  end
endtask
