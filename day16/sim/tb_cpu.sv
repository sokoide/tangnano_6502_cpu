// Day 16: Indexed Addressing (LDA/STA abs,X / LDA abs,Y) - Logic Testbench
`timescale 1ns / 1ps

module tb_cpu;
    logic clk;
    logic rst_n;
    logic pc_enable;
    logic [7:0] data_in;
    logic [7:0] data_out;
    logic write_en;
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
        .data_in(data_in),
        .data_out(data_out),
        .write_en(write_en),
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
        #200000;  // 10000 cycles
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

    initial begin
        $display("=== Day 16: Indexed Addressing Test ===");

        // Memory setup
        // $0200: LDX #$05
        // $0202: LDA $1000,X   ; read  mem[$1005] = 5A
        // $0205: LDA #$77
        // $0207: STA $1000,X   ; write mem[$1005] = 77
        // $020A: LDY #$05
        // $020C: LDA $1000,Y   ; read  mem[$1005] = 77
        // $020F: HLT
        mem[16'h0200] = 8'hA2;  // LDX imm
        mem[16'h0201] = 8'h05;
        mem[16'h0202] = 8'hBD;  // LDA abs,X
        mem[16'h0203] = 8'h00;  // low
        mem[16'h0204] = 8'h10;  // high
        mem[16'h0205] = 8'hA9;  // LDA imm
        mem[16'h0206] = 8'h77;
        mem[16'h0207] = 8'h9D;  // STA abs,X
        mem[16'h0208] = 8'h00;
        mem[16'h0209] = 8'h10;
        mem[16'h020A] = 8'hA0;  // LDY imm
        mem[16'h020B] = 8'h05;
        mem[16'h020C] = 8'hB9;  // LDA abs,Y
        mem[16'h020D] = 8'h00;
        mem[16'h020E] = 8'h10;
        mem[16'h020F] = 8'hEF;  // HLT

        // Seeded data for indexed read
        mem[16'h1005] = 8'h5A;

        clk = 0;
        rst_n = 0;
        pc_enable = 1;

        // Release reset on negedge
        @(negedge clk);
        rst_n = 1;

        // 1. LDX #$05
        wait_pc(16'h0202, 10, "LDX #$05");
        check8("debug_x after LDX #$05", debug_x, 8'h05);

        // 2. LDA $1000,X: indexed read -> mem[0x1005] = 0x5A
        wait_pc(16'h0205, 10, "LDA $1000,X");
        check8("debug_a after LDA $1000,X", debug_a, 8'h5A);

        // 3. LDA #$77
        wait_pc(16'h0207, 10, "LDA #$77");
        check8("debug_a after LDA #$77", debug_a, 8'h77);

        // 4. STA $1000,X: indexed write -> mem[0x1005] = 0x77
        wait_pc(16'h020A, 10, "STA $1000,X");
        check8("mem[0x1005] after STA $1000,X", mem[16'h1005], 8'h77);

        // 5. LDY #$05
        wait_pc(16'h020C, 10, "LDY #$05");
        check8("debug_y after LDY #$05", debug_y, 8'h05);

        // 6. LDA $1000,Y: indexed read with Y -> 0x77 (written in step 4)
        wait_pc(16'h020F, 10, "LDA $1000,Y");
        check8("debug_a after LDA $1000,Y", debug_a, 8'h77);

        // 7. HLT: PC must stay at 0x020F (post-posedge stability)
        repeat (3) begin
            @(posedge clk);
            #1;
        end
        if (debug_pc !== 16'h020F) begin
            $display("FAIL: debug_pc after HLT = 0x%04h (expected 0x020F)", debug_pc);
            error_count++;
        end else begin
            $display("PASS: debug_pc stays at 0x020F after HLT");
        end

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
