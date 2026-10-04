/* verilator lint_off DECLFILENAME */
module Gowin_rPLL40 (
    output logic clkout,
    output logic locked,
    input  logic clkin
);
    always_comb clkout = clkin;
    assign locked = 1'b1;  // Simulation model: PLL is always locked
endmodule
/* verilator lint_on DECLFILENAME */
