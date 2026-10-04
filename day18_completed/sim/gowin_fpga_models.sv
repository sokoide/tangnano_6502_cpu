// Functional models of the Gowin primitives used by lcd_demo.sv's FPGA branch.
// Compiled only by `make test-lock`, which builds lcd_demo with -UVERILATOR so
// the real non-VERILATOR path (PLL LOCK gating included) is simulated.
// The clocks pass through XTAL_IN (single clock domain); timing is not modeled.
/* verilator lint_off DECLFILENAME */
/* verilator lint_off UNUSEDSIGNAL */

module Gowin_rPLL9 (
    output logic clkout,
    input  logic clkin
);
    assign clkout = clkin;
endmodule

module Gowin_rPLL40 (
    output logic clkout,
    output logic locked,
    input  logic clkin
);
    // Driven hierarchically by the testbench to emulate PLL LOCK.
    logic tb_locked = 1'b0;
    assign clkout = clkin;
    assign locked = tb_locked;
endmodule

// 32KB program RAM (ram.sv FPGA branch). Instruments the write port so the
// testbench can prove writes are gated: write_count counts accepted writes and
// cap0200/cap02ff capture the data last written to the boot window ends.
module Gowin_SDPB (
    output logic [ 7:0] dout,
    input  logic        clka,
    input  logic        cea,
    input  logic        reseta,
    input  logic        clkb,
    input  logic        ceb,
    input  logic        resetb,
    input  logic        oce,
    input  logic [14:0] ada,
    input  logic [ 7:0] din,
    input  logic [14:0] adb
);
    logic   [7:0] mem              [0:32767];
    integer       write_count = 0;
    logic   [7:0] cap0200 = 8'h00;
    logic   [7:0] cap02ff = 8'h00;
    logic         cap0200_v = 1'b0;
    logic         cap02ff_v = 1'b0;

    always @(posedge clka) begin
        if (cea) begin
            mem[ada] <= din;
            write_count = write_count + 1;
            if (ada == 15'h0200) begin
                cap0200   <= din;
                cap0200_v <= 1'b1;
            end
            if (ada == 15'h02FF) begin
                cap02ff   <= din;
                cap02ff_v <= 1'b1;
            end
        end
    end

    always @(posedge clkb) begin
        if (ceb) dout <= mem[adb];
    end
endmodule

// 1KB text VRAM with memory-domain writes and pixel-domain reads.
module Gowin_SDPB_vram (
    output logic [7:0] dout,
    input  logic       clka,
    input  logic       cea,
    input  logic       reseta,
    input  logic       clkb,
    input  logic       ceb,
    input  logic       resetb,
    input  logic       oce,
    input  logic [9:0] ada,
    input  logic [7:0] din,
    input  logic [9:0] adb
);
    logic [7:0] mem[0:1023];

    always @(posedge clka) begin
        if (cea) mem[ada] <= din;
    end

    always @(posedge clkb) begin
        if (ceb) dout <= mem[adb];
    end
endmodule

// 4KB font ROM; the bitmap content is irrelevant to the LOCK gate test.
module Gowin_pROM_font (
    output logic [ 7:0] dout,
    input  logic        clk,
    input  logic        oce,
    input  logic        ce,
    input  logic        reset,
    input  logic [11:0] ad
);
    always @(posedge clk) begin
        dout <= {ad[7:0]} ^ 8'h3C;
    end
endmodule

/* verilator lint_on UNUSEDSIGNAL */
/* verilator lint_on DECLFILENAME */
