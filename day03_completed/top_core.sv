/* verilator lint_off PINCONNECTEMPTY */
/* verilator lint_off UNUSEDSIGNAL */
// Day 03 Completed: SystemVerilog Sequential Circuits
// Integrated test module for sequential circuits

module top_core (
    input  logic       clk,
    input  logic       rst_n,
    input  logic [3:0] switches,          // Input switches
    output logic [5:0] leds,              // 6 LEDs
    output logic       pwm_out,           // PWM output
    output logic       shift_serial_out,  // Shift register serial output
    output logic       div_clk_out        // Divided clock output
);

    // Internal signals
    logic [7:0] count_out;
    logic slow_clk;
    logic counter_enable;
    logic counter_overflow;
    logic [7:0] pwm_duty;
    logic red_led, yellow_led, green_led;

    // Clock divider (27MHz to ~1Hz for visible operation)
    clock_divider clk_div (
        .clk_in   (clk),
        .rst_n    (rst_n),
        .div_ratio(4'd10),    // Divide by 10
        .clk_out  (slow_clk)
    );

    // Enable counter every ~0.1s for fast visible movement (2.7M cycles @ 27MHz)
    logic [23:0] enable_counter;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_counter <= 24'b0;
            counter_enable <= 1'b0;
        end else begin
            if (enable_counter >= 24'd2_699_999) begin
                enable_counter <= 24'b0;
                counter_enable <= 1'b1;
            end else begin
                enable_counter <= enable_counter + 1;
                counter_enable <= 1'b0;
            end
        end
    end

    // 8-bit counter
    counter_8bit counter (
        .clk(clk),
        .rst_n(rst_n),
        .enable(counter_enable),
        .count(count_out),
        .overflow(counter_overflow)
    );

    // PWM generator - duty cycle controlled by switches
    assign pwm_duty = {switches, 4'b0000};

    pwm_generator pwm (
        .clk(clk),
        .rst_n(rst_n),
        .duty_cycle(pwm_duty),
        .pwm_out(pwm_out)
    );

    // Traffic light controller with parameters for faster switching
    traffic_light #(
        .TIMER_LIMIT_RED(26'd13_500_000),  // 0.5s
        .TIMER_LIMIT_GREEN(26'd13_500_000),  // 0.5s
        .TIMER_LIMIT_YELLOW(26'd6_750_000)  // 0.25s
    ) traffic (
        .clk(clk),
        .rst_n(rst_n),
        .red(red_led),
        .yellow(yellow_led),
        .green(green_led)
    );

    // Shift register (connected but not driving LEDs in this core mapping)
    shift_register shifter (
        .clk          (slow_clk),
        .rst_n        (rst_n),
        .shift_enable (1'b1),
        .serial_in    (switches[0]),
        .load_enable  (switches[1]),
        .parallel_data(count_out),
        .shift_data   (),
        .serial_out   (shift_serial_out)
    );

    // Map traffic light and counter to LEDs (Active High internally)
    assign leds[0] = red_led;
    assign leds[1] = yellow_led;
    assign leds[2] = green_led;
    assign leds[3] = count_out[0];
    assign leds[4] = count_out[1];
    assign leds[5] = count_out[2];

    assign div_clk_out = slow_clk;

endmodule
