// A combinational fixture ROM supplies a program; CPU/RAM/top/VRAM are real.
`timescale 1ns / 1ps
module rom (
    input  logic [15:0] addr,
    output logic [ 7:0] data
);
    bit MULTIPLE = 0;  // Fixture selection is fixed before reset release.
    function automatic logic [7:0] expected(input logic [15:0] a);
        case (a)
            'h200:   expected = 'ha9;
            'h201:   expected = 'hab;  // LDA #AB
            'h202:   expected = 'h85;
            'h203:   expected = 'h00;  // STA 00
            'h204:   expected = 'ha9;
            'h205:   expected = 'h12;  // LDA #12
            'h206:   expected = 'h85;
            'h207:   expected = 'h01;  // STA 01
            'h208:   expected = 'hcf;  // CVR
            'h209:   expected = 'hdf;  // IFO
            'h20a:   expected = 'ha9;
            'h20b:   expected = 'h55;
            'h20c:   expected = 'h85;
            'h20d:   expected = 'h02;  // store after debug release
            'h20e:   expected = MULTIPLE ? 8'hdf : 8'hef;
            'h20f:   expected = MULTIPLE ? 8'hcf : 8'hea;
            'h210:   expected = MULTIPLE ? 8'hdf : 8'hea;
            'h211:   expected = 'hef;
            default: expected = 'hea;
        endcase
    endfunction
    assign data = expected(addr);
endmodule
module tb_day18_integration #(
    parameter bit RESET_DURING_INFO = 0,
    parameter bit REPEAT_REQUESTS   = 0
);
    logic rst_n = 0, XTAL_IN = 0, LCD_CLK, LCD_DEN;
    logic [4:0] LCD_R, LCD_B;
    logic [5:0] LCD_G;
    lcd_demo dut (.*);
    localparam logic [15:0] FINAL_PC = REPEAT_REQUESTS ? 16'h0211 : 16'h020e;
    always #5 XTAL_IN = ~XTAL_IN;
    int boot_writes = 0, cpu_writes = 0, clear_writes = 0;
    bit info_seen = 0, clear_seen = 0, clear_validation = 0, clear_counting = 0, info_holding = 0;
    int info_count = 0, clear_count = 0;
    logic [15:0] held_pc;
    logic [7:0] held_a, held_x, held_y, held_p, held_s;
    always @(posedge dut.cpu_clk) begin
        if (!rst_n) begin
            assert (!dut.ram_we_final)
            else $fatal(1, "Write during reset");
            boot_writes = 0;
            cpu_writes = 0;
            clear_writes = 0;
            info_seen = 0;
            clear_seen = 0;
            clear_validation = 0;
            clear_counting = 0;
            info_holding = 0;
            info_count = 0;
            clear_count = 0;
        end else begin
            if (dut.boot_active && dut.ram_we_final) boot_writes++;
            if (!dut.boot_active && dut.ram_we_final) cpu_writes++;
            if (dut.memory_hold) begin
                assert (!dut.ram_we_final)
                else $fatal(1, "Debug overwrote RAM");
            end
            if (dut.cpu_vram_clear) begin
                clear_seen = 1;
                clear_writes = 0;
                clear_validation = 1;
                clear_counting = 1;
                clear_count++;
            end
            if (clear_counting && dut.vram_cea) begin
                assert (dut.vram_ada == 10'(clear_writes) && dut.vram_din == 8'h20)
                else $fatal(1, "Clear transaction %0d address/data incorrect", clear_writes);
                clear_writes++;
                if (clear_writes == 1024) clear_counting = 0;
            end
            if (dut.cpu_show_info) begin
                info_count++;
                if (clear_validation) begin
                    assert (clear_writes == 1024)
                    else $fatal(1, "CVR did not retire all writes");
                    for (int i = 0; i < 1024; i++)
                    assert (dut.vram_inst.ram[i] == 8'h20)
                    else $fatal(1, "CVR cell %0d", i);
                    clear_validation = 0;
                end
                info_seen = 1;
                info_holding = 1;
                held_pc = dut.cpu_debug_pc;
                held_a = dut.cpu_debug_a;
                held_x = dut.cpu_debug_x;
                held_y = dut.cpu_debug_y;
                held_p = dut.cpu_debug_p;
                held_s = dut.cpu_debug_s;
            end
            if (!dut.memory_hold) info_holding = 0;
            if (info_holding && dut.memory_hold) begin
                assert(dut.cpu_debug_pc==held_pc && dut.cpu_debug_a==held_a &&
                       dut.cpu_debug_x==held_x && dut.cpu_debug_y==held_y &&
                       dut.cpu_debug_p==held_p && dut.cpu_debug_s==held_s)
                else $fatal(1, "Snapshot CPU advanced during rendering");
            end
        end
    end
    bit completed = 0;
    initial begin : test_main
        dut.u_rom.MULTIPLE = REPEAT_REQUESTS;
        // Unique adjacent RAM bytes catch stale reads and mixed nibbles.
        for (int i = 0; i < 32768; i++) dut.u_ram.mem[i] = 8'(i * 37 + 3);
        for (int i = 0; i < 1024; i++) dut.vram_inst.ram[i] = 8'h58;
        repeat (4) @(negedge XTAL_IN);
        rst_n = 1;
        wait (dut.cpu_rst_n);
        #1;
        assert (boot_writes == 256)
        else $fatal(1, "Boot write count %0d", boot_writes);
        for (int i = 0; i < 256; i++)
        assert (dut.u_ram.mem['h200+i] == dut.u_rom.expected(16'h0200 + 16'(i)))
        else $fatal(1, "Boot payload byte %0d", i);
        if (RESET_DURING_INFO) begin
            wait (dut.cpu_show_info);
            repeat (8) @(negedge XTAL_IN);
            rst_n = 0;
            repeat (4) @(negedge XTAL_IN);
            rst_n = 1;
            wait (dut.cpu_rst_n);
        end
        // Wait for the resumed store rather than any internal render state.
        for (int cycles = 0; cycles < 10000; cycles++) begin
            @(posedge dut.cpu_clk);
            #2;
            if (dut.u_ram.mem[2] == 8'h55 && dut.cpu_debug_pc == FINAL_PC && !dut.memory_hold) begin
                assert(info_seen && clear_seen && cpu_writes==3 &&
                        info_count==(REPEAT_REQUESTS?3:1) && clear_count==(REPEAT_REQUESTS?2:1))
                else $fatal(1, "Requests or CPU writes missing");
                assert(dut.vram_inst.ram[65]==(REPEAT_REQUESTS?"5":"1") &&
                       dut.vram_inst.ram[66]==(REPEAT_REQUESTS?"5":"2"))
                else $fatal(1, "A snapshot digits wrong");
                assert(dut.vram_inst.ram[245]=="0" && dut.vram_inst.ram[246]=="2" &&
                       dut.vram_inst.ram[247]==(REPEAT_REQUESTS?"1":"0") &&
                       dut.vram_inst.ram[248]==(REPEAT_REQUESTS?"1":"A"))
                else $fatal(1, "PC snapshot must be post-IFO 020A");
                assert(dut.vram_inst.ram[125]=="0" && dut.vram_inst.ram[126]=="0" &&
                       dut.vram_inst.ram[185]=="0" && dut.vram_inst.ram[186]=="0" &&
                       dut.vram_inst.ram[306]=="F" && dut.vram_inst.ram[307]=="F" &&
                       dut.vram_inst.ram[365]=="3" && dut.vram_inst.ram[366]=="C")
                else $fatal(1, "X/Y/SP/P snapshot mismatch");
                for (int addr = 0; addr < 128; addr++) begin
                    automatic int row = 9 + addr / 16;
                    automatic int lo = addr % 16;
                    automatic
                    int
                    col=(lo<4)?9+2*lo:(lo<8)?18+2*(lo-4):
                                      (lo<12)?28+2*(lo-8):37+2*(lo-12);
                    automatic
                    logic [7:0]
                    expected_byte=(addr==0)?8'hab:
                                  (addr==1)?8'h12:(REPEAT_REQUESTS && addr==2)?8'h55:8'(addr*37+3);
                    assert (dut.vram_inst.ram[row*60+col] == hex_digit(
                        expected_byte[7:4]
                    ) && dut.vram_inst.ram[row*60+col+1] == hex_digit(
                        expected_byte[3:0]
                    ))
                    else $fatal(1, "Dump mismatch at %0d", addr);
                    if (addr != 2)
                        assert (dut.u_ram.mem[addr] == expected_byte)
                        else $fatal(1, "RAM changed during dump at %0d", addr);
                end
                // LED column: row 9+k shows byte $0k as '@' (1) / ' ' (0), bit 7..0,
                // with a day99-style "0x0k:" label at cols 47-51.
                for (int k = 0; k < 8; k++) begin
                    automatic
                    logic [7:0]
                    expected_led=(k==0)?8'hab:
                                  (k==1)?8'h12:(REPEAT_REQUESTS && k==2)?8'h55:8'(k*37+3);
                    assert(dut.vram_inst.ram[(9+k)*60+47]=="0" &&
                           dut.vram_inst.ram[(9+k)*60+48]=="x" &&
                           dut.vram_inst.ram[(9+k)*60+49]=="0" &&
                           dut.vram_inst.ram[(9+k)*60+50]==hex_digit(
                        k[3:0]
                    ) && dut.vram_inst.ram[(9+k)*60+51] == ":")
                    else $fatal(1, "LED label mismatch at row %0d", 9 + k);
                    for (int b = 0; b < 8; b++) begin
                        assert (dut.vram_inst.ram[(9+k)*60+52+b] == (expected_led[7-b] ? "@" : " "))
                        else $fatal(1, "LED column mismatch at $%02X bit %0d", k, 7 - b);
                    end
                end
                repeat (6) begin
                    @(posedge dut.cpu_clk);
                    #2;
                end
                assert (dut.cpu_debug_pc == FINAL_PC && !dut.memory_hold)
                else $fatal(1, "Resume/HLT failed");
                $display("PASS: Day18 boot/CVR1024/IFO snapshot/dump/resumed store");
                completed = 1;
                break;
            end
        end
        if (!completed) $fatal(1, "Day18 integrated timeout PC=%h", dut.cpu_debug_pc);
        $finish;
    end
    function automatic logic [7:0] hex_digit(input logic [3:0] n);
        return n < 10 ? 8'(48 + int'(n)) : 8'(65 + int'(n) - 10);
    endfunction
    initial begin
        #200000;
        $fatal(1, "Global Day18 integration timeout");
    end
endmodule
