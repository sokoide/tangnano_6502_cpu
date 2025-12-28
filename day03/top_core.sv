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

    // Power-on Reset (POR) to ensure stable start
    logic [3:0] por_counter = 0;
    logic internal_rst_n;
    always_ff @(posedge clk) begin
        if (por_counter < 4'd15) begin
            por_counter <= por_counter + 1;
            internal_rst_n <= 1'b0;
        end else begin
            internal_rst_n <= rst_n;
        end
    end

    // Clock divider (27MHz to ~1Hz for visible operation)
    clock_divider clk_div (
        .clk_in   (clk),
        .rst_n    (internal_rst_n),
        .div_ratio(4'd10),           // Divide by 10
        .clk_out  (slow_clk)
    );

    // Enable counter every ~0.5s for clearly visible incrementing
    logic [23:0] enable_counter;
    always_ff @(posedge clk or negedge internal_rst_n) begin
        if (!internal_rst_n) begin
            enable_counter <= 24'b0;
            counter_enable <= 1'b0;
        end else begin
            if (enable_counter == 24'd13_499_999) begin  // 0.5 sec @ 27MHz
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
        .rst_n(internal_rst_n),
        .enable(counter_enable),
        .count(count_out),
        .overflow(counter_overflow)
    );

    // PWM generator - duty cycle controlled by switches
    assign pwm_duty = {switches, 4'b0000};  // Extend switches to 8 bits

    pwm_generator pwm (
        .clk(clk),
        .rst_n(internal_rst_n),
        .duty_cycle(pwm_duty),
        .pwm_out(pwm_out)
    );

    // Traffic light controller
    traffic_light traffic (
        .clk(clk),
        .rst_n(internal_rst_n),
        .red(red_led),
        .yellow(yellow_led),
        .green(green_led)
    );

    // Shift register
    shift_register shifter (
        .clk          (slow_clk),         // Use slow clock for visible shifting
        .rst_n        (rst_n),
        .shift_enable (1'b1),             // Always shifting
        .serial_in    (switches[0]),      // Input from switch 0
        .load_enable  (switches[1]),      // Load enable from switch 1
        .parallel_data(count_out),        // Load counter value
        .shift_data   (),                 // Not used in this demo
        .serial_out   (shift_serial_out)
    );

    assign leds[0] = red_led;
    assign leds[1] = yellow_led;
    assign leds[2] = green_led;
    // Use low bits of counter since we now have a slow counter_enable
    assign leds[3] = count_out[0];
    assign leds[4] = count_out[1];
    assign leds[5] = count_out[2];

    // Clock divider output
    assign div_clk_out = slow_clk;

endmodule
