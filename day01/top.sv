// Day 01: LED Blink Example
// This module demonstrates a basic clock divider to blink an LED.

module top (
    input  logic clk,  // 27MHz system clock input from the board oscillator
    output logic led   // Output signal connected to an on-board LED
);

    // 25-bit counter. 
    // A 27MHz clock ticks 27,000,000 times per second.
    // 2^25 is approximately 33,554,432.
    // By using the 25th bit (MSB), the LED will toggle roughly every 1.24 seconds 
    // (33.5M / 27M), resulting in a visible blink.
    logic [24:0] counter;

    // Sequential logic: updates on the rising edge of the clock
    // We initialize the counter to 0 to ensure a predictable starting state.
    always_ff @(posedge clk) begin
        counter <= counter + 1;
    end

    // Combinational logic: continuous assignment
    // The 'led' signal always reflects the state of the counter's bit.
    // 
    // [Note for Beginners]
    // Different boards may have different LED polarities and clock behaviors:
    // - Tang Nano 20K: LED is often Active High (1 = ON). Use 'assign led = counter[24];'
    // - Tang Nano 9K: LED is often Active Low (0 = ON). Use 'assign led = ~counter[24];'
    // If the LED is always ON or OFF, try inverting the signal with '~'.
    // If the blink is too slow, try using a lower bit like 'counter[22]'.
    assign led = counter[24];

endmodule
