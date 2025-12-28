// PWM Generator
// PWM信号生成器

// Pulse Width Modulation (PWM) Generator
// Controls the average power delivered by an electrical signal by turning it ON and OFF fast.
module pwm_generator (
    input  logic clk,
    input  logic rst_n,
    input  logic [7:0] duty_cycle,  // 0 (0% ON) to 255 (100% ON)
    output logic pwm_out
);

    logic [7:0] counter;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 8'b0;
        end else begin
            counter <= counter + 1;
        end
    end

    // Combinational comparison
    // If the counter is less than the duty cycle, the output is HIGH.
    assign pwm_out = (counter < duty_cycle);

endmodule
