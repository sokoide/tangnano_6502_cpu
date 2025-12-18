// ram.sv - 256-byte RAM for Stack ($0100-$01FF)
module ram (
    input  logic       clk,
    input  logic [7:0] addr,    // 8-bit offset within page 1
    input  logic       write_en,
    input  logic [7:0] din,
    output logic [7:0] dout
);

    logic [7:0] mem [256];

    assign dout = mem[addr];

    always_ff @(posedge clk) begin
        if (write_en) begin
            mem[addr] <= din;
        end
    end

endmodule
