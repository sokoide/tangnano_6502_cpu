// CPU/memory writes at 31.5MHz (9K) or 40.5MHz (20K); LCD reads at 9MHz.
// Both domains assert reset on external reset or either PLL lock loss.
module top_core #(parameter bit BOARD_20K = 0) (
    // Clock and Reset
    input logic rst_n,   // Active-low reset
    input logic XTAL_IN, // 27MHz crystal oscillator input

    // LCD Interface
    output logic       LCD_CLK,  // LCD pixel clock output (9MHz)
    output logic       LCD_DEN,  // LCD data enable
    output logic [4:0] LCD_R,    // LCD red channel (5-bit)
    output logic [5:0] LCD_G,    // LCD green channel (6-bit)
    output logic [4:0] LCD_B,    // LCD blue channel (5-bit)

    // Debug/Test Outputs
    output logic MEMORY_CLK  // Board-specific CPU/memory clock output
);

    // Clock Generation via Phase-Locked Loops (PLLs)
    // LCD timing: (480+43+8) * (272+8+12) * 58.05Hz ≈ 9MHz
    // CPU/Memory: Higher frequency for processing performance
    logic pixel_locked, memory_locked, pixel_rst_n, memory_rst_n;
    wire ready_n = rst_n && pixel_locked && memory_locked;
    platform_clocks #(.BOARD_20K(BOARD_20K)) clocks (
        .clkin(XTAL_IN), .rst_n(rst_n), .pixel_clk(LCD_CLK),
        .memory_clk(MEMORY_CLK), .pixel_locked(pixel_locked),
        .memory_locked(memory_locked));
    reset_sync pixel_reset(.clk(LCD_CLK), .ready_n(ready_n), .rst_n(pixel_rst_n));
    reset_sync memory_reset(.clk(MEMORY_CLK), .ready_n(ready_n), .rst_n(memory_rst_n));

    // pROM for font
    // 16bytes/char x 256 chars = 4KB
    logic f_ce, f_oce, f_reset;
    logic [ 7:0] f_dout;
    logic [11:0] f_ad;
    Gowin_pROM_font prom_font_inst (
        .dout(f_dout),  //output [7:0] dout
        .clk(LCD_CLK),  // font read belongs to pixel domain
        .oce(f_oce),  //input oce
        .ce(f_ce),  //input ce
        .reset(f_reset),  //input reset
        .ad(f_ad)  //input [11:0] ad
    );

    // LCD
    logic vsync;
    // VRAM read interface (driven by RAM, consumed by LCD)
    logic [7:0] v_dout;
    logic [9:0] v_adb;

    lcd lcd_inst (
        .PixelClk(LCD_CLK),
        .nRST    (pixel_rst_n),
        .v_dout  (v_dout),
        .f_dout  (f_dout),

        .LCD_DE(LCD_DEN),
        .LCD_B (LCD_B),
        .LCD_G (LCD_G),
        .LCD_R (LCD_R),
        .v_adb (v_adb),
        .f_ad  (f_ad),
        .vsync (vsync)
    );

    // Memory Interface Signals

    // Main RAM (32KB) Interface
    logic [7:0] dout;  // RAM read data
    logic cea, ceb, oce;  // RAM control signals
    logic reseta, resetb;  // RAM reset signals
    logic [14:0] ada, adb;  // RAM addresses (write/read)
    logic [7:0] din;  // RAM write data

    // Video RAM (1KB) Interface
    logic v_cea, v_ceb, v_oce;  // VRAM control signals
    logic v_reseta, v_resetb;  // VRAM reset signals
    logic [9:0] v_ada;  // VRAM write address
    logic [7:0] v_din;  // VRAM write data

    ram ram_inst (
        // common
        .MEMORY_CLK(MEMORY_CLK),
        .PIXEL_CLK(LCD_CLK),
        // regular RAM
        .dout(dout),
        .cea(cea && memory_rst_n),
        .ceb(ceb),
        .oce(oce),
        .reseta(reseta),
        .resetb(resetb),
        .ada(ada),
        .adb(adb),
        .din(din),
        // VRAM
        .v_dout(v_dout),
        .v_cea(v_cea && memory_rst_n),
        .v_ceb(v_ceb),
        .v_oce(v_oce),
        .v_reseta(v_reseta),
        .v_resetb(v_resetb),
        .v_ada(v_ada),
        .v_adb(v_adb),
        .v_din(v_din)
    );

    // Boot program instance
    `include "../include/boot_program.sv"

    // CPU instance
    cpu cpu_inst (
        .rst_n(memory_rst_n),
        .clk(MEMORY_CLK),
        .dout(dout),
        .vsync(vsync),
        .boot_program(boot_program),
        .boot_program_length(boot_program_length),
        .din(din),
        .ada(ada),
        .cea(cea),
        .ceb(ceb),
        .adb(adb),
        .v_ada(v_ada),
        .v_cea(v_cea),
        .v_din(v_din)
    );

    // READ_MODE=0 bypass outputs use CE, independent of OCE.
    assign reseta = !memory_rst_n;
    assign resetb = !memory_rst_n;
    assign oce = 1'b1;
    assign v_reseta = !memory_rst_n;
    assign v_resetb = !pixel_rst_n;
    assign v_ceb = pixel_rst_n;
    assign v_oce = 1'b1;
    assign f_ce = pixel_rst_n;
    assign f_oce = 1'b1;
    assign f_reset = !pixel_rst_n;
endmodule
