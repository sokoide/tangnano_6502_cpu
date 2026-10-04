// Execute the actual hardware ROM through boot copy and synchronous RAM.
`timescale 1ns / 1ps
module tb_curriculum_rom #(
    parameter int TEST_DAY = 12
);
    logic clk = 0, rst_n = 0, cpu_rst_n;
    logic [15:0] address_bus, debug_pc, rom_addr;
    logic [14:0] ram_addr;
    logic [7:0] data_in, data_out, rom_data_out, ram_data_out, ram_din;
    logic [7:0] debug_a, debug_x, debug_y, debug_p, debug_s;
    logic write_en, ram_we;
    cpu dut (
        .clk(clk),
        .rst_n(cpu_rst_n),
        .pc_enable(1'b1),
        .address_bus(address_bus),
        .data_in(data_in),
        .data_out(data_out),
        .write_en(write_en),
        .debug_pc(debug_pc),
        .debug_a(debug_a),
        .debug_x(debug_x),
        .debug_y(debug_y),
        .debug_p(debug_p),
        .debug_s(debug_s)
    );
    rom u_rom (
        .addr(rom_addr),
        .data(rom_data_out)
    );
    ram u_ram (
        .clk(clk),
        .addr(ram_addr),
        .write_en(ram_we),
        .din(ram_din),
        .dout(ram_data_out)
    );
    boot_loader u_boot (
        .clk(clk),
        .rst_n(rst_n),
        .cpu_address_bus(address_bus),
        .cpu_data_out(data_out),
        .cpu_write_en(write_en),
        .rom_data_out(rom_data_out),
        .cpu_rst_n(cpu_rst_n),
        .rom_addr(rom_addr),
        .ram_addr(ram_addr),
        .ram_din(ram_din),
        .ram_we(ram_we)
    );
    assign data_in = address_bus[15] ? rom_data_out : ram_data_out;
    always #5 clk = ~clk;
    initial begin
        repeat (3) @(negedge clk);
        rst_n = 1;
        wait (cpu_rst_n);
        repeat (250) @(negedge clk);
        if (TEST_DAY == 12) begin
            assert (debug_pc == 16'h020A && debug_a == 8'hAA && u_ram.mem['h300] == 8'hAA)
            else $fatal(1, "Day12 ROM result PC=%h A=%h", debug_pc, debug_a);
            assert (u_ram.mem['h200] == 8'hA9)
            else $fatal(1, "Day12 must retain its first opcode");
        end else if (TEST_DAY == 15) begin
            assert (debug_pc == 16'h0212 && debug_x == 0 && debug_y == 8'hFF &&
                    u_ram.mem['h10] == 1)
            else $fatal(1, "Day15 ROM result PC=%h X=%h Y=%h", debug_pc, debug_x, debug_y);
        end else $fatal(1, "Unsupported TEST_DAY");
        repeat (10) begin
            @(negedge clk);
            assert (!write_en)
            else $fatal(1, "HLT must not write");
            assert (debug_pc == (TEST_DAY == 12 ? 16'h020A : 16'h0212))
            else $fatal(1, "HLT must hold PC");
        end
        $display("PASS: Day%0d hardware ROM boot/synchronous RAM/result/HLT", TEST_DAY);
        $finish;
    end
    initial begin
        #20000;
        $fatal(1, "ROM execution watchdog");
    end
endmodule
