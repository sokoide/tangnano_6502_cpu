// ram.sv - 1024-byte RAM for Page 0-3 ($0000-$03FF)
module ram (
    input  logic       clk,
    input  logic [9:0] addr,    // 10-bit address for $0000-$03FF
    input  logic       write_en,
    input  logic [7:0] din,
    output logic [7:0] dout
);

    logic [7:0] mem [1024];

    assign dout = mem[addr];

    always_ff @(posedge clk) begin
        if (write_en) begin
            mem[addr] <= din;
        end
    end

endmodule
