module top_core (
    input  logic       rst_n,
    input  logic       XTAL_IN,

    output logic       LCD_CLK,
    output logic       LCD_DEN,
    output logic [4:0] LCD_R,
    output logic [5:0] LCD_G,
    output logic [4:0] LCD_B
);

    // Clock generation: 27MHz -> 9MHz
    Gowin_rPLL9 pll_inst (
        .clkout(LCD_CLK),
        .clkin (XTAL_IN)
    );

    logic [9:0] vram_addr;
    logic [7:0] vram_data;
    logic [11:0] font_addr;
    logic [7:0] font_data;
    logic vsync;

    lcd lcd_inst (
        .PixelClk(LCD_CLK),
        .nRST(rst_n),
        .v_dout(vram_data),
        .f_dout(font_data),
        .LCD_DE(LCD_DEN),
        .LCD_B(LCD_B),
        .LCD_G(LCD_G),
        .LCD_R(LCD_R),
        .v_adb(vram_addr),
        .f_ad(font_addr),
        .vsync(vsync)
    );

    font_rom font_inst (
        .clk(LCD_CLK),
        .addr(font_addr),
        .data(font_data)
    );

    vram vram_inst (
        .clk(LCD_CLK),
        .rst_n(rst_n),
        .addr(vram_addr),
        .data(vram_data)
    );

endmodule
