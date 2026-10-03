`timescale 1ns / 1ps

// Fixed-byte diagnostic test: boot load, arithmetic, two IFO passes, WVS, HLT.
module tb_diag_simple5;
    import cpu_pkg::*;

    localparam int PROG_LEN = 27;
    localparam int CYCLE_LIMIT = 20000;
    localparam logic [7:0] PROG[0:PROG_LEN-1] = '{
        8'hCF,
        8'hA9,
        8'h20,
        8'h85,
        8'h01,
        8'h18,
        8'h69,
        8'h01,
        8'h85,
        8'h02,
        8'hC9,
        8'h7F,
        8'h08,
        8'h68,
        8'h85,
        8'h03,
        8'hA5,
        8'h02,
        8'hDF,
        8'h00,
        8'h02,
        8'hFF,
        8'hF0,
        8'hDF,
        8'h00,
        8'h00,
        8'hEF
    };

    logic clk = 0;
    logic rst_n = 0;
    logic vsync = 0;
    logic [7:0] dout;
    logic [7:0] din;
    logic [14:0] ada, adb;
    logic cea, ceb;
    logic [9:0] v_ada;
    logic v_cea;
    logic [7:0] v_din;
    logic [7:0] boot_program[7680];
    logic [15:0] boot_program_length;

    cpu dut (
        .clk(clk),
        .rst_n(rst_n),
        .dout(dout),
        .din(din),
        .ada(ada),
        .adb(adb),
        .cea(cea),
        .ceb(ceb),
        .v_ada(v_ada),
        .v_cea(v_cea),
        .v_din(v_din),
        .vsync(vsync),
        .boot_program(boot_program),
        .boot_program_length(boot_program_length)
    );

    // One-clock synchronous read, matching the CPU-facing BSRAM contract.
    logic [7:0] ram[0:32767];
    logic [7:0] dout_q;
    always_ff @(posedge clk) begin
        if (rst_n && cea) ram[ada] <= din;
        if (ceb) dout_q <= ram[adb];
    end
    assign dout = dout_q;

    always #5 clk = ~clk;
    // A 40-cycle frame is needed: $F0 waits >240 rising edges, so 100-cycle
    // frames alone would exceed the 20,000-cycle diagnostic bound.
    initial
        forever begin
            #380 vsync = 1;
            #20 vsync = 0;
        end

    initial begin
        int cycles;
        bit saw_first_ifo;
        bit saw_second_ifo;

        for (int i = 0; i < 32768; i++) ram[i] = 8'hCC;
        for (int i = 0; i < 7680; i++) boot_program[i] = 8'hEA;
        for (int i = 0; i < PROG_LEN; i++) boot_program[i] = PROG[i];
        boot_program_length = 16'(PROG_LEN);

        repeat (4) @(negedge clk);
        rst_n = 1;
        saw_first_ifo = 0;
        saw_second_ifo = 0;

        for (cycles = 0; cycles < CYCLE_LIMIT; cycles++) begin
            @(negedge clk);
            if (dut.cur.pc == 16'h0212 && dut.cur.state == SHOW_INFO) saw_first_ifo = 1;
            if (dut.cur.pc == 16'h0217 && dut.cur.state == SHOW_INFO) saw_second_ifo = 1;
            if (dut.cur.state == HALT) break;
            if (dut.cur.state == FAULT)
                $fatal(
                    1, "diagnostic fault at pc=%04x reason=%0d", dut.cur.pc, dut.cur.fault_reason
                );
        end

        if (cycles == CYCLE_LIMIT)
            $fatal(1, "diagnostic timeout at pc=%04x state=%0d", dut.cur.pc, dut.cur.state);
        if (!saw_first_ifo || !saw_second_ifo)
            $fatal(1, "missing IFO pass: first=%0d second=%0d", saw_first_ifo, saw_second_ifo);
        if (dut.cur.ra !== 8'h21 || ram[1] !== 8'h20 || ram[2] !== 8'h21 || ram[3] !== 8'hB0)
            $fatal(
                1, "result A=%02x RAM[01..03]=%02x %02x %02x", dut.cur.ra, ram[1], ram[2], ram[3]
            );
        for (int i = 0; i < PROG_LEN; i++) begin
            if (ram[16'h0200+i] !== PROG[i])
                $fatal(
                    1,
                    "boot readback $%04x=%02x expected=%02x",
                    16'h0200 + i,
                    ram[16'h0200+i],
                    PROG[i]
                );
        end
        $display("PASS diag_simple5: %0d cycles, A=21, RAM[01..03]=20 21 B0, boot=%0d bytes",
                 cycles, PROG_LEN);
        $finish;
    end
endmodule
