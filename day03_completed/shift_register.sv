// Shift Register
// 8ビット シフトレジスタ

module shift_register (
    input  logic clk,
    input  logic rst_n,
    input  logic shift_enable,
    input  logic serial_in,
    input  logic load_enable,
    input  logic [7:0] parallel_data,
    output logic [7:0] shift_data,
    output logic serial_out
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_data <= 8'b0;
        end else if (load_enable) begin
            shift_data <= parallel_data;
        end else if (shift_enable) begin
            shift_data <= {shift_data[6:0], serial_in};
        end
    end

    assign serial_out = shift_data[7];

endmodule