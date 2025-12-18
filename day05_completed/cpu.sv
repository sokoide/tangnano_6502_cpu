module cpu (
    input  logic        clk,
    input  logic        rst_n,      // Active-low reset
    input  logic        pc_enable,  // Enable signal for PC update
    output logic [15:0] address_bus,
    output logic [15:0] debug_pc
);

    logic [15:0] pc;

    // Program Counter
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= 16'h8000;
        end else if (pc_enable) begin
            // For now, just increment PC on every cycle
            pc <= pc + 1;
        end
    end

    assign address_bus = pc;
    assign debug_pc = pc;

endmodule
