// ram.sv - 32KB RAM for Page 0-127 ($0000-$7FFF)
// Aligned with Day 99 specifications.

module ram (
    input  logic        clk,
    input  logic [14:0] addr,      // 15-bit address for $0000-$7FFF
    input  logic        write_en,
    input  logic [ 7:0] din,
    output logic [ 7:0] dout
);

`ifdef VERILATOR
    // One-clock read latency, matching the clocked BSRAM interface.
    logic [7:0] mem[32768];

    always_ff @(posedge clk) begin
        dout <= mem[addr];  // No consumer may depend on same-edge read/write collision data.
        if (write_en) begin
            mem[addr] <= din;
        end
    end
`else
    // Hardware implementation using Gowin BSRAM primitive
    Gowin_SDPB ram_inst (
        .dout(dout),
        .clka(clk),
        .cea(write_en),
        .reseta(1'b0),
        .clkb(clk),
        .ceb(1'b1),
        .resetb(1'b0),
        .oce(1'b0),
        .ada(addr),
        .din(din),
        .adb(addr)
    );
`endif

endmodule
