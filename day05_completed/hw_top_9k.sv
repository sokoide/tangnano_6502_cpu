// Day 05 Completed: Hardware sanity top (Tang Nano 9K)
// Open-drain style LED: ON=0, OFF=Z (for 1.8V bank LED pins)
module top (
    input  logic clk,
    output logic led
);
    logic [24:0] counter;
    always @(posedge clk) counter <= counter + 25'd1;
    assign led = counter[24] ? 1'b0 : 1'bz;
endmodule
