// Day 01: LED Blink Example Template
// Tang Nano FPGA LED チカチカ サンプル

module top (
    input  wire clk,     // 27MHz clock input
    output wire led      // LED output
);

    // TODO: Clock divider implementation
    // ヒント: 27MHzを約1Hzに分周するには？

    reg [24:0] counter;

    always_ff @(posedge clk) begin
        // TODO: カウンタのインクリメント処理を書いてください
        counter <= counter + 1;
    end

    // TODO: LEDの点滅制御
    // ヒント: counterの適切なビットを使用
    assign led = counter[24];

endmodule