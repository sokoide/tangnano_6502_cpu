// Day 08 Completed: Hardware sanity top (Tang Nano 20K)
module top (
    input  wire clk,
    output wire led
);
    reg [24:0] counter;
    always @(posedge clk) counter <= counter + 25'd1;
    assign led = counter[24];
endmodule

