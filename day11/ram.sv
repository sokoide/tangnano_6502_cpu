// ram.sv - 512-byte RAM for Page 0 (ZP) and Page 1 (Stack) ($0000-$01FF)
module ram (
    input  logic       clk,
    input  logic [8:0] addr,      // 9-bit address for $0000-$01FF
    input  logic       write_en,
    input  logic [7:0] din,
    output logic [7:0] dout
);

    logic [7:0] mem[512];

    assign dout = mem[addr];

    always_ff @(posedge clk) begin
        if (write_en) begin
            mem[addr] <= din;
        end
    end

endmodule
