// Day 03 Completed: Board Wrapper for Tang Nano 20K
module top (
    input  logic       clk,      // 27MHz
    input  logic       ResetButton,
    output logic [5:0] led       // 6 LEDs
);
    // Invert ResetButton: S1 is 0 when pressed, so ~ResetButton is 1 when pressed.
    // However, the core logic expects internal_rst_n to be 1 for RUNNING.
    // So if we want it to RUN when NOT pressed:
    logic internal_rst_n;
    assign internal_rst_n = ResetButton; // Use the raw signal if the core is Active Low

    // If it currently works ONLY when pressed (ResetButton=0), then:
    // Pressed: ResetButton=0 -> Core sees 0 -> Reset? No, user says it works.
    // This is strange. Let's explicitly define it to be 1 (RUN) when NOT pressed.
    logic rst_n;
    assign rst_n = ~ResetButton; // Invert: Now it should RUN when NOT pressed (1) and RESET when pressed (0).

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

    // Tang Nano 20K LEDs are Active Low (0 = ON).
    assign led = ~leds_internal;

endmodule