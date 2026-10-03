`timescale 1ns/1ps
/* verilator lint_off UNUSEDSIGNAL */
// Post-PnR netlist observation: peek the SDPB sim models to read RAM bytes
// and the VRAM cell at (59,0) — the character the user sees on the LCD.
module tb_pnr_trace;
    logic       ResetButton;
    logic       XTAL_IN;

    logic       LCD_CLK;
    logic       LCD_DEN;
    logic [4:0] LCD_R;
    logic [5:0] LCD_G;
    logic [4:0] LCD_B;
    logic       MEMORY_CLK;

    top dut (
        .ResetButton(ResetButton),
        .XTAL_IN(XTAL_IN),
        .LCD_CLK(LCD_CLK),
        .LCD_DEN(LCD_DEN),
        .LCD_R(LCD_R),
        .LCD_G(LCD_G),
        .LCD_B(LCD_B),
        .MEMORY_CLK(MEMORY_CLK)
    );

    always #18.518519 XTAL_IN = ~XTAL_IN;

    // RAM bit columns: instance 2b = ada[14]==0 bank, 2b+1 = ada[14]==1 bank.
    wire r00 = dut.\u_core/ram_inst/vendor.ram_inst/sdpb_inst_0  .ram_MEM[probe_addr[13:0]];
    wire r01 = dut.\u_core/ram_inst/vendor.ram_inst/sdpb_inst_1  .ram_MEM[probe_addr[13:0]];
    wire r02 = dut.\u_core/ram_inst/vendor.ram_inst/sdpb_inst_2  .ram_MEM[probe_addr[13:0]];
    wire r03 = dut.\u_core/ram_inst/vendor.ram_inst/sdpb_inst_3  .ram_MEM[probe_addr[13:0]];
    wire r04 = dut.\u_core/ram_inst/vendor.ram_inst/sdpb_inst_4  .ram_MEM[probe_addr[13:0]];
    wire r05 = dut.\u_core/ram_inst/vendor.ram_inst/sdpb_inst_5  .ram_MEM[probe_addr[13:0]];
    wire r06 = dut.\u_core/ram_inst/vendor.ram_inst/sdpb_inst_6  .ram_MEM[probe_addr[13:0]];
    wire r07 = dut.\u_core/ram_inst/vendor.ram_inst/sdpb_inst_7  .ram_MEM[probe_addr[13:0]];
    wire r08 = dut.\u_core/ram_inst/vendor.ram_inst/sdpb_inst_8  .ram_MEM[probe_addr[13:0]];
    wire r09 = dut.\u_core/ram_inst/vendor.ram_inst/sdpb_inst_9  .ram_MEM[probe_addr[13:0]];
    wire r10 = dut.\u_core/ram_inst/vendor.ram_inst/sdpb_inst_10 .ram_MEM[probe_addr[13:0]];
    wire r11 = dut.\u_core/ram_inst/vendor.ram_inst/sdpb_inst_11 .ram_MEM[probe_addr[13:0]];
    wire r12 = dut.\u_core/ram_inst/vendor.ram_inst/sdpb_inst_12 .ram_MEM[probe_addr[13:0]];
    wire r13 = dut.\u_core/ram_inst/vendor.ram_inst/sdpb_inst_13 .ram_MEM[probe_addr[13:0]];
    wire r14 = dut.\u_core/ram_inst/vendor.ram_inst/sdpb_inst_14 .ram_MEM[probe_addr[13:0]];
    wire r15 = dut.\u_core/ram_inst/vendor.ram_inst/sdpb_inst_15 .ram_MEM[probe_addr[13:0]];

    logic [14:0] probe_addr;
    logic [7:0]  probe_byte;
    always_comb begin
        probe_byte[0] = probe_addr[14] ? r01 : r00;
        probe_byte[1] = probe_addr[14] ? r03 : r02;
        probe_byte[2] = probe_addr[14] ? r05 : r04;
        probe_byte[3] = probe_addr[14] ? r07 : r06;
        probe_byte[4] = probe_addr[14] ? r09 : r08;
        probe_byte[5] = probe_addr[14] ? r11 : r10;
        probe_byte[6] = probe_addr[14] ? r13 : r12;
        probe_byte[7] = probe_addr[14] ? r15 : r14;
    end

    // VRAM is a single 8-bit SDPB; ram_MEM[cell*8 +: 8] = char code.
    wire [16383:0] vram_mem = dut.\u_core/ram_inst/vendor.vram_inst/sdpb_inst_0  .ram_MEM;
    logic [7:0]    vram_char59;
    always_comb vram_char59 = vram_mem[59*8 +: 8];

    initial begin
        integer cyc;
        integer i;
        integer j;
        integer k;

        XTAL_IN = 1'b0;
        ResetButton = 1'b0;   // 9K: rst_n = ResetButton (active-high button)
        #200;
        ResetButton = 1'b1;

        // Wait for boot to finish (~25 writes at 2 cycles each << 1M cycles).
        for (cyc = 0; cyc < 2000000; cyc++) begin
            @(posedge MEMORY_CLK);
            if (cyc % 100000 == 0) $display("[pnr] progress cyc=%0d t=%0t", cyc, $time);
        end

        $display("[pnr] RAM dump after boot:");
        for (i = 0; i < 40; i = i + 4) begin
            $write("  0x%03x: ", 16'h0200 + i);
            for (j = 0; j < 4; j++) begin
                probe_addr = 15'h0200 + i + j;
                #1;
                $write("%02x ", probe_byte);
            end
            $write("\n");
        end

        // Sample the displayed char at (59,0) for ~2 seconds.
        probe_addr = 15'h0210;
        for (k = 0; k < 6; k++) begin
            for (cyc = 0; cyc < 1000000; cyc++) begin
                @(posedge MEMORY_CLK);
                if (cyc % 100000 == 0) $display("[pnr] frame-progress k=%0d cyc=%0d", k, cyc);
            end
            $display("[pnr] t=%0dms vram[59]=%02x ram[0210]=%02x",
                     (k+1)*37, vram_char59, probe_byte);
        end
        $finish;
    end
endmodule
