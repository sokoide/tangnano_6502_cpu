// Day 18: Custom Instructions (WVS/CVR/IFO/HLT) - Logic Testbench
`timescale 1ns / 1ps

module tb_cpu;
    logic clk;
    logic rst_n;
    logic pc_enable;
    logic [7:0] data_in;
    logic [7:0] data_out;
    logic write_en;
    logic vsync;
    logic vram_clear;
    logic show_info;
    logic [15:0] address_bus;
    logic [15:0] debug_pc;
    logic [7:0] debug_a, debug_x, debug_y, debug_p, debug_s;

    // Memory model
    logic [7:0] mem[65536];
    assign data_in = mem[address_bus];

    // RAM write logic
    always @(posedge clk) begin
        if (write_en) mem[address_bus] <= data_out;
    end

    // Instance of CPU
    cpu dut (
        .clk(clk),
        .rst_n(rst_n),
        .pc_enable(pc_enable),
        .memory_hold(1'b0),
        .data_in(data_in),
        .data_out(data_out),
        .write_en(write_en),
        .vsync(vsync),
        .vram_clear(vram_clear),
        .show_info(show_info),
        .address_bus(address_bus),
        .debug_pc(debug_pc),
        .debug_a(debug_a),
        .debug_x(debug_x),
        .debug_y(debug_y),
        .debug_p(debug_p),
        .debug_s(debug_s)
    );

    // 50MHz clock
    always #10 clk = ~clk;

    integer error_count = 0;

    // Global watchdog: bounded completion
    initial begin
        #400000;  // 20000 cycles
        $fatal(1, "TIMEOUT: simulation did not finish");
    end

    // Wait (bounded) until PC reaches the target instruction boundary
    task automatic wait_pc(input logic [15:0] target, input integer bound, input string what);
        integer i;
        for (i = 0; i < bound; i++) begin
            @(posedge clk);
            #1;  // post-posedge sampling
            if (debug_pc === target) return;
        end
        $fatal(1, "TIMEOUT: %s: PC never reached 0x%04h (PC=0x%04h)", what, target, debug_pc);
    endtask

    task automatic check8(input string name, input logic [7:0] got, input logic [7:0] exp);
        if (got !== exp) begin
            $display("FAIL: %s = 0x%02h (expected 0x%02h)", name, got, exp);
            error_count++;
        end else begin
            $display("PASS: %s = 0x%02h", name, got, exp);
        end
    endtask

    task automatic check_bit(input string name, input logic got, input logic exp);
        if (got !== exp) begin
            $display("FAIL: %s = %b (expected %b)", name, got, exp);
            error_count++;
        end else begin
            $display("PASS: %s = %b", name, got, exp);
        end
    endtask

    // Drive one vsync rising edge (setup on negedge, released on negedge).
    // Returns right after the posedge that sampled vsync=1.
    task automatic vsync_edge();
        @(negedge clk);
        vsync = 1;
        @(posedge clk);
        #1;
        @(negedge clk);
        vsync = 0;
    endtask

    initial begin
        $display("=== Day 18: Custom Instructions (WVS/CVR/IFO/HLT) Test ===");

        // Memory setup
        // $0200: CVR         ; vram_clear pulse (1 cycle)
        // $0201: WVS #2      ; wait for 2 vsync rising edges
        // $0203: IFO         ; show_info pulse (1 cycle)
        // $0204: JSR $0210   ; subroutine: LDA #$37 / RTS (return to $0207)
        // $0207: HLT
        // Subroutine at $0210: LDA #$37 / RTS
        mem[16'h0200] = 8'hCF;  // CVR
        mem[16'h0201] = 8'hFF;  // WVS
        mem[16'h0202] = 8'h02;  // wait count = 2
        mem[16'h0203] = 8'hDF;  // IFO
        mem[16'h0204] = 8'h20;  // JSR $0210
        mem[16'h0205] = 8'h10;  // low
        mem[16'h0206] = 8'h02;  // high (0x02: RAM program space, not 0x80)
        mem[16'h0207] = 8'hEF;  // HLT
        mem[16'h0210] = 8'hA9;  // LDA imm (subroutine)
        mem[16'h0211] = 8'h37;
        mem[16'h0212] = 8'h60;  // RTS

        clk = 0;
        rst_n = 0;
        pc_enable = 1;
        vsync = 0;

        // Reset state check: custom outputs must be 0 during reset
        @(posedge clk);
        #1;
        check_bit("vram_clear (reset)", vram_clear, 1'b0);
        check_bit("show_info (reset)", show_info, 1'b0);

        // Release reset on negedge
        @(negedge clk);
        rst_n = 1;

        // 1. CVR: vram_clear must assert for exactly one cycle
        wait_pc(16'h0201, 10, "CVR");
        check_bit("vram_clear during CVR cycle", vram_clear, 1'b1);
        @(posedge clk);
        #1;
        check_bit("vram_clear after CVR cycle", vram_clear, 1'b0);

        // 2. WVS #2: PC must hold at 0x0202 until 2 vsync rising edges
        wait_pc(16'h0202, 10, "WVS operand fetch");
        wait (dut.state == dut.STATE_WAIT_VSYNC);
        @(negedge clk);
        #1;  // Watchdog bounds the wait; event stimulus starts after WVS is active
        if (debug_pc !== 16'h0202) begin
            $display("FAIL: PC left 0x0202 before vsync edges (PC=0x%04h)", debug_pc);
            error_count++;
        end else begin
            $display("PASS: PC holds at 0x0202 while waiting for vsync");
        end
        // 1st rising edge: still waiting for the 2nd edge
        vsync_edge();
        repeat (3) begin
            @(posedge clk);
            #1;
        end
        if (debug_pc !== 16'h0202) begin
            $display("FAIL: PC advanced after only 1 of 2 vsync edges (PC=0x%04h)", debug_pc);
            error_count++;
        end else begin
            $display("PASS: PC holds at 0x0202 after 1st vsync edge");
        end
        // 2nd rising edge: WVS completes at this posedge (PC -> 0x0203)
        @(negedge clk);
        vsync = 1;
        @(posedge clk);
        #1;  // post-posedge: the WVS exit update is now visible
        if (debug_pc !== 16'h0203) begin
            $display("FAIL: PC = 0x%04h after 2nd vsync edge (expected 0x0203)", debug_pc);
            error_count++;
        end else begin
            $display("PASS: WVS #2 completed, PC advanced to 0x0203");
        end
        @(negedge clk);
        vsync = 0;

        // 3. IFO: show_info must assert for exactly one cycle
        wait_pc(16'h0204, 10, "IFO");
        check_bit("show_info during IFO cycle", show_info, 1'b1);
        @(posedge clk);
        #1;
        check_bit("show_info after IFO cycle", show_info, 1'b0);

        // 4. JSR $0210 (high byte 0x02): subroutine LDA #$37, RTS returns to $0207
        wait_pc(16'h0210, 15, "JSR $0210");
        check8("debug_s after JSR", debug_s, 8'hFD);
        check8("mem[0x01FF] after JSR (PCH)", mem[16'h01FF], 8'h02);
        check8("mem[0x01FE] after JSR (PCL)", mem[16'h01FE], 8'h06);
        wait_pc(16'h0207, 15, "RTS");
        check8("debug_a after subroutine LDA #$37", debug_a, 8'h37);
        check8("debug_s after RTS", debug_s, 8'hFF);

        // 5. HLT: PC must stay at 0x0207 (post-posedge stability)
        repeat (3) begin
            @(posedge clk);
            #1;
        end
        if (debug_pc !== 16'h0207) begin
            $display("FAIL: debug_pc after HLT = 0x%04h (expected 0x0207)", debug_pc);
            error_count++;
        end else begin
            $display("PASS: debug_pc stays at 0x0207 after HLT");
        end
        check_bit("vram_clear after HLT", vram_clear, 1'b0);
        check_bit("show_info after HLT", show_info, 1'b0);

        // Final result
        $display("---------------------------------------");
        if (error_count == 0) begin
            $display("RESULT: ALL TESTS PASSED");
            $finish;
        end else begin
            $fatal(1, "RESULT: %0d TESTS FAILED", error_count);
        end
    end

endmodule
