// Project-owned PLL adapter. Vendor/generated sources remain unchanged.
`timescale 1ns/1ps
module platform_pll #(parameter bit MEMORY = 0, BOARD_20K = 0)(
  input logic clkin, rst_n, output wire clkout, output logic locked
);
`ifdef VERILATOR
  logic oscillator = 0;
  // Testbench may force this low to exercise lock loss without stopping clocks.
  logic lock_available = 1;
  initial forever #(MEMORY ? (BOARD_20K ? 12.345679 : 15.873016) : 55.555556) oscillator = ~oscillator;
  assign clkout = oscillator;
  logic [3:0] lock_count;
  always @(posedge clkin or negedge rst_n) begin
    if (!rst_n) begin lock_count <= 0; locked <= 0; end
    else if (!lock_available) begin lock_count <= 0; locked <= 0; end
    else if (lock_count != 15) begin lock_count <= lock_count + 1'b1; locked <= 0; end
    else locked <= 1;
  end
`else

wire clkoutp_o;
wire clkoutd_o;
wire clkoutd3_o;
wire gw_gnd;

assign gw_gnd = 1'b0;

rPLL rpll_inst (
    .CLKOUT(clkout),
    .LOCK(locked),
    .CLKOUTP(clkoutp_o),
    .CLKOUTD(clkoutd_o),
    .CLKOUTD3(clkoutd3_o),
    .RESET(!rst_n),
    .RESET_P(gw_gnd),
    .CLKIN(clkin),
    .CLKFB(gw_gnd),
    .FBDSEL({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .IDSEL({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .ODSEL({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .PSDA({gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .DUTYDA({gw_gnd,gw_gnd,gw_gnd,gw_gnd}),
    .FDLY({gw_gnd,gw_gnd,gw_gnd,gw_gnd})
);

defparam rpll_inst.FCLKIN = "27";
defparam rpll_inst.DYN_IDIV_SEL = "false";
// GW1NR-9 runs the CPU/memory clock at 31.5MHz (27MHz * 7 / 6) to
// meet the measured timing limit. GW2AR-18 retains the 40.5MHz setting.
defparam rpll_inst.IDIV_SEL = MEMORY ? (BOARD_20K ? 1 : 5) : 2;
defparam rpll_inst.DYN_FBDIV_SEL = "false";
defparam rpll_inst.FBDIV_SEL = MEMORY ? (BOARD_20K ? 2 : 6) : 0;
defparam rpll_inst.DYN_ODIV_SEL = "false";
defparam rpll_inst.ODIV_SEL = MEMORY ? 16 : (BOARD_20K ? 64 : 48);
defparam rpll_inst.PSDA_SEL = "0000";
defparam rpll_inst.DYN_DA_EN = "true";
defparam rpll_inst.DUTYDA_SEL = "1000";
defparam rpll_inst.CLKOUT_FT_DIR = 1'b1;
defparam rpll_inst.CLKOUTP_FT_DIR = 1'b1;
defparam rpll_inst.CLKOUT_DLY_STEP = 0;
defparam rpll_inst.CLKOUTP_DLY_STEP = 0;
defparam rpll_inst.CLKFB_SEL = "internal";
defparam rpll_inst.CLKOUT_BYPASS = "false";
defparam rpll_inst.CLKOUTP_BYPASS = "false";
defparam rpll_inst.CLKOUTD_BYPASS = "false";
defparam rpll_inst.DYN_SDIV_SEL = 2;
defparam rpll_inst.CLKOUTD_SRC = "CLKOUT";
defparam rpll_inst.CLKOUTD3_SRC = "CLKOUT";
defparam rpll_inst.DEVICE = BOARD_20K ? "GW2AR-18C" : "GW1NR-9C";

`endif
endmodule

module platform_clocks #(parameter bit BOARD_20K = 0)(
  input logic clkin, rst_n,
  output wire pixel_clk, memory_clk,
  output wire pixel_locked, memory_locked
);
  platform_pll #(.BOARD_20K(BOARD_20K)) pixel_pll(
    .clkin(clkin), .rst_n(rst_n), .clkout(pixel_clk), .locked(pixel_locked));
  platform_pll #(.MEMORY(1), .BOARD_20K(BOARD_20K)) memory_pll(
    .clkin(clkin), .rst_n(rst_n), .clkout(memory_clk), .locked(memory_locked));
endmodule
