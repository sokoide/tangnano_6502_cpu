`timescale 1ns / 1ps
/* verilator lint_off UNUSEDSIGNAL */
// Trace simple5.s execution: sample A register and VRAM cell 59 (top-right)
// once per frame to see whether A sweeps 0x20..0x7E or toggles.
module tb_simple5_trace;
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

    // 27MHz clock
    always #18.5 XTAL_IN = ~XTAL_IN;

    initial begin
        int frames;
        int last_vsync;
        int vsync_count;

        XTAL_IN = 1'b0;

        // 9K: rst_n = ResetButton (active-high button)
        ResetButton = 1'b0;
        #200;
        ResetButton = 1'b1;

        $display("[sim] simple5 trace starting...");
        last_vsync  = 0;
        vsync_count = 0;

        for (frames = 0; frames < 400; frames++) begin
            @(posedge dut.u_core.vsync);
            vsync_count++;
            if (vsync_count % 3 == 0) begin
                $display("[t=%0t] frame %0d: A=%02x v_din=%02x pc=%04x state=%0d", $time,
                         vsync_count, dut.u_core.cpu_inst.cur.ra, dut.u_core.cpu_inst.cur.v_din,
                         dut.u_core.cpu_inst.cur.pc, dut.u_core.cpu_inst.cur.state);
            end
        end

        $display("[sim] done");
        $finish;
    end
endmodule
