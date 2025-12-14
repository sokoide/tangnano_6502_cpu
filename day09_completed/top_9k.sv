// Day 09: Tang Nano 9K top-level wrapper
//
// 9K board: reset button is active-high (rst_n follows ResetButton).

/* verilator lint_off DECLFILENAME */
module top (
    input  logic ResetButton,
    input  logic XTAL_IN,
    output logic       LCD_CLK,
    output logic       LCD_DEN,
    output logic [4:0] LCD_R,
    output logic [5:0] LCD_G,
    output logic [4:0] LCD_B
);
    logic rst_n;
    assign rst_n = ResetButton;

    top_core u_core (
        .rst_n(rst_n),
        .XTAL_IN(XTAL_IN),
        .LCD_CLK(LCD_CLK),
        .LCD_DEN(LCD_DEN),
        .LCD_R(LCD_R),
        .LCD_G(LCD_G),
        .LCD_B(LCD_B)
    );
endmodule
/* verilator lint_on DECLFILENAME */
