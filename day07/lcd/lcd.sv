// Pixel-domain pipeline: synchronous VRAM -> synchronous font ROM -> RGB/DE.
// DE is delayed with the pixel metadata by two edges relative to the beam.
`include "include/consts.svh"
module lcd (
    input logic PixelClk, nRST,
    input logic [7:0] v_dout, f_dout,
    output logic LCD_DE,
    output logic [4:0] LCD_B, LCD_R,
    output logic [5:0] LCD_G,
    output logic [9:0] v_adb,
    output logic [11:0] f_ad,
    output logic vsync
);
    logic [15:0] H_PixelCount, V_PixelCount;
    logic valid0, valid1, error1;
    logic [3:0] row0;
    logic [2:0] bit0, bit1;
    int unsigned x, y;
    logic active;
    always_comb begin
        active = H_PixelCount >= H_BackPorch && H_PixelCount < H_BackPorch + H_PixelValid
                    && V_PixelCount >= V_BackPorch && V_PixelCount < V_BackPorch + V_PixelValid;
        x = active ? int'(H_PixelCount) - H_BackPorch : 0;
        y = active ? int'(V_PixelCount) - V_BackPorch : 0;
        v_adb = 10'(x / int'(CHAR_WIDTH) + (y / int'(CHAR_HEIGHT)) * int'(COLUMNS));
        f_ad = {v_dout, row0};
    end
    always_ff @(posedge PixelClk or negedge nRST) begin
        if (!nRST) begin
            H_PixelCount <= 0;
            V_PixelCount <= 0;
            vsync <= 0;
            valid0 <= 0; valid1 <= 0; error1 <= 0;
            row0 <= 0; bit0 <= 0; bit1 <= 0;
            LCD_DE <= 0; LCD_R <= 0; LCD_G <= 0; LCD_B <= 0;
        end else begin
            if (H_PixelCount == PixelForHS - 1) begin
                H_PixelCount <= 0;
                if (V_PixelCount == PixelForVS - 1) V_PixelCount <= 0;
                else V_PixelCount <= V_PixelCount + 1'b1;
            end else H_PixelCount <= H_PixelCount + 1'b1;
            // Registered source; CPU synchronizes this single bit in its own domain.
            vsync <= V_PixelCount < V_BackPorch || V_PixelCount >= V_BackPorch + V_PixelValid;
            valid0 <= active; row0 <= 4'(y); bit0 <= 3'(x);
            valid1 <= valid0; bit1 <= bit0; error1 <= v_dout > CHAR_CODE_MAX;
            LCD_DE <= valid1;
            if (!valid1) begin
                LCD_R <= LCD_RED_BORDER; LCD_G <= LCD_GREEN_BORDER; LCD_B <= LCD_BLUE_BORDER;
            end else if (error1) begin
                LCD_R <= LCD_RED_ERROR; LCD_G <= LCD_GREEN_ERROR; LCD_B <= LCD_BLUE_ERROR;
            end else if (f_dout[7-bit1]) begin
                LCD_R <= LCD_RED_ON; LCD_G <= LCD_GREEN_ON; LCD_B <= LCD_BLUE_ON;
            end else begin
                LCD_R <= LCD_RED_OFF; LCD_G <= LCD_GREEN_OFF; LCD_B <= LCD_BLUE_OFF;
            end
        end
    end
endmodule
