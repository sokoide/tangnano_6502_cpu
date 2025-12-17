// LCD demo repurposed from Day 09 so that Day 04 introduces the display early.
module lcd_demo (
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

    // Memory clock: 27MHz -> 40.5MHz (matches day99 memory/ROM timing)
    logic MEMORY_CLK;
    Gowin_rPLL40 pll_mem_inst (
        .clkout(MEMORY_CLK),
        .clkin (XTAL_IN)
    );

    logic [9:0] vram_addr;
    logic [7:0] vram_data;
    logic [11:0] font_addr;
    logic [7:0] font_data;
    /* verilator lint_off UNUSEDSIGNAL */
    logic vsync;
    /* verilator lint_on UNUSEDSIGNAL */

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

    // Synchronize LCD-domain addresses into the memory clock domain.
    logic [9:0] vram_addr_sync1, vram_addr_sync2;
    logic [11:0] font_addr_sync1, font_addr_sync2;

    always_ff @(posedge MEMORY_CLK or negedge rst_n) begin
        if (!rst_n) begin
            vram_addr_sync1 <= 10'd0;
            vram_addr_sync2 <= 10'd0;
            font_addr_sync1 <= 12'd0;
            font_addr_sync2 <= 12'd0;
        end else begin
            vram_addr_sync1 <= vram_addr;
            vram_addr_sync2 <= vram_addr_sync1;
            font_addr_sync1 <= font_addr;
            font_addr_sync2 <= font_addr_sync1;
        end
    end

    font_rom font_inst (
        .clk(MEMORY_CLK),
        .addr(font_addr_sync2),
        .data(font_data)
    );

    vram vram_inst (
        .clk(MEMORY_CLK),
        .rst_n(rst_n),
        .addr(vram_addr_sync2),
        .data(vram_data)
    );

endmodule
