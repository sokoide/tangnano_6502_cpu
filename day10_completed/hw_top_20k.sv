// Day 10 Completed: Hardware sanity top (Tang Nano 20K)
module top (
    input  wire XTAL_IN,
    output wire led
);
    reg [24:0] counter;
    always @(posedge XTAL_IN) counter <= counter + 25'd1;
    assign led = counter[24];
endmodule
