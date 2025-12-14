// Simulation testbench for Day10 TFT bring-up (smoke test)

`include "include/board_select.svh"

module tb_tft;
    logic ResetButton;
    logic XTAL_IN;

    logic        LCD_CLK;
    logic        LCD_DEN;
    logic [4:0]  LCD_R;
    logic [5:0]  LCD_G;
    logic [4:0]  LCD_B;

    top uut (
        .ResetButton(ResetButton),
        .XTAL_IN(XTAL_IN),
        .LCD_CLK(LCD_CLK),
        .LCD_DEN(LCD_DEN),
        .LCD_R(LCD_R),
        .LCD_G(LCD_G),
        .LCD_B(LCD_B)
    );

    // 27MHz clock
    always #18.5 XTAL_IN = ~XTAL_IN;

    initial begin
        int cycles;
        bit saw_den;
        bit saw_color;

        XTAL_IN = 1'b0;
        saw_den = 1'b0;
        saw_color = 1'b0;

`ifdef BOARD_20K
        ResetButton = 1'b1;
        #200;
        ResetButton = 1'b0;
`else
        ResetButton = 1'b0;
        #200;
        ResetButton = 1'b1;
`endif

        $display("Starting Day10 TFT sim...");
        $dumpfile("tb_tft.vcd");
        $dumpvars(0, tb_tft);

        for (cycles = 0; cycles < 30000; cycles++) begin
            @(posedge LCD_CLK);
            if (LCD_DEN) begin
                saw_den = 1'b1;
                if ((LCD_R != 5'd0) || (LCD_G != 6'd0) || (LCD_B != 5'd0))
                    saw_color = 1'b1;
            end
            if (saw_den && saw_color) break;
        end

        if (!saw_den)  $fatal(1, "LCD_DEN never asserted (timing not running?)");
        if (!saw_color) $fatal(1, "Never observed non-black pixel during active region");

        $display("PASS: saw LCD_DEN and color output");
        $finish;
    end
endmodule
