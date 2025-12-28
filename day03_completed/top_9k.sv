// Day 03 Completed: Board Wrapper for Tang Nano 9K
module top (
    input  logic       clk,          // 27MHz
    input  logic       ResetButton,
    output logic [5:0] led           // 6 LEDs
);
    logic rst_n;
    assign rst_n = ResetButton;

    logic [5:0] leds_internal;

    top_core u_core (
        .clk(clk),
        .rst_n(rst_n),
        .switches(4'b0),  // No switches used yet
        .leds(leds_internal),
        .pwm_out(),
        .shift_serial_out(),
        .div_clk_out()
    );

    // Invert LEDs for Tang Nano 9K (Active Low)
    assign led = ~leds_internal;

endmodule
