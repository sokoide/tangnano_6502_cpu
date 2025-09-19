// Complete 6502 CPU Core
// Integrates all components into a working CPU

module cpu_core (
    input  logic        clk,
    input  logic        rst_n,

    // Memory interface
    output logic [15:0] mem_addr,
    output logic [7:0]  mem_data_out,
    input  logic [7:0]  mem_data_in,
    output logic        mem_read,
    output logic        mem_write,
    input  logic        mem_ready,

    // Interrupt inputs
    input  logic        irq_n,
    input  logic        nmi_n,

    // Debug outputs
    output logic [7:0]  debug_reg_a,
    output logic [7:0]  debug_reg_x,
    output logic [7:0]  debug_reg_y,
    output logic [7:0]  debug_reg_sp,
    output logic [15:0] debug_reg_pc,
    output logic [7:0]  debug_status_reg,
    output logic [7:0]  debug_opcode,
    output logic [2:0]  debug_cpu_state,
    output logic [7:0]  debug_alu_result
);

    // Internal signals
    logic [3:0]  alu_op;
    logic        alu_carry_in;
    logic [1:0]  alu_a_sel;
    logic [1:0]  alu_b_sel;
    logic [2:0]  reg_src_sel;

    logic        reg_a_write;
    logic        reg_x_write;
    logic        reg_y_write;
    logic        reg_sp_write;
    logic        reg_pc_write;
    logic        pc_increment;
    logic        sp_push;
    logic        sp_pop;

    logic        update_nz;
    logic        update_c;
    logic        update_v;
    logic        manual_set_c;
    logic        manual_clear_c;

    logic [15:0] pc_branch_target;

    logic [7:0]  reg_a_out;
    logic [7:0]  reg_x_out;
    logic [7:0]  reg_y_out;
    logic [7:0]  reg_sp_out;
    logic [15:0] reg_pc_out;

    logic [7:0]  alu_result;
    logic        alu_carry_out;
    logic        alu_overflow;
    logic        alu_negative;
    logic        alu_zero;

    logic [7:0]  status_reg;
    logic [1:0]  instruction_length;

    // CPU Datapath
    cpu_datapath datapath (
        .clk(clk),
        .rst_n(rst_n),
        .alu_op(alu_op),
        .alu_carry_in(alu_carry_in),
        .alu_a_sel(alu_a_sel),
        .alu_b_sel(alu_b_sel),
        .reg_src_sel(reg_src_sel),
        .reg_a_write(reg_a_write),
        .reg_x_write(reg_x_write),
        .reg_y_write(reg_y_write),
        .reg_sp_write(reg_sp_write),
        .reg_pc_write(reg_pc_write),
        .pc_increment(pc_increment),
        .sp_push(sp_push),
        .sp_pop(sp_pop),
        .mem_data_in(mem_data_in),
        .pc_branch_target(pc_branch_target),
        .reg_a_out(reg_a_out),
        .reg_x_out(reg_x_out),
        .reg_y_out(reg_y_out),
        .reg_sp_out(reg_sp_out),
        .reg_pc_out(reg_pc_out),
        .alu_result(alu_result),
        .alu_carry_out(alu_carry_out),
        .alu_overflow(alu_overflow),
        .alu_negative(alu_negative),
        .alu_zero(alu_zero)
    );

    // Status Register
    status_register status_reg_inst (
        .clk(clk),
        .rst_n(rst_n),
        .update_n(update_nz),
        .update_z(update_nz),
        .update_c(update_c),
        .update_v(update_v),
        .new_n(alu_negative),
        .new_z(alu_zero),
        .new_c(alu_carry_out),
        .new_v(alu_overflow),
        .set_i(1'b0),           // Interrupt disable control
        .clear_i(1'b0),
        .set_d(1'b0),           // Decimal mode control
        .clear_d(1'b0),
        .set_b(1'b0),           // Break flag control
        .clear_b(1'b0),
        .manual_set_c(manual_set_c),
        .manual_clear_c(manual_clear_c),
        .status_reg(status_reg)
    );

    // Control Unit
    cpu_control_unit control_unit (
        .clk(clk),
        .rst_n(rst_n),
        .mem_data_in(mem_data_in),
        .mem_addr(mem_addr),
        .mem_data_out(mem_data_out),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_ready(mem_ready),
        .reg_a(reg_a_out),
        .reg_x(reg_x_out),
        .reg_y(reg_y_out),
        .reg_sp(reg_sp_out),
        .reg_pc(reg_pc_out),
        .alu_result(alu_result),
        .alu_carry_out(alu_carry_out),
        .alu_overflow(alu_overflow),
        .alu_negative(alu_negative),
        .alu_zero(alu_zero),
        .status_reg(status_reg),
        .alu_op(alu_op),
        .alu_carry_in(alu_carry_in),
        .alu_a_sel(alu_a_sel),
        .alu_b_sel(alu_b_sel),
        .reg_src_sel(reg_src_sel),
        .reg_a_write(reg_a_write),
        .reg_x_write(reg_x_write),
        .reg_y_write(reg_y_write),
        .reg_sp_write(reg_sp_write),
        .reg_pc_write(reg_pc_write),
        .pc_increment(pc_increment),
        .sp_push(sp_push),
        .sp_pop(sp_pop),
        .update_nz(update_nz),
        .update_c(update_c),
        .update_v(update_v),
        .manual_set_c(manual_set_c),
        .manual_clear_c(manual_clear_c),
        .pc_branch_target(pc_branch_target),
        .current_opcode(debug_opcode),
        .cpu_state(debug_cpu_state),
        .instruction_length(instruction_length)
    );

    // Debug outputs
    assign debug_reg_a = reg_a_out;
    assign debug_reg_x = reg_x_out;
    assign debug_reg_y = reg_y_out;
    assign debug_reg_sp = reg_sp_out;
    assign debug_reg_pc = reg_pc_out;
    assign debug_status_reg = status_reg;
    assign debug_alu_result = alu_result;

endmodule