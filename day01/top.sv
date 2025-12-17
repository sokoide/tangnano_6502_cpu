// Day 01: LED Blink Example Template
// Tang Nano FPGA LED Blink Sample

module top (
    input  logic clk,  // 27MHz clock input
    output logic led   // LED output
);

    // 25-bit counter to divide 27MHz clock
    logic [24:0] counter;

    always_ff @(posedge clk) begin
        counter <= counter + 1;
    end

    // Use the most significant bit to toggle the LED
    assign led = counter[24];

endmodule
