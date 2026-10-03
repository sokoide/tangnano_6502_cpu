`ifndef TB_LCD_PIPELINE_SV
`define TB_LCD_PIPELINE_SV
`timescale 1ns / 1ps
module tb_lcd_pipeline;
    logic pclk = 0, mclk = 0, rst_n = 0, write_en = 0;
    int phase = 0;
    initial begin
        void'($value$plusargs("phase=%d", phase));
        #(phase);
        forever #55.555556 pclk = ~pclk;
    end
    always #12.345679 mclk = ~mclk;
    logic [9:0] wa = 0, ra;
    logic [7:0] wd = 0, vd, fd;
    logic [11:0] fa;
    logic de, vs;
    logic [4:0] r, b;
    logic [5:0] g;
    ram memory (
        .MEMORY_CLK(mclk),
        .PIXEL_CLK(pclk),
        .dout(),
        .cea(1'b0),
        .ceb(1'b0),
        .oce(1'b0),
        .reseta(1'b0),
        .resetb(1'b0),
        .ada(15'b0),
        .adb(15'b0),
        .din(8'b0),
        .v_dout(vd),
        .v_cea(write_en),
        .v_ceb(rst_n),
        .v_oce(1'b0),
        .v_reseta(1'b0),
        .v_resetb(!rst_n),
        .v_ada(wa),
        .v_adb(ra),
        .v_din(wd)
    );
    Gowin_pROM_font font (
        .dout(fd),
        .clk(pclk),
        .oce(1'b0),
        .ce(rst_n),
        .reset(!rst_n),
        .ad(fa)
    );
    lcd dut (
        .PixelClk(pclk),
        .nRST(rst_n),
        .v_dout(vd),
        .f_dout(fd),
        .LCD_DE(de),
        .LCD_R(r),
        .LCD_G(g),
        .LCD_B(b),
        .v_adb(ra),
        .f_ad(fa),
        .vsync(vs)
    );
    function automatic logic [7:0] code(input int index);
        return 8'(33 + index % 90);
    endfunction
    logic [7:0] expected_font[4096];
    logic expected_valid[3], expected_bit[3];
    int h = 0, v = 0, pixels = 0, lit = 0, cell_index, x, y;
    bit valid, bitmap;
    int file, value, n = 0;
    string line;
    initial begin
        for (int i = 0; i < 4096; i++) expected_font[i] = 0;
        file = $fopen("data/font.mi", "r");
        if (!file) $fatal(1, "Missing expected font");
        while ($fgets(
            line, file
        ))
        if (line.getc(0) != 8'h23) begin
            if ($sscanf(line, "%h", value) != 1 || n >= 4096) $fatal(1, "Expected font parse");
            expected_font[n++] = 8'(value);
        end
        $fclose(file);
        if (n != 2048) $fatal(1, "Expected font size");
        for (int j = 0; j < 3; j++) begin
            expected_valid[j] = 0;
            expected_bit[j]   = 0;
        end
        for (int j = 0; j < 1024; j++) begin
            @(negedge mclk);
            write_en = 1;
            wa = 10'(j);
            wd = code(j);
        end
        @(negedge mclk);
        write_en = 0;
        @(negedge pclk);
        rst_n = 1;
        // Two complete frames plus pipeline drain; reference does not read DUT counters.
        for (int t = 0; t < 531 * 292 * 2 + 2; t++) begin
            @(posedge pclk);
            valid = h >= 43 && h < 523 && v >= 12 && v < 284;
            x = valid ? h - 43 : 0;
            y = valid ? v - 12 : 0;
            cell_index = x / 8 + (y / 16) * 60;
            bitmap = expected_font[int'(code(cell_index))*16+y%16][7-x%8];
            if (ra !== 10'(cell_index))
                $fatal(1, "VRAM address t=%0d got=%0d expected=%0d", t, ra, cell_index);
            expected_valid[2] = expected_valid[1];
            expected_valid[1] = expected_valid[0];
            expected_valid[0] = valid;
            expected_bit[2]   = expected_bit[1];
            expected_bit[1]   = expected_bit[0];
            expected_bit[0]   = bitmap;
            #1;
            if (vs !== (v < 12 || v >= 284)) $fatal(1, "VSync line %0d", v);
            if (de !== expected_valid[2]) $fatal(1, "DE pipeline t=%0d", t);
            if (de) begin
                pixels++;
                if (r !== 0 || b !== 0 || g !== (expected_bit[2] ? 6'd63 : 6'd0))
                    $fatal(1, "Pixel t=%0d rgb=%h/%h/%h bit=%b", t, r, g, b, expected_bit[2]);
                if (g) lit++;
            end
            if (h == 530) begin
                h = 0;
                v = (v == 291) ? 0 : v + 1;
            end else h++;
        end
        if (pixels != 480 * 272 * 2 || lit == 0) $fatal(1, "Pixel count %0d lit %0d", pixels, lit);
        $display("PASS LCD phase=%0d pixels=%0d lit=%0d: all cells/rows/bits/DE/period", phase,
                 pixels, lit);
        $finish;
    end
    initial begin
        #40000000;
        $fatal(1, "LCD timeout");
    end
endmodule

`endif
