task automatic state_boot_init();
  begin
    v_cea <= 0;  // VRAM write disable
    boot_write <= 1;
    next_state = INIT_RAM;
  end
endtask

task automatic state_boot_init_vram();
  begin
    v_cea <= 1;  // VRAM write enable
    v_din <= char_code;
    char_code <= (char_code < 8'h7F) ? (char_code + 1) & 8'hFF : 8'h20;

    if (v_ada <= COLUMNS * ROWS) begin
      v_ada <= (v_ada + 1) & VRAMW;
    end else begin
      v_cea <= 0;  // VRAM write disable
      next_state = HALT;
    end
  end
endtask

task automatic state_boot_init_ram();
  begin
    if (boot_write) begin
      boot_write <= 0;
      cea <= 1;  // RAM write enable
      ada <= (PROGRAM_START + boot_idx) & RAMW;
      din <= boot_program[boot_idx];
    end else begin
      cea <= 0;
      if (boot_idx == boot_program_length) begin
        v_cea <= 1;  // VRAM write enable
        next_state = FETCH_REQ;
        next_fetch_stage = FETCH_OPCODE;
      end else begin
        boot_idx   <= (boot_idx + 1) & RAMW;
        boot_write <= 1;
      end
    end
  end
endtask

task automatic state_boot_halt();
  begin
    // HALT keeps the CPU idle with state HALT.
  end
endtask
