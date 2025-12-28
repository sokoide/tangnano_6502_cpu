// 8-bit Shift Register with Parallel Load
// Useful for serial-to-parallel and parallel-to-serial conversion.
module shift_register (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       shift_enable,
    input  logic       serial_in,
    input  logic       load_enable,
    input  logic [7:0] parallel_data,
    output logic [7:0] shift_data,
    output logic       serial_out
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset to 0
            shift_data <= 8'b0;
        end else if (load_enable) begin
            // Synchronous parallel load
            shift_data <= parallel_data;
        end else if (shift_enable) begin
            // Shift left: bit 0 gets serial_in, other bits shift up.
            shift_data <= {shift_data[6:0], serial_in};
        end
    end

    // MSB is the serial output
    assign serial_out = shift_data[7];

endmodule
