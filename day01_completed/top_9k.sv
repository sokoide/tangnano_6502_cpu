// Day 01: LED Blink Example (Tang Nano 9K)
// This module demonstrates a basic clock divider to blink an LED.

module top (
    input  logic clk,  // 27MHz system clock input from the board oscillator
    output logic led   // Output signal connected to an on-board LED
);

    // 25-bit counter with initialization
    logic [24:0] counter = 0;

    // Sequential logic: updates on the rising edge of the clock
    always_ff @(posedge clk) begin
        counter <= counter + 1;
    end

    // Use bit 24 to toggle the LED
    // A 27MHz clock ticks 27,000,000 times per second.
    // 2^24 is ~16.7M, toggling roughly every 0.6 seconds (full period ~1.2s).
    assign led = ~counter[24];

endmodule
