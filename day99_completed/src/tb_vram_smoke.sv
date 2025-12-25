/* verilator lint_off UNUSEDSIGNAL */
module tb_vram_smoke;
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
        int cycles;
        int vram_writes;
        bit saw_den;

        XTAL_IN = 1'b0;
        vram_writes = 0;
        saw_den = 0;

`ifdef BOARD_20K
        // rst_n = !ResetButton (active-low reset)
        ResetButton = 1'b1;
        #200;
        ResetButton = 1'b0;
`else
        // rst_n = ResetButton (active-high button)
        ResetButton = 1'b0;
        #200;
        ResetButton = 1'b1;
`endif

        $display("[sim] Day99 VRAM smoke test starting...");
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_vram_smoke);

        for (cycles = 0; cycles < 300000; cycles++) begin
            @(posedge MEMORY_CLK);

            if (dut.u_core.v_cea) begin
                vram_writes++;
                if (vram_writes <= 16) begin
                    $display("[vram] write #%0d addr=%0d data=%02x", vram_writes, dut.u_core.v_ada,
                             dut.u_core.v_din);
                end
            end

            if (LCD_DEN) begin
                saw_den = 1;
            end

            if (vram_writes >= 1 && saw_den) begin
                break;
            end
        end

        if (!saw_den) begin
            $fatal(1, "LCD_DEN never asserted (LCD timing not running?)");
        end
        if (vram_writes == 0) begin
            $fatal(1, "No VRAM writes observed from CPU");
        end

        $display("[sim] PASS: saw %0d VRAM writes and LCD_DEN activity", vram_writes);
        $finish;
    end
endmodule

/* verilator lint_on UNUSEDSIGNAL */
