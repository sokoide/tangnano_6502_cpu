// 6502 Stack Pointer Implementation
// Stack grows downward from $01FF to $0100

module stack_pointer (
    input  logic       clk,
    input  logic       rst_n,

    // Stack operations
    input  logic       push,
    input  logic       pop,
    input  logic       load_sp,      // Load SP with immediate value
    input  logic [7:0] sp_data,      // Data for SP load

    // Stack pointer output
    output logic [7:0] sp,

    // Stack address output (always in page 1: $01xx)
    output logic [15:0] stack_addr,

    // Status flags
    output logic       stack_overflow,
    output logic       stack_underflow
);

    logic [7:0] stack_pointer;
    logic       overflow_flag;
    logic       underflow_flag;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stack_pointer <= 8'hFF;      // Initialize to $01FF
            overflow_flag <= 1'b0;
            underflow_flag <= 1'b0;
        end else begin
            overflow_flag <= 1'b0;
            underflow_flag <= 1'b0;

            if (load_sp) begin
                stack_pointer <= sp_data;
            end else if (push) begin
                if (stack_pointer == 8'h00) begin
                    overflow_flag <= 1'b1;   // Stack overflow
                end else begin
                    stack_pointer <= stack_pointer - 1;
                end
            end else if (pop) begin
                if (stack_pointer == 8'hFF) begin
                    underflow_flag <= 1'b1;  // Stack underflow
                end else begin
                    stack_pointer <= stack_pointer + 1;
                end
            end
        end
    end

    // Outputs
    assign sp = stack_pointer;
    assign stack_addr = {8'h01, stack_pointer};  // Always in page 1
    assign stack_overflow = overflow_flag;
    assign stack_underflow = underflow_flag;

endmodule