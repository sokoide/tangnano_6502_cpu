// Day 03 Completed: SystemVerilog Sequential Circuits
// Integrated test module for sequential circuits

module top (
    input  wire clk,
    input  wire rst_n,
    input  wire [3:0] switches,        // Input switches
    output wire [7:0] count_out,       // Counter output
    output wire pwm_out,               // PWM output
    output wire red_led,               // Traffic light red
    output wire yellow_led,            // Traffic light yellow
    output wire green_led,             // Traffic light green
    output wire shift_serial_out,      // Shift register serial output
    output wire div_clk_out            // Divided clock output
);

    // Internal signals
    logic slow_clk;
    logic counter_enable;
    logic counter_overflow;
    logic [7:0] pwm_duty;

    // Clock divider (27MHz to ~1Hz for visible operation)
    clock_divider clk_div (
        .clk_in(clk),
        .rst_n(rst_n),
        .div_ratio(4'd10),             // Divide by 10
        .clk_out(slow_clk)
    );

    // Enable counter every 1000 fast clocks for visible counting
    logic [9:0] enable_counter;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_counter <= 10'b0;
            counter_enable <= 1'b0;
        end else begin
            if (enable_counter == 10'd999) begin
                enable_counter <= 10'b0;
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
    assign pwm_duty = {switches, 4'b0000};  // Extend switches to 8 bits

    pwm_generator pwm (
        .clk(clk),
        .rst_n(rst_n),
        .duty_cycle(pwm_duty),
        .pwm_out(pwm_out)
    );

    // Traffic light controller
    traffic_light traffic (
        .clk(clk),
        .rst_n(rst_n),
        .red(red_led),
        .yellow(yellow_led),
        .green(green_led)
    );

    // Shift register
    shift_register shifter (
        .clk(slow_clk),                // Use slow clock for visible shifting
        .rst_n(rst_n),
        .shift_enable(1'b1),           // Always shifting
        .serial_in(switches[0]),       // Input from switch 0
        .load_enable(switches[1]),     // Load enable from switch 1
        .parallel_data(count_out),     // Load counter value
        .shift_data(),                 // Not used in this demo
        .serial_out(shift_serial_out)
    );

    // Clock divider output
    assign div_clk_out = slow_clk;

endmodule