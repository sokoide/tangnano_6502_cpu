// Day 04: System Core (LCD & Visualization) - Skeleton
//
// Learning Goals: / 学習目標:
// 1. Integration of LCD rendering pipeline / LCDレンダリングパイプラインの統合
// 2. Understanding VRAM and Memory Map / VRAMとメモリマップの理解

module top_core (
    input logic       rst_n,
    input logic       XTAL_IN,
    input logic [3:0] switches,

    // LCD Signals
    output logic       LCD_CLK,
    output logic       LCD_DEN,
    output logic [4:0] LCD_R,
    output logic [5:0] LCD_G,
    output logic [4:0] LCD_B,

    // Debug LEDs (not used in Day 04 skeleton)
    output logic led_load,
    output logic led_store,
    output logic led_arithmetic,
    output logic led_branch
);

    // -------------------------------------------------------------------------
    // STEP 1: LCD Demo Instance / LCDデモ・モジュールのインスタンス化
    // -------------------------------------------------------------------------
    // TODO: Instantiate the lcd_demo module for LCD display as "u_demo".
    // TODO: 液晶表示用の lcd_demo モジュールを "u_demo" という名前でインスタンス化してください。
    // Input XTAL_IN (27MHz) and connect various LCD signals to outputs.
    // XTAL_IN (27MHz) を入力し、各種LCD信号を出力に接続します。
    // This enables the display function on the actual hardware.
    // これにより、実機での表示機能が有効になります。


    // For Day 04, we just keep the debug outputs inactive.
    assign led_load = 1'b0;
    assign led_store = 1'b0;
    assign led_arithmetic = 1'b0;
    assign led_branch = 1'b0;

endmodule
