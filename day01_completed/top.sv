// Day 01 Completed: LED Blink
// Tang Nano FPGA LED Blink Complete Version

module top (
    input  wire clk,     // 27MHz clock input
    output wire led      // LED output
);

    // Clock divider for visible blinking (~0.8Hz)
    // 27MHz / 2^25 ≈ 0.8Hz
    reg [24:0] counter;

    always_ff @(posedge clk) begin
        counter <= counter + 1;
    end

    // LED blinking using MSB of counter
    assign led = counter[24];

endmodule