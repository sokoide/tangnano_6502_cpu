// Day 03 Completed: Board Wrapper for Tang Nano 20K
module top (
    input  logic       clk,          // 27MHz
    input  logic       ResetButton,  // S1 button (Active High: 1 when pressed)
    output logic [5:0] led           // 6 LEDs (Active Low: 0 = ON)
);
    // Internal reset signal (Active Low: 0 = RESET, 1 = RUN)
    // S1 is Active High, so we invert it to ensure the core runs when the button is NOT pressed.
    logic rst_n;
    assign rst_n = ~ResetButton;

    logic [5:0] leds_internal;

    top_core u_core (
        .clk(clk),
        .rst_n(rst_n),
        .switches(4'b0),
        .leds(leds_internal),
        .pwm_out(),
        .shift_serial_out(),
        .div_clk_out()
    );

    // Invert outputs for Active Low LEDs
    assign led = ~leds_internal;

endmodule
