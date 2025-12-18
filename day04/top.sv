// Day 04 Skeleton: The Foundation (LCD & Registers)
// In this module, you will integrate the LCD controller and the CPU registers.

module top (
    input logic       clk,      // 27MHz Crystal
    input logic       rst_n,    // S1 button
    input logic [3:0] switches, // External switches

    // LCD Signals
    output logic       LCD_CLK,
    output logic       LCD_DEN,
    output logic [4:0] LCD_R,
    output logic [5:0] LCD_G,
    output logic [4:0] LCD_B
);

    // TODO: Instantiate the PLL to generate 9MHz clock.
    // TODO: Instantiate lcd_demo to drive the display.
    // TODO: Instantiate cpu_registers and connect them to debug signals.

endmodule
