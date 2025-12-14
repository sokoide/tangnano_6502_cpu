// Day 01 Completed: LED Blink (Tang Nano 9K)
//
// Note: On some Tang Nano 9K builds, the user LED pin sits in a 1.8V bank.
// Driving it high may leave the LED dimly on. This version uses a simple
// open-drain style output: drive LOW to turn LED on, Hi-Z to turn it off.

module top (
    input  wire clk,     // 27MHz clock input
    output wire led      // LED output (tri-stated when "off")
);

    logic [24:0] counter;

    always @(posedge clk) begin
        counter <= counter + 25'd1;
    end

    // Open-drain style: ON = 0, OFF = Z
    assign led = counter[24] ? 1'b0 : 1'bz;

endmodule

