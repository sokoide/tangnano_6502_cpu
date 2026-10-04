// Day 18: PLL LOCK write-gate Testbench
//
// Verifies the FPGA-branch memory-domain gating that `make test` cannot reach
// through lcd_demo (the LOCK logic lives inside the non-VERILATOR `else`
// branch). This bench wires the REAL boot_loader and REAL ram together with a
// verbatim copy of the LOCK synchronizer from lcd_demo.sv (locked_raw is driven
// by this bench in place of Gowin_rPLL40) and the same write-gate expression
// (`ram_we_final = mem_rst_n && ram_we`). Keep the copied block in sync with
// lcd_demo.sv when it changes.
//
// Contract under test:
//   1. While the PLL is unlocked (even with rst_n released), the held
//      boot_loader still asserts ram_we=1 combinationally (boot_done=0), and the
//      gate must block every RAM write.
//   2. After LOCK holds for 16 clocks, the boot copy completes and RAM matches
//      the ROM pattern.
//   3. When LOCK drops later, writes are blocked again after the 2-FF
//      synchronizer latency and RAM content stops changing.
//   4. Re-lock re-runs the boot copy.
`timescale 1ns / 1ps

module tb_lock_gate;

    logic MEMORY_CLK;
    logic rst_n;
    logic locked_raw;  // Testbench-driven stand-in for Gowin_rPLL40 .locked

    // 100MHz stand-in for the 27/40.5MHz MEMORY_CLK; functional check only.
    initial MEMORY_CLK = 1'b0;
    always #5 MEMORY_CLK = ~MEMORY_CLK;

    integer error_count = 0;

    initial begin
        #100000;  // 10000 cycles: far beyond the 2 boot copies tested here
        $fatal(1, "TIMEOUT: simulation did not finish");
    end

    task automatic check(input string name, input logic got, input logic exp);
        if (got !== exp) begin
            $display("FAIL: %s = %b (expected %b)", name, got, exp);
            error_count++;
        end else begin
            $display("PASS: %s = %b", name, got);
        end
    endtask

    task automatic check8(input string name, input logic [7:0] got, input logic [7:0] exp);
        if (got !== exp) begin
            $display("FAIL: %s = 0x%02h (expected 0x%02h)", name, got, exp);
            error_count++;
        end else begin
            $display("PASS: %s = 0x%02h", name, got);
        end
    endtask

    // 256-byte ROM pattern for the $0200 boot window (never zero).
    function automatic logic [7:0] rom_byte(input logic [15:0] addr);
        rom_byte = (addr[7:0] ^ 8'h5A) | 8'h80;
    endfunction

    // ---- LOCK synchronizer: verbatim copy of lcd_demo.sv (FPGA branch) ----
    logic locked_meta, locked_sync, lock_stable;
    logic [3:0] lock_count;
    wire mem_rst_n = rst_n && lock_stable;

    always_ff @(posedge MEMORY_CLK or negedge rst_n) begin
        if (!rst_n) begin
            locked_meta <= 1'b0;
            locked_sync <= 1'b0;
        end else begin
            locked_meta <= locked_raw;
            locked_sync <= locked_meta;
        end
    end

    always_ff @(posedge MEMORY_CLK or negedge rst_n) begin
        if (!rst_n) begin
            lock_count  <= 4'd0;
            lock_stable <= 1'b0;
        end else if (!locked_sync) begin
            lock_count  <= 4'd0;
            lock_stable <= 1'b0;
        end else if (lock_count != 4'd15) begin
            lock_count  <= lock_count + 1'b1;
            lock_stable <= 1'b0;
        end else begin
            lock_stable <= 1'b1;
        end
    end
    // ---- end of copied block ----

    // CPU-side stimulus (idle except during the lock-drop phase).
    logic [15:0] cpu_addr;
    logic [ 7:0] cpu_dout;
    logic        cpu_we;

    logic        cpu_rst_n;
    logic [15:0] rom_addr;
    logic [14:0] ram_addr;
    logic [ 7:0] ram_din;
    logic        ram_we;
    logic [ 7:0] rom_data;

    assign rom_data = rom_byte(rom_addr);

    boot_loader u_boot (
        .clk            (MEMORY_CLK),
        .rst_n          (mem_rst_n),
        .cpu_address_bus(cpu_addr),
        .cpu_data_out   (cpu_dout),
        .cpu_write_en   (cpu_we),
        .rom_data_out   (rom_data),
        .cpu_rst_n      (cpu_rst_n),
        .rom_addr       (rom_addr),
        .ram_addr       (ram_addr),
        .ram_din        (ram_din),
        .ram_we         (ram_we)
    );

    // Same gate expression as lcd_demo.sv: writes require LOCK-stable reset.
    logic ram_we_final;
    assign ram_we_final = mem_rst_n && ram_we;

    ram u_ram (
        .clk     (MEMORY_CLK),
        .addr    (ram_addr),
        .write_en(ram_we_final),
        .din     (ram_din),
        .dout    ()
    );

    integer we_pulse_count;

    always @(posedge MEMORY_CLK) begin
        if (ram_we_final) we_pulse_count = we_pulse_count + 1;
    end

    task automatic check_ram_window(input string name);
        integer i;
        integer fails;
        fails = 0;
        for (i = 0; i < 256; i++) begin
            if (u_ram.mem[16'h0200+i] !== rom_byte(16'h0200 + i)) begin
                $display("FAIL: %s: mem[$%04h] = %02h (expected %02h)", name, 16'h0200 + i,
                         u_ram.mem[16'h0200+i], rom_byte(16'h0200 + i));
                fails++;
            end
        end
        if (fails == 0) begin
            $display("PASS: %s: RAM $0200-$02FF matches ROM pattern", name);
        end else begin
            error_count = error_count + fails;
        end
    endtask

    initial begin
        integer i;
        $display("=== Day 18: PLL LOCK write-gate Test ===");

        for (i = 0; i < 256; i++) u_ram.mem[16'h0200+i] = 8'h00;
        we_pulse_count = 0;
        cpu_addr       = 16'h0000;
        cpu_dout       = 8'h00;
        cpu_we         = 1'b0;
        rst_n          = 1'b0;
        locked_raw     = 1'b0;

        // Phase 1: reset held.
        repeat (4) @(negedge MEMORY_CLK);
        check("mem_rst_n low during reset", mem_rst_n, 1'b0);

        // Phase 2: external reset released, PLL still unlocked.
        rst_n = 1'b1;
        repeat (40) @(negedge MEMORY_CLK);
        check("lock_stable stays low while unlocked", lock_stable, 1'b0);
        check("held boot_loader still asserts ram_we", u_boot.ram_we, 1'b1);
        check("write gate blocks boot writes while unlocked", ram_we_final, 1'b0);
        check("CPU stays in reset while unlocked", cpu_rst_n, 1'b0);
        check("no write pulses while unlocked", (we_pulse_count == 0), 1'b1);
        check8("RAM $0200 untouched while unlocked", u_ram.mem[16'h0200], 8'h00);

        // Phase 3: PLL locks; boot copy runs after 2FF + 16-clock stability.
        locked_raw = 1'b1;
        repeat (400) @(negedge MEMORY_CLK);
        check("lock_stable rises after 16 stable clocks", lock_stable, 1'b1);
        check("boot copy completed", u_boot.boot_done, 1'b1);
        check("CPU released after boot", cpu_rst_n, 1'b1);
        check_ram_window("after first boot");
        if (we_pulse_count < 256) begin
            $display("FAIL: only %0d write pulses seen (expected >= 256)", we_pulse_count);
            error_count++;
        end else begin
            $display("PASS: %0d write pulses observed during boot", we_pulse_count);
        end

        // Phase 4: LOCK drops after a successful boot. Writes must stop after
        // the 2-FF synchronizer latency (~2 clocks) and RAM must freeze.
        begin : lock_drop
            logic [7:0] keep0, keep1;
            keep0 = u_ram.mem[16'h0200];
            keep1 = u_ram.mem[16'h02FF];
            locked_raw = 1'b0;
            repeat (4) @(negedge MEMORY_CLK);  // past the synchronizer latency
            repeat (30) begin
                @(negedge MEMORY_CLK);
                if (ram_we_final !== 1'b0) begin
                    $display("FAIL: ram_we_final asserted after lock drop");
                    error_count++;
                end
            end
            if (error_count == 0) $display("PASS: writes blocked after lock drop");
            check8("RAM $0200 frozen after lock drop", u_ram.mem[16'h0200], keep0);
            check8("RAM $02FF frozen after lock drop", u_ram.mem[16'h02FF], keep1);
        end

        // Phase 5: LOCK returns; the boot copy re-runs and RAM stays valid.
        locked_raw = 1'b1;
        repeat (400) @(negedge MEMORY_CLK);
        check("boot copy re-runs after re-lock", u_boot.boot_done, 1'b1);
        check_ram_window("after re-lock");

        $display("---------------------------------------");
        if (error_count == 0) begin
            $display("RESULT: ALL TESTS PASSED");
            $finish;
        end else begin
            $fatal(1, "RESULT: %0d TESTS FAILED", error_count);
        end
    end

endmodule
