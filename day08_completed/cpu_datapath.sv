// 6502 CPU Datapath
// Connects ALU, registers, and memory with proper multiplexing

module cpu_datapath (
    input  logic        clk,
    input  logic        rst_n,

    // Control signals from decoder
    input  logic [3:0]  alu_op,
    input  logic        alu_carry_in,
    input  logic [1:0]  alu_a_sel,
    input  logic [1:0]  alu_b_sel,
    input  logic [2:0]  reg_src_sel,

    // Register control
    input  logic        reg_a_write,
    input  logic        reg_x_write,
    input  logic        reg_y_write,
    input  logic        reg_sp_write,
    input  logic        reg_pc_write,
    input  logic        pc_increment,
    input  logic        sp_push,
    input  logic        sp_pop,

    // Memory interface
    input  logic [7:0]  mem_data_in,
    input  logic [15:0] pc_branch_target,

    // Register outputs (for external use)
    output logic [7:0]  reg_a_out,
    output logic [7:0]  reg_x_out,
    output logic [7:0]  reg_y_out,
    output logic [7:0]  reg_sp_out,
    output logic [15:0] reg_pc_out,

    // ALU outputs
    output logic [7:0]  alu_result,
    output logic        alu_carry_out,
    output logic        alu_overflow,
    output logic        alu_negative,
    output logic        alu_zero
);

    // Internal signals
    logic [7:0] alu_operand_a;
    logic [7:0] alu_operand_b;
    logic [7:0] register_data_in;

    // Register file
    cpu_registers registers (
        .clk(clk),
        .rst_n(rst_n),
        .reg_a_write(reg_a_write),
        .reg_x_write(reg_x_write),
        .reg_y_write(reg_y_write),
        .reg_sp_write(reg_sp_write),
        .reg_pc_write(reg_pc_write),
        .data_in(register_data_in),
        .pc_in(pc_branch_target),
        .pc_increment(pc_increment),
        .sp_push(sp_push),
        .sp_pop(sp_pop),
        .reg_a(reg_a_out),
        .reg_x(reg_x_out),
        .reg_y(reg_y_out),
        .reg_sp(reg_sp_out),
        .reg_pc(reg_pc_out)
    );

    // ALU instance
    cpu_alu alu (
        .operand_a(alu_operand_a),
        .operand_b(alu_operand_b),
        .operation(alu_op),
        .carry_in(alu_carry_in),
        .result(alu_result),
        .carry_out(alu_carry_out),
        .overflow(alu_overflow),
        .negative(alu_negative),
        .zero(alu_zero)
    );

    // ALU A input multiplexer
    always_comb begin
        case (alu_a_sel)
            2'b00: alu_operand_a = reg_a_out;     // Accumulator
            2'b01: alu_operand_a = reg_x_out;     // X register
            2'b10: alu_operand_a = reg_y_out;     // Y register
            2'b11: alu_operand_a = 8'h00;         // Zero
            default: alu_operand_a = reg_a_out;
        endcase
    end

    // ALU B input multiplexer
    always_comb begin
        case (alu_b_sel)
            2'b00: alu_operand_b = mem_data_in;   // Memory data
            2'b01: alu_operand_b = reg_a_out;     // Accumulator
            2'b10: alu_operand_b = reg_x_out;     // X register
            2'b11: alu_operand_b = reg_y_out;     // Y register
            default: alu_operand_b = mem_data_in;
        endcase
    end

    // Register data input multiplexer
    always_comb begin
        case (reg_src_sel)
            3'b000: register_data_in = alu_result;    // ALU result
            3'b001: register_data_in = mem_data_in;   // Memory data
            3'b010: register_data_in = reg_a_out;     // Register transfer
            3'b011: register_data_in = reg_x_out;     // Register transfer
            3'b100: register_data_in = reg_y_out;     // Register transfer
            3'b101: register_data_in = reg_sp_out;    // Stack pointer
            default: register_data_in = alu_result;
        endcase
    end

endmodule