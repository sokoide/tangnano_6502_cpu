// Day 01 Completed: LED Blink (Tang Nano 20K)

module top (
    input  logic clk,  // 27MHz clock input
    output logic led   // LED output
);

    // Clock divider for visible blinking (~0.8Hz)
    // 27MHz / 2^25 ≈ 0.8Hz
    logic [24:0] counter;

    always @(posedge clk) begin
        counter <= counter + 25'd1;
    end

    // Push-pull LED drive
    assign led = counter[24];

endmodule
