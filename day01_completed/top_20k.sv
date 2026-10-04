// Day 01: LED Blink Example (Tang Nano 20K)
// This module demonstrates a basic clock divider to blink an LED.

module top (
    input  logic clk,  // 27MHz system clock input from the board oscillator
    output logic led   // Output signal connected to an on-board LED
);

    // 25-bit counter. 
    // A 27MHz clock ticks 27,000,000 times per second.
    // 2^25 is approximately 33,554,432.
    // Bit 24 changes every 2^24 clocks (0.621s); its full cycle is 1.243s.
    logic [24:0] counter = 0;

    // Sequential logic: updates on the rising edge of the clock
    always_ff @(posedge clk) begin
        // The counter increments by 1 every clock cycle
        counter <= counter + 1'b1;
    end

    // Combinational logic: continuous assignment
    // The 'led' signal always reflects the state of the counter's most significant bit.
    // The Tang Nano 20K on-board LED is active-low (0 = ON), so invert the bit.
    // When counter[24] is 1, the LED is ON; when it's 0, the LED is OFF.
    assign led = ~counter[24];

endmodule
