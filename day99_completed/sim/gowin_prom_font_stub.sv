module Gowin_pROM_font (
    output logic [7:0] dout,
    input  logic       clk,
    input  logic       oce,
    input  logic       ce,
    input  logic       reset,
    input  logic [11:0] ad
);
  logic [7:0] rom [0:4095];

  integer i;
  initial begin
    for (i = 0; i < 4096; i = i + 1) begin
      rom[i] = 8'h00;
    end
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      dout <= 8'h00;
    end else if (ce && oce) begin
      dout <= rom[ad];
    end
  end
endmodule

