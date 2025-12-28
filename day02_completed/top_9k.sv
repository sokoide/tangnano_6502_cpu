// Day 02 Completed: Hardware sanity top (Tang Nano 9K)
// In Day 02, we blink the LED faster (~4x) than Day 01 to confirm the update.

module top (
    input  logic clk,  // 27MHz clock
    output logic led   // On-board LED
);

    logic [24:0] counter = 0;

    always_ff @(posedge clk) begin
        counter <= counter + 1;
    end

    // Use bit 22 for faster blinking (approx 0.3s period)
    // Tang Nano 9K LED is Active Low (0 = ON).
    assign led = ~counter[22];

endmodule
