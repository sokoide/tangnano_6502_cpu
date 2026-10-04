// Day 18: PLL LOCK write-gate Testbench (real lcd_demo FPGA branch)
//
// Compiled with -UVERILATOR so lcd_demo.sv takes its FPGA (non-VERILATOR)
// branch: the REAL PLL LOCK synchronizer, write gate, boot_loader and RAM are
// simulated together. The Gowin primitives are replaced by the functional
// models in gowin_fpga_models.sv; the model's PLL LOCK input is driven
// hierarchically from this bench.
//
// Contract under test:
//   1. While the PLL is unlocked (even with rst_n released), the held
//      boot_loader still asserts ram_we=1 combinationally, and the lcd_demo
//      write gate must keep the RAM write port idle.
//   2. mem_rst_n must not release before the LOCK has been stable through the
//      2-FF synchronizer plus the 16-clock counter (no early release).
//   3. After LOCK the boot copy completes and the RAM boot window holds the
//      data the boot actually wrote.
//   4. When LOCK drops later, writes are blocked after the synchronizer
//      latency and RAM stops changing; the bench corrupts the window during
//      the block, and the re-lock boot copy must rewrite those bytes.
`timescale 1ns / 1ps

module tb_lock_gate;

    logic rst_n;
    logic XTAL_IN;

    lcd_demo u_dut (
        .rst_n  (rst_n),
        .XTAL_IN(XTAL_IN),
        .LCD_CLK(),
        .LCD_DEN(),
        .LCD_R  (),
        .LCD_G  (),
        .LCD_B  ()
    );

    initial XTAL_IN = 1'b0;
    always #5 XTAL_IN = ~XTAL_IN;

    integer error_count = 0;

    initial begin
        #2000000;  // 100k cycles: far beyond the phases tested here
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

    // Wait (bounded) until cond is true, counting posedges from the call.
    // cond must be by reference so the live signal value is re-evaluated.
    task automatic wait_pos(ref logic cond, input integer bound, input string what,
                            output integer edges);
        edges = 0;
        while (cond !== 1'b1 && edges < bound) begin
            @(posedge XTAL_IN);
            #1;
            edges++;
        end
        if (cond !== 1'b1) begin
            $display("FAIL: TIMEOUT: %s never became true", what);
            error_count++;
            edges = -1;
        end
    endtask

    initial begin
        integer i;
        integer edges;
        integer wc0, wc1;
        logic [7:0] garbage0, garbageff;
        $display("=== Day 18: PLL LOCK write-gate Test (lcd_demo FPGA branch) ===");

        rst_n = 1'b0;
        u_dut.pll40_inst.tb_locked = 1'b0;

        // Phase 1: external reset released, PLL still unlocked.
        repeat (4) @(negedge XTAL_IN);
        rst_n = 1'b1;
        repeat (40) @(negedge XTAL_IN);
        check("lock_stable stays low while unlocked", u_dut.lock_stable, 1'b0);
        check("mem_rst_n stays low while unlocked", u_dut.mem_rst_n, 1'b0);
        check("held boot_loader still asserts ram_we", u_dut.ram_we, 1'b1);
        check("write gate blocks boot writes while unlocked", u_dut.ram_we_final, 1'b0);
        check("CPU stays in reset while unlocked", u_dut.cpu_rst_n, 1'b0);
        check("no accepted RAM writes while unlocked", (u_dut.u_ram.ram_inst.write_count == 0),
              1'b1);

        // Phase 2: LOCK asserts. mem_rst_n must not release early: the earliest
        // legal release is 2FF + 16 counter clocks (>= 18 posedges).
        u_dut.pll40_inst.tb_locked = 1'b1;
        for_loop_2 :
        for (i = 1; i <= 17; i++) begin
            @(posedge XTAL_IN);
            #1;
            if (u_dut.lock_stable !== 1'b0) begin
                $display("FAIL: lock_stable released early, %0d posedges after LOCK", i);
                error_count++;
                disable for_loop_2;
            end
        end
        if (error_count == 0) $display("PASS: no release within 17 posedges of LOCK");
        wait_pos(u_dut.lock_stable, 6, "lock_stable after 16-clock stability", edges);
        if (edges > 0) $display("PASS: lock_stable released after %0d posedges", 17 + edges);
        check("mem_rst_n follows lock_stable", u_dut.mem_rst_n, 1'b1);

        // Phase 3: boot copy runs to completion on the LOCK-stable clock.
        wait_pos(u_dut.u_boot.boot_done, 2000, "boot_done", edges);
        wc0 = u_dut.u_ram.ram_inst.write_count;
        if (wc0 >= 256) begin
            $display("PASS: boot copy accepted %0d RAM writes", wc0);
        end else begin
            $display("FAIL: only %0d RAM writes accepted (expected >= 256)", wc0);
            error_count++;
        end
        check("boot wrote $0200 (captured)", u_dut.u_ram.ram_inst.cap0200_v, 1'b1);
        check8("RAM $0200 holds the booted byte", u_dut.u_ram.ram_inst.mem[15'h0200],
               u_dut.u_ram.ram_inst.cap0200);
        check("boot wrote $02FF (captured)", u_dut.u_ram.ram_inst.cap02ff_v, 1'b1);
        check8("RAM $02FF holds the booted byte", u_dut.u_ram.ram_inst.mem[15'h02FF],
               u_dut.u_ram.ram_inst.cap02ff);

        // Phase 4: LOCK drops. Writes must stop after the synchronizer latency
        // and RAM must freeze; then corrupt the boot window from this bench.
        u_dut.pll40_inst.tb_locked = 1'b0;
        repeat (4) @(negedge XTAL_IN);
        for (i = 0; i < 30; i++) begin
            @(negedge XTAL_IN);
            if (u_dut.ram_we_final !== 1'b0) begin
                $display("FAIL: ram_we_final asserted after lock drop");
                error_count++;
            end
        end
        if (error_count == 0) $display("PASS: writes blocked after lock drop");
        wc0 = u_dut.u_ram.ram_inst.write_count;
        repeat (10) @(negedge XTAL_IN);
        check("RAM write port idle while dropped", (u_dut.u_ram.ram_inst.write_count == wc0), 1'b1);
        garbage0 = ~u_dut.u_ram.ram_inst.cap0200;
        garbageff = ~u_dut.u_ram.ram_inst.cap02ff;
        u_dut.u_ram.ram_inst.mem[15'h0200] = garbage0;
        u_dut.u_ram.ram_inst.mem[15'h02FF] = garbageff;
        check8("bench corrupted RAM $0200", u_dut.u_ram.ram_inst.mem[15'h0200], garbage0);

        // Phase 5: LOCK returns. The boot copy must re-run and rewrite the
        // corrupted bytes (the captured data after re-copy proves the write).
        u_dut.pll40_inst.tb_locked = 1'b1;
        wait_pos(u_dut.lock_stable, 40, "lock_stable on re-lock", edges);
        wait_pos(u_dut.u_boot.boot_done, 2000, "boot_done on re-copy", edges);
        wc1 = u_dut.u_ram.ram_inst.write_count;
        if (wc1 - wc0 >= 256) begin
            $display("PASS: re-lock boot copy accepted %0d RAM writes", wc1 - wc0);
        end else begin
            $display("FAIL: only %0d writes on re-copy (expected >= 256)", wc1 - wc0);
            error_count++;
        end
        check8("RAM $0200 rewritten by re-copy", u_dut.u_ram.ram_inst.mem[15'h0200],
               u_dut.u_ram.ram_inst.cap0200);
        if (u_dut.u_ram.ram_inst.mem[15'h0200] === garbage0) begin
            $display("FAIL: RAM $0200 still holds the corrupted byte");
            error_count++;
        end else begin
            $display("PASS: corrupted RAM $0200 replaced");
        end
        check8("RAM $02FF rewritten by re-copy", u_dut.u_ram.ram_inst.mem[15'h02FF],
               u_dut.u_ram.ram_inst.cap02ff);

        $display("---------------------------------------");
        if (error_count == 0) begin
            $display("RESULT: ALL TESTS PASSED");
            $finish;
        end else begin
            $fatal(1, "RESULT: %0d TESTS FAILED", error_count);
        end
    end

endmodule
