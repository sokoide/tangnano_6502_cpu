// Day 04 Completed: Hardware sanity top (Tang Nano 20K)
module top_unused (
    input  logic clk,
    output logic led
);
    logic [24:0] counter;
    always @(posedge clk) counter <= counter + 25'd1;
    assign led = counter[24];
endmodule
