// Day 04: Board Wrapper for Tang Nano 9K
/* verilator lint_off DECLFILENAME */
module top (
    input  logic       ResetButton,
    input  logic       XTAL_IN,
    output logic       LCD_CLK,
    output logic       LCD_DEN,
    output logic [4:0] LCD_R,
    output logic [5:0] LCD_G,
    output logic [4:0] LCD_B,
    output logic [5:0] led       // 6 LEDs (Active Low)
);
    logic rst_n;
    assign rst_n = ResetButton;

    logic l_load, l_store, l_arith, l_branch;

    top_core u_core (
        .rst_n  (rst_n),
        .XTAL_IN(XTAL_IN),
        .switches(4'b0),
        .LCD_CLK(LCD_CLK),
        .LCD_DEN(LCD_DEN),
        .LCD_R  (LCD_R),
        .LCD_G  (LCD_G),
        .LCD_B  (LCD_B),
        .led_load(l_load),
        .led_store(l_store),
        .led_arithmetic(l_arith),
        .led_branch(l_branch)
    );

    // Invert for Tang Nano 9K (Active Low)
    assign led[0] = ~l_load;
    assign led[1] = ~l_store;
    assign led[2] = ~l_arith;
    assign led[3] = ~l_branch;
    assign led[5:4] = 2'b11; // Off

endmodule
/* verilator lint_on DECLFILENAME */
