// Day 04 Completed: LCD Display & Rendering Pipeline
// This module integrates the PLL, VRAM, and Font ROM to drive the TFT panel.
`include "include/consts.svh"
module lcd_demo (
    input  logic       rst_n,
    input  logic       XTAL_IN,
    output logic       LCD_CLK,
    output logic       LCD_DEN,
    output logic [4:0] LCD_R,
    output logic [5:0] LCD_G,
    output logic [4:0] LCD_B
);

    logic [9:0] vram_addr;   // Text-VRAM address (60x17 layout)
    logic [7:0] vram_data;   // ASCII character code from VRAM
    logic [11:0] font_addr;  // Font ROM address (Char index + row)
    logic [7:0] font_data;   // 1-byte pixel pattern for the current row
    /* verilator lint_off UNUSEDSIGNAL */
    logic vsync;
    /* verilator lint_on UNUSEDSIGNAL */

`ifdef VERILATOR
    // Simulation path: keep everything in the PixelClk domain with simple models.
    Gowin_rPLL9 pll_inst (
        .clkout(LCD_CLK),
        .clkin (XTAL_IN)
    );

    font_rom font_inst (
        .clk (LCD_CLK),
        .addr(font_addr),
        .data(font_data)
    );

    vram vram_inst (
        .clk  (LCD_CLK),
        .rst_n(rst_n),
        .addr (vram_addr),
        .data (vram_data)
    );
`else
    // FPGA path: match the stable day99 display path (fast MEMORY_CLK + BRAM/pROM).
    logic MEMORY_CLK;

    Gowin_rPLL9 pll9_inst (
        .clkout(LCD_CLK),
        .clkin (XTAL_IN)
    );

    Gowin_rPLL40 pll40_inst (
        .clkout(MEMORY_CLK),
        .clkin (XTAL_IN)
    );

    // Font pROM (Sweet16Font, 4KB: 16 bytes/char x 256 chars)
    Gowin_pROM_font prom_font_inst (
        .dout (font_data),
        .clk  (MEMORY_CLK),
        .oce  (1'b1),
        .ce   (1'b1),
        .reset(1'b0),
        .ad   (font_addr)
    );

    // VRAM in SDPB (1KB), written once at boot to show the demo text.
    logic [9:0] vram_adb_sync1, vram_adb_sync2;
    always_ff @(posedge MEMORY_CLK or negedge rst_n) begin
        if (!rst_n) begin
            vram_adb_sync1 <= 10'd0;
            vram_adb_sync2 <= 10'd0;
        end else begin
            vram_adb_sync1 <= vram_addr;
            vram_adb_sync2 <= vram_adb_sync1;
        end
    end

    logic       vram_cea;
    logic [9:0] vram_ada;
    logic [7:0] vram_din;

    Gowin_SDPB_vram vram_inst (
        .dout  (vram_data),
        .clka  (MEMORY_CLK),
        .cea   (vram_cea),
        .reseta(1'b0),
        .clkb  (MEMORY_CLK),
        .ceb   (1'b1),
        .resetb(1'b0),
        .oce   (1'b0),
        .ada   (vram_ada),
        .din   (vram_din),
        .adb   (vram_adb_sync2)
    );

    // Simple VRAM initializer (runs once after reset)
    localparam int VRAM_DEPTH = COLUMNS * ROWS;  // 60*17 = 1020
    localparam int ROW0_LEN   = 9;
    localparam int ROW1_LEN   = 8;
    localparam int ROW2_LEN   = 9;

    function automatic logic [7:0] row0_char(input int i);
        unique case (i)
            0: row0_char = "V";
            1: row0_char = "R";
            2: row0_char = "A";
            3: row0_char = "M";
            4: row0_char = " ";
            5: row0_char = "T";
            6: row0_char = "E";
            7: row0_char = "X";
            8: row0_char = "T";
            default: row0_char = " ";
        endcase
    endfunction

    function automatic logic [7:0] row1_char(input int i);
        unique case (i)
            0: row1_char = "C";
            1: row1_char = "H";
            2: row1_char = "A";
            3: row1_char = "R";
            4: row1_char = " ";
            5: row1_char = "L";
            6: row1_char = "C";
            7: row1_char = "D";
            default: row1_char = " ";
        endcase
    endfunction

    function automatic logic [7:0] row2_char(input int i);
        unique case (i)
            0: row2_char = "F";
            1: row2_char = "P";
            2: row2_char = "G";
            3: row2_char = "A";
            4: row2_char = " ";
            5: row2_char = "S";
            6: row2_char = "H";
            7: row2_char = "O";
            8: row2_char = "W";
            default: row2_char = " ";
        endcase
    endfunction

    typedef enum logic [2:0] {S_CLEAR, S_ROW0, S_ROW1, S_ROW2, S_DONE} init_state_t;
    init_state_t init_state;
    logic [9:0] init_addr;
    logic [3:0] init_idx;

    always_ff @(posedge MEMORY_CLK or negedge rst_n) begin
        if (!rst_n) begin
            init_state <= S_CLEAR;
            init_addr  <= 10'd0;
            init_idx   <= 4'd0;
            vram_cea   <= 1'b0;
            vram_ada   <= 10'd0;
            vram_din   <= 8'h20;
        end else begin
            vram_cea <= 1'b0;
            unique case (init_state)
                S_CLEAR: begin
                    vram_cea <= 1'b1;
                    vram_ada <= init_addr;
                    vram_din <= 8'h20;
                    if (init_addr == VRAM_DEPTH - 1) begin
                        init_state <= S_ROW0;
                        init_idx   <= 4'd0;
                    end else begin
                        init_addr <= init_addr + 10'd1;
                    end
                end
                S_ROW0: begin
                    vram_cea <= 1'b1;
                    vram_ada <= (1 * COLUMNS + 4 + init_idx);
                    vram_din <= row0_char(init_idx);
                    if (init_idx == ROW0_LEN - 1) begin
                        init_state <= S_ROW1;
                        init_idx   <= 4'd0;
                    end else begin
                        init_idx <= init_idx + 4'd1;
                    end
                end
                S_ROW1: begin
                    vram_cea <= 1'b1;
                    vram_ada <= (5 * COLUMNS + 8 + init_idx);
                    vram_din <= row1_char(init_idx);
                    if (init_idx == ROW1_LEN - 1) begin
                        init_state <= S_ROW2;
                        init_idx   <= 4'd0;
                    end else begin
                        init_idx <= init_idx + 4'd1;
                    end
                end
                S_ROW2: begin
                    vram_cea <= 1'b1;
                    vram_ada <= (9 * COLUMNS + 10 + init_idx);
                    vram_din <= row2_char(init_idx);
                    if (init_idx == ROW2_LEN - 1) begin
                        init_state <= S_DONE;
                    end else begin
                        init_idx <= init_idx + 4'd1;
                    end
                end
                default: begin
                    init_state <= S_DONE;
                end
            endcase
        end
    end
`endif

    // LCD Controller: Generates timing (HSYNC/VSYNC/DEN) and scanline coordinates
    lcd lcd_inst (
        .PixelClk(LCD_CLK),
        .nRST(rst_n),
        .v_dout(vram_data),   // Feed character code
        .f_dout(font_data),   // Feed font pixels
        .LCD_DE(LCD_DEN),
        .LCD_B(LCD_B),
        .LCD_G(LCD_G),
        .LCD_R(LCD_R),
        .v_adb(vram_addr),    // Output VRAM address for NEXT pixel
        .f_ad(font_addr),     // Output Font address for NEXT pixel
        .vsync(vsync)
    );

endmodule
