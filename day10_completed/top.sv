// Day 10 Completed: 480x272 RGB TFT bring-up (animated color bars)
//
// Day10 uses the same 480x272 RGB TFT wiring as `day99_completed`:
// RGB565 + LCD_DEN + LCD_CLK.
//
// Pins are defined in tft_*.cst.

`include "include/board_select.svh"

module top (
    input  ResetButton,
    input  XTAL_IN,     // 27MHz

    output       LCD_CLK,  // Pixel clock (~9MHz)
    output       LCD_DEN,
    output logic [4:0] LCD_R,
    output logic [5:0] LCD_G,
    output logic [4:0] LCD_B
);

`ifdef BOARD_20K
    logic rst_n;
    assign rst_n = !ResetButton;
`else
    logic rst_n;
    assign rst_n = ResetButton;
`endif

    // 27MHz -> 9MHz pixel clock (PLL IP, board-specific netlist)
    Gowin_rPLL9 rpll9_inst (
        .clkout(LCD_CLK),
        .clkin (XTAL_IN)
    );

    // 480x272 timing (DE-only mode)
    // Keep these simple (no `int unsigned`) so Gowin GUI builds work even if the
    // project is not set to SystemVerilog-2017 mode.
    localparam [15:0] H_VALID = 16'd480;
    localparam [15:0] H_BACK  = 16'd43;
    localparam [15:0] H_FRONT = 16'd8;
    localparam [15:0] H_TOTAL = H_BACK + H_VALID + H_FRONT;

    localparam [15:0] V_VALID = 16'd272;
    localparam [15:0] V_BACK  = 16'd12;
    localparam [15:0] V_FRONT = 16'd8;
    localparam [15:0] V_TOTAL = V_BACK + V_VALID + V_FRONT;

    logic [15:0] h_count;
    logic [15:0] v_count;

    always @(posedge LCD_CLK or negedge rst_n) begin
        if (!rst_n) begin
            h_count <= 16'd0;
            v_count <= 16'd0;
        end else if (h_count == (H_TOTAL - 16'd1)) begin
            h_count <= 16'd0;
            if (v_count == (V_TOTAL - 16'd1)) v_count <= 16'd0;
            else v_count <= v_count + 16'd1;
        end else begin
            h_count <= h_count + 16'd1;
        end
    end

    logic active;
    assign active =
        (h_count >= H_BACK) && (h_count < (H_BACK + H_VALID)) &&
        (v_count >= V_BACK) && (v_count < (V_BACK + V_VALID));

    assign LCD_DEN = active;

    logic [15:0] x;
    assign x = (h_count >= H_BACK) ? (h_count - H_BACK) : 16'd0;

    // Animate the bar boundary for a visible "alive" pattern.
    logic [23:0] anim;
    always @(posedge LCD_CLK or negedge rst_n) begin
        if (!rst_n) anim <= 24'd0;
        else anim <= anim + 24'd1;
    end
    logic [9:0] shift;
    assign shift = anim[23:14];

    always @(posedge LCD_CLK or negedge rst_n) begin
        if (!rst_n) begin
            LCD_R <= 5'd0;
            LCD_G <= 6'd0;
            LCD_B <= 5'd0;
        end else if (active) begin
            if (x < (16'd160 + shift)) begin
                LCD_R <= 5'd31;
                LCD_G <= 6'd0;
                LCD_B <= 5'd0;
            end else if (x < (16'd320 + shift)) begin
                LCD_R <= 5'd0;
                LCD_G <= 6'd63;
                LCD_B <= 5'd0;
            end else begin
                LCD_R <= 5'd0;
                LCD_G <= 6'd0;
                LCD_B <= 5'd31;
            end
        end else begin
            LCD_R <= 5'd0;
            LCD_G <= 6'd0;
            LCD_B <= 5'd0;
        end
    end

endmodule
