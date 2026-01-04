/* verilator lint_off PINCONNECTEMPTY */
/* verilator lint_off UNUSEDSIGNAL */
// Day 04 Completed: System Core (LCD Only)
//
// This completed version focuses on the LCD visualization pipeline only.
// CPU register/flag logic is introduced in later days.

module top_core (
    input logic       rst_n,    // Active-low reset / 非アクティブ低レベル・リセット
    input logic       XTAL_IN,  // 27MHz Main Clock / 27MHz メインクロック入力
    input logic [3:0] switches, // Debug switches / デバッグ用スイッチ

    // LCD Signals / LCDインターフェース信号
    output logic       LCD_CLK,
    output logic       LCD_DEN,
    output logic [4:0] LCD_R,
    output logic [5:0] LCD_G,
    output logic [4:0] LCD_B,

    // Debug LEDs (Instruction categories) / デバッグ用LED
    output logic led_load,
    output logic led_store,
    output logic led_arithmetic,
    output logic led_branch
);

    // LCD demo instance
    lcd_demo u_demo (
        .rst_n  (rst_n),
        .XTAL_IN(XTAL_IN),
        .LCD_CLK(LCD_CLK),
        .LCD_DEN(LCD_DEN),
        .LCD_R  (LCD_R),
        .LCD_G  (LCD_G),
        .LCD_B  (LCD_B)
    );

    // LEDs are unused in Day 04.
    assign led_load = 1'b0;
    assign led_store = 1'b0;
    assign led_arithmetic = 1'b0;
    assign led_branch = 1'b0;

    // switches are currently unused.
    /* verilator lint_off UNUSED */
    wire _unused = &switches;
    /* verilator lint_on UNUSED */

endmodule
