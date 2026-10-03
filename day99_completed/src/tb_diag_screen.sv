`timescale 1ns/1ps
/* verilator lint_off UNUSEDSIGNAL */
// Dump the 60x17 text screen from the behavioral VRAM model after a few frames.
module tb_diag_screen;
    logic       ResetButton;
    logic       XTAL_IN;

    logic       LCD_CLK;
    logic       LCD_DEN;
    logic [4:0] LCD_R;
    logic [5:0] LCD_G;
    logic [4:0] LCD_B;
    logic       MEMORY_CLK;

    top dut (
        .ResetButton(ResetButton),
        .XTAL_IN(XTAL_IN),
        .LCD_CLK(LCD_CLK),
        .LCD_DEN(LCD_DEN),
        .LCD_R(LCD_R),
        .LCD_G(LCD_G),
        .LCD_B(LCD_B),
        .MEMORY_CLK(MEMORY_CLK)
    );

    always #18.5 XTAL_IN = ~XTAL_IN;

    initial begin
        int row;
        int col;

        XTAL_IN = 1'b0;
        ResetButton = 1'b0;
        #200;
        ResetButton = 1'b1;

        // Run ~1.5s of sim time so CVR/IFO/WVS complete.
        repeat (90000000) @(posedge MEMORY_CLK);

        for (row = 0; row < 17; row++) begin
            for (col = 0; col < 60; col++) begin
                $write("%c", dut.u_core.ram_inst.behavioral.vram_mem[row*60+col]);
            end
            $write("\n");
        end
        $finish;
    end
endmodule
