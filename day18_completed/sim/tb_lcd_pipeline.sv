`timescale 1ns/1ps
module tb_lcd_pipeline;
    logic clk = 0, rst_n = 0, write_en = 0;
    always #55.555556 clk = ~clk;
    logic [9:0] write_addr = 0, read_addr;
    logic [7:0] write_data = 0, vram_data, font_data = 0;
    logic [11:0] font_addr;
    logic de, vsync;
    logic [4:0] red, blue;
    logic [5:0] green;
    vram memory(.clk(clk), .rst_n(rst_n), .addr(read_addr), .write_en(write_en),
        .write_addr(write_addr), .write_data(write_data), .data(vram_data));
    lcd dut(.PixelClk(clk), .nRST(rst_n), .v_dout(vram_data), .f_dout(font_data),
        .LCD_DE(de), .LCD_R(red), .LCD_G(green), .LCD_B(blue),
        .v_adb(read_addr), .f_ad(font_addr), .vsync(vsync));

    // Distinct cell codes and row patterns expose previous-cell/row/bit errors.
    function automatic logic [7:0] code(input int index);
        return 8'(33 + index % 90);
    endfunction
    function automatic logic [7:0] glyph(input logic [7:0] character, input int row);
        return (character ^ 8'(row * 37)) + 8'(row);
    endfunction
    always_ff @(posedge clk) font_data <= glyph(font_addr[11:4], int'(font_addr[3:0]));

    logic expected_valid[3], expected_bit[3];
    int h = 0, v = 0, pixels = 0, lit = 0, x, y, cell_index;
    logic active;
    logic [7:0] bitmap;
    initial begin
        for (int j = 0; j < 3; j++) begin expected_valid[j] = 0; expected_bit[j] = 0; end
        // Initialize through the write interface while keeping the LCD reset.
        rst_n = 1;
        for (int j = 0; j < 1024; j++) begin
            @(negedge clk); write_en = 1; write_addr = 10'(j); write_data = code(j);
        end
        @(negedge clk); write_en = 0; rst_n = 0;
        repeat (3) @(negedge clk);
        rst_n = 1;
        for (int t = 0; t < 531 * 292 * 2 + 2; t++) begin
            @(posedge clk);
            active = h >= 43 && h < 523 && v >= 12 && v < 284;
            x = active ? h - 43 : 0; y = active ? v - 12 : 0;
            cell_index = x / 8 + (y / 16) * 60;
            bitmap = glyph(code(cell_index), y % 16);
            assert (read_addr === 10'(cell_index)) else $fatal(1, "Address t=%0d", t);
            expected_valid[2] = expected_valid[1]; expected_valid[1] = expected_valid[0];
            expected_valid[0] = active;
            expected_bit[2] = expected_bit[1]; expected_bit[1] = expected_bit[0];
            expected_bit[0] = bitmap[7 - x % 8];
            #1;
            assert (vsync === (v < 12 || v >= 284)) else $fatal(1, "VSync line %0d", v);
            assert (de === expected_valid[2]) else $fatal(1, "DE t=%0d", t);
            if (de) begin
                pixels++;
                assert (red === 0 && blue === 0 && green === (expected_bit[2] ? 6'd63 : 6'd0))
                    else $fatal(1, "Pixel t=%0d rgb=%h/%h/%h", t, red, green, blue);
                if (green) lit++;
            end
            if (h == 530) begin h = 0; v = (v == 291) ? 0 : v + 1; end else h++;
        end
        assert (pixels == 480 * 272 * 2 && lit > 0) else $fatal(1, "Pixel count");
        $display("PASS LCD pipeline: %0d pixels, all cells/rows/bits/DE/frame period", pixels);
        $finish;
    end
    initial begin #40000000; $fatal(1, "LCD timeout"); end
endmodule
