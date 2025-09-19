// Day 01: LED Blink Example Template
// Tang Nano FPGA LED Blink Sample

module top (
    input  wire clk,     // 27MHz clock input
    output wire led      // LED output
);

    // TODO: Clock divider implementation
    // Hint: How to divide 27MHz to approximately 1Hz?

    reg [24:0] counter;

    always_ff @(posedge clk) begin
        // TODO: Write counter increment logic here
        counter <= counter + 1;
    end

    // TODO: LED blink control
    // Hint: Use appropriate bit of counter
    assign led = counter[24];

endmodule