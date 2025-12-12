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
  logic [7:0] mem [0:1023];

  integer i;
  initial begin
    for (i = 0; i < 1024; i = i + 1) begin
      mem[i] = 8'h00;
    end
    dout = 8'h00;
  end

  always_ff @(posedge clka) begin
    if (reseta) begin
      // No-op: keep memory contents
    end else if (cea) begin
      mem[ada] <= din;
    end
  end

  always_ff @(posedge clkb) begin
    if (resetb) begin
      dout <= 8'h00;
    end else if (ceb && oce) begin
      dout <= mem[adb];
    end
  end
endmodule

