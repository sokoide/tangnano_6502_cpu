// Day 09 Completed: 480x272 RGB TFT bring-up (color bars)
//
// This day is for the 480x272 RGB TFT panel (RGB565 + DEN + CLK).
// It generates the LCD timing in "SYNC-DE" mode and outputs simple color bars.
//
// Pins are defined in tft_*.cst.

`include "include/board_select.svh"

module top (
    // Clock and Reset
    input  logic ResetButton,
    input  logic XTAL_IN,     // 27MHz

    // LCD Interface
    output logic       LCD_CLK,  // Pixel clock (~9MHz)
    output logic       LCD_DEN,  // Data enable
    output logic [4:0] LCD_R,
    output logic [5:0] LCD_G,
    output logic [4:0] LCD_B,

    // Debug
    output logic led
);

`ifdef BOARD_20K
    wire rst_n = !ResetButton;
`else
    wire rst_n = ResetButton;
`endif

    // 27MHz -> 9MHz pixel clock (PLL IP, board-specific netlist)
    Gowin_rPLL9 rpll9_inst (
        .clkout(LCD_CLK),
        .clkin (XTAL_IN)
    );

    // 480x272 timing (DE-only mode)
    localparam int unsigned H_VALID = 480;
    localparam int unsigned H_BACK  = 43;
    localparam int unsigned H_FRONT = 8;
    localparam int unsigned H_TOTAL = H_BACK + H_VALID + H_FRONT;

    localparam int unsigned V_VALID = 272;
    localparam int unsigned V_BACK  = 12;
    localparam int unsigned V_FRONT = 8;
    localparam int unsigned V_TOTAL = V_BACK + V_VALID + V_FRONT;

    logic [15:0] h_count;
    logic [15:0] v_count;

    always_ff @(posedge LCD_CLK or negedge rst_n) begin
        if (!rst_n) begin
            h_count <= 16'd0;
            v_count <= 16'd0;
        end else if (h_count == (H_TOTAL - 1)) begin
            h_count <= 16'd0;
            if (v_count == (V_TOTAL - 1)) v_count <= 16'd0;
            else v_count <= v_count + 16'd1;
        end else begin
            h_count <= h_count + 16'd1;
        end
    end

    wire active =
        (h_count >= H_BACK) && (h_count < (H_BACK + H_VALID)) &&
        (v_count >= V_BACK) && (v_count < (V_BACK + V_VALID));

    assign LCD_DEN = active;

    // Simple color bars inside active region
    logic [15:0] x;
    always_comb begin
        x = (h_count >= H_BACK) ? (h_count - H_BACK[15:0]) : 16'd0;
    end

    always_ff @(posedge LCD_CLK or negedge rst_n) begin
        if (!rst_n) begin
            LCD_R <= 5'd0;
            LCD_G <= 6'd0;
            LCD_B <= 5'd0;
        end else if (active) begin
            if (x < 16'd160) begin
                // Red bar
                LCD_R <= 5'd31;
                LCD_G <= 6'd0;
                LCD_B <= 5'd0;
            end else if (x < 16'd320) begin
                // Green bar
                LCD_R <= 5'd0;
                LCD_G <= 6'd63;
                LCD_B <= 5'd0;
            end else begin
                // Blue bar
                LCD_R <= 5'd0;
                LCD_G <= 6'd0;
                LCD_B <= 5'd31;
            end
        end else begin
            // Blanking
            LCD_R <= 5'd0;
            LCD_G <= 6'd0;
            LCD_B <= 5'd0;
        end
    end

    // Heartbeat LED (open-drain style, works on both boards)
    logic [25:0] hb_counter;
    always_ff @(posedge LCD_CLK or negedge rst_n) begin
        if (!rst_n) hb_counter <= 26'd0;
        else hb_counter <= hb_counter + 26'd1;
    end
    assign led = hb_counter[25] ? 1'b0 : 1'bz;

endmodule
