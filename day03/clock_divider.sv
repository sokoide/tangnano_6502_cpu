// Integer clock divider. Prefer clock enables for internal synchronous logic.
module clock_divider (
    input logic clk_in,
    input logic rst_n,
    input logic [3:0] div_ratio,  // 0: disabled, 1: bypass, 2..15: integer division
    output logic clk_out
);
    logic [3:0] counter;
    always_ff @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) counter <= 4'd0;
        else if (div_ratio <= 4'd1 || counter >= div_ratio - 4'd1) counter <= 4'd0;
        else counter <= counter + 4'd1;
    end
    // Even ratios: 50%; odd ratios: floor(N/2)/N. Change ratio during reset.
    assign clk_out = !rst_n || div_ratio == 4'd0 ? 1'b0 :
                     div_ratio == 4'd1 ? clk_in : counter < (div_ratio >> 1);
endmodule
