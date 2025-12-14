task automatic state_clear_vram_init();
  begin
    vram_write(0, 8'h20);
  end
endtask

task automatic state_clear_vram_loop();
  begin
    if (v_ada <= COLUMNS * ROWS) begin
      v_ada <= (v_ada + 1) & VRAMW;
      v_din <= 8'h20;
      v_cea <= 1;
      ada   <= (v_ada + SHADOW_VRAM_START) & RAMW;
      din   <= 8'h20;
      cea   <= 1;
    end else begin
      pc <= pc_plus1;
      adb <= pc_plus1 & RAMW;
      v_cea <= 0;
      cea <= 0;
    end
  end
endtask
