// Day 18: System Integration - Logic Testbench
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

    initial begin
        $display("=== Day 18: System Integration Test ===");

        // Test program: Final showdown
        // LDA #$10, STA $20, JSR sub, HLT
        // sub: INC $20, RTS
        mem[16'h0200] = 8'hA9;
        mem[16'h0201] = 8'h10;
        mem[16'h0202] = 8'h85;
        mem[16'h0203] = 8'h20;
        mem[16'h0204] = 8'h20;
        mem[16'h0205] = 8'h08;
        mem[16'h0206] = 8'h80;
        mem[16'h0207] = 8'hEF;  // HLT

        mem[16'h0208] = 8'hE6;
        mem[16'h0209] = 8'h20;  // INC $20
        mem[16'h020A] = 8'h60;  // RTS

        clk = 0;
        rst_n = 0;
        pc_enable = 1;
        vsync = 0;
        #25;
        rst_n = 1;
        #20;

        // Execute until HLT
        repeat (30) @(posedge clk);
        #5;

        // Check if INC $20 worked (16 + 1 = 17, 0x11)
        if (mem[16'h0020] !== 8'h11) begin
            $display("FAIL: Final integration check failed, mem[0x20]=%h", mem[16'h0020]);
            error_count++;
        end else $display("PASS: Final integration results correct");

        // Final result
        $display("---------------------------------------");
        if (error_count == 0) $display("RESULT: ALL TESTS PASSED");
        else $display("RESULT: %0d TESTS FAILED", error_count);
        $display("---------------------------------------");
        $finish;
    end
endmodule
