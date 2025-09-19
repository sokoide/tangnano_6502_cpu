// Clock Divider
// 可変分周器

module clock_divider (
    input  logic clk_in,
    input  logic rst_n,
    input  logic [3:0] div_ratio,  // 分周比 (1-15)
    output logic clk_out
);

    logic [3:0] counter;
    logic [3:0] threshold;

    // 分周比の半分を閾値とする (50% duty cycle)
    assign threshold = div_ratio >> 1;

    always_ff @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 4'b0;
            clk_out <= 1'b0;
        end else begin
            if (counter >= div_ratio - 1) begin
                counter <= 4'b0;
                clk_out <= 1'b0;
            end else begin
                counter <= counter + 1;
                if (counter >= threshold) begin
                    clk_out <= 1'b1;
                end else begin
                    clk_out <= 1'b0;
                end
            end
        end
    end

endmodule