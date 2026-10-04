/* verilator lint_off DECLFILENAME */
module Gowin_rPLL40 (
    output logic clkout,
    output logic locked,
    input  logic clkin
);
    always_comb clkout = clkin;
    always_comb locked = 1'b1;
endmodule
/* verilator lint_on DECLFILENAME */
