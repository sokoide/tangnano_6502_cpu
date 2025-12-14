// Day 02 Completed: Hardware sanity top (Tang Nano 20K)
module top (
    input  logic clk,
    output logic led
);
    logic [24:0] counter;
    always @(posedge clk) counter <= counter + 25'd1;
    assign led = counter[24];
endmodule
