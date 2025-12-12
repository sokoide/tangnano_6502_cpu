// Simulation stub for Gowin PLL wrapper used on Tang Nano boards.
// Hardware builds should use the vendor-provided netlist under gowin_rpll_*.

module Gowin_rPLL9 (
    output logic clkout,
    input  logic clkin
);
    always_comb clkout = clkin;
endmodule
