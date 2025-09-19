// 6502 CPU Register File
// Complete register set with proper 6502 behavior

module cpu_registers (
    input  logic        clk,
    input  logic        rst_n,

    // Register write enables
    input  logic        reg_a_write,
    input  logic        reg_x_write,
    input  logic        reg_y_write,
    input  logic        reg_sp_write,
    input  logic        reg_pc_write,

    // Data input (from ALU or memory)
    input  logic [7:0]  data_in,

    // Program counter control
    input  logic [15:0] pc_in,           // For jumps/branches
    input  logic        pc_increment,    // Normal instruction fetch

    // Stack pointer control
    input  logic        sp_push,
    input  logic        sp_pop,

    // Register outputs
    output logic [7:0]  reg_a,
    output logic [7:0]  reg_x,
    output logic [7:0]  reg_y,
    output logic [7:0]  reg_sp,
    output logic [15:0] reg_pc
);

    // Internal registers
    logic [7:0]  accumulator;
    logic [7:0]  index_x;
    logic [7:0]  index_y;
    logic [7:0]  stack_pointer;
    logic [15:0] program_counter;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            accumulator <= 8'h00;
            index_x <= 8'h00;
            index_y <= 8'h00;
            stack_pointer <= 8'hFF;      // Stack starts at $01FF
            program_counter <= 16'hC000; // Boot from ROM
        end else begin
            // Register updates
            if (reg_a_write) begin
                accumulator <= data_in;
            end

            if (reg_x_write) begin
                index_x <= data_in;
            end

            if (reg_y_write) begin
                index_y <= data_in;
            end

            if (reg_sp_write) begin
                stack_pointer <= data_in;
            end

            // Program counter control
            if (reg_pc_write) begin
                program_counter <= pc_in;
            end else if (pc_increment) begin
                program_counter <= program_counter + 1;
            end

            // Stack pointer control
            if (sp_push) begin
                stack_pointer <= stack_pointer - 1;
            end else if (sp_pop) begin
                stack_pointer <= stack_pointer + 1;
            end
        end
    end

    // Output assignments
    assign reg_a = accumulator;
    assign reg_x = index_x;
    assign reg_y = index_y;
    assign reg_sp = stack_pointer;
    assign reg_pc = program_counter;

endmodule