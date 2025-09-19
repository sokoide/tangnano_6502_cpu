// 6502 CPU Control Unit
// Main controller that orchestrates instruction execution

module cpu_control_unit (
    input  logic        clk,
    input  logic        rst_n,

    // Memory interface
    input  logic [7:0]  mem_data_in,
    output logic [15:0] mem_addr,
    output logic [7:0]  mem_data_out,
    output logic        mem_read,
    output logic        mem_write,
    input  logic        mem_ready,

    // Register interface
    input  logic [7:0]  reg_a,
    input  logic [7:0]  reg_x,
    input  logic [7:0]  reg_y,
    input  logic [7:0]  reg_sp,
    input  logic [15:0] reg_pc,

    // ALU interface
    input  logic [7:0]  alu_result,
    input  logic        alu_carry_out,
    input  logic        alu_overflow,
    input  logic        alu_negative,
    input  logic        alu_zero,

    // Status register
    input  logic [7:0]  status_reg,

    // Control outputs to datapath
    output logic [3:0]  alu_op,
    output logic        alu_carry_in,
    output logic [1:0]  alu_a_sel,
    output logic [1:0]  alu_b_sel,
    output logic [2:0]  reg_src_sel,

    // Register control
    output logic        reg_a_write,
    output logic        reg_x_write,
    output logic        reg_y_write,
    output logic        reg_sp_write,
    output logic        reg_pc_write,
    output logic        pc_increment,
    output logic        sp_push,
    output logic        sp_pop,

    // Status register control
    output logic        update_nz,
    output logic        update_c,
    output logic        update_v,
    output logic        manual_set_c,
    output logic        manual_clear_c,

    // Program counter control
    output logic [15:0] pc_branch_target,

    // Debug outputs
    output logic [7:0]  current_opcode,
    output logic [2:0]  cpu_state,
    output logic [1:0]  instruction_length
);

    // CPU states
    typedef enum logic [2:0] {
        FETCH,
        DECODE,
        EXECUTE,
        MEMORY,
        WRITEBACK
    } cpu_state_t;

    cpu_state_t state, next_state;

    // Internal registers
    logic [7:0]  opcode;
    logic [7:0]  operand_low;
    logic [7:0]  operand_high;
    logic [15:0] effective_addr;
    logic [7:0]  fetched_data;

    // Decoder outputs
    logic        decoder_mem_read;
    logic        decoder_mem_write;
    logic        decoder_is_branch;
    logic        decoder_is_jump;
    logic        decoder_stack_push;
    logic        decoder_stack_pop;
    logic [2:0]  decoder_addr_mode;

    // Addressing mode calculator
    logic [15:0] addr_calc_result;
    logic        addr_calc_page_crossed;

    // CPU Decoder
    cpu_decoder decoder (
        .opcode(opcode),
        .status_reg(status_reg),
        .alu_op(alu_op),
        .alu_carry_in(alu_carry_in),
        .reg_a_write(reg_a_write),
        .reg_x_write(reg_x_write),
        .reg_y_write(reg_y_write),
        .reg_sp_write(reg_sp_write),
        .reg_pc_write(reg_pc_write),
        .mem_read(decoder_mem_read),
        .mem_write(decoder_mem_write),
        .update_nz(update_nz),
        .update_c(update_c),
        .update_v(update_v),
        .reg_src_sel(reg_src_sel),
        .alu_a_sel(alu_a_sel),
        .alu_b_sel(alu_b_sel),
        .addr_mode(decoder_addr_mode),
        .instruction_length(instruction_length),
        .is_branch(decoder_is_branch),
        .is_jump(decoder_is_jump),
        .stack_push(decoder_stack_push),
        .stack_pop(decoder_stack_pop)
    );

    // Addressing Mode Calculator
    addressing_mode_calculator addr_calc (
        .mode(decoder_addr_mode),
        .operand_low(operand_low),
        .operand_high(operand_high),
        .reg_x(reg_x),
        .reg_y(reg_y),
        .pc(reg_pc),
        .effective_address(addr_calc_result),
        .page_boundary_crossed(addr_calc_page_crossed)
    );

    // State machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= FETCH;
            opcode <= 8'h00;
            operand_low <= 8'h00;
            operand_high <= 8'h00;
            effective_addr <= 16'h0000;
            fetched_data <= 8'h00;
        end else begin
            state <= next_state;

            case (state)
                FETCH: begin
                    if (mem_ready) begin
                        opcode <= mem_data_in;
                    end
                end

                DECODE: begin
                    if (mem_ready && instruction_length > 2'd1) begin
                        operand_low <= mem_data_in;
                    end
                end

                EXECUTE: begin
                    if (mem_ready && instruction_length == 2'd3) begin
                        operand_high <= mem_data_in;
                    end
                    effective_addr <= addr_calc_result;
                end

                MEMORY: begin
                    if (mem_ready && decoder_mem_read) begin
                        fetched_data <= mem_data_in;
                    end
                end

                WRITEBACK: begin
                    // State completed
                end
            endcase
        end
    end

    // Next state logic
    always_comb begin
        case (state)
            FETCH: begin
                if (mem_ready) begin
                    next_state = DECODE;
                end else begin
                    next_state = FETCH;
                end
            end

            DECODE: begin
                if (instruction_length == 2'd1) begin
                    next_state = EXECUTE;
                end else if (mem_ready) begin
                    next_state = EXECUTE;
                end else begin
                    next_state = DECODE;
                end
            end

            EXECUTE: begin
                if (instruction_length == 2'd3 && !mem_ready) begin
                    next_state = EXECUTE;
                end else if (decoder_mem_read || decoder_mem_write) begin
                    next_state = MEMORY;
                end else begin
                    next_state = WRITEBACK;
                end
            end

            MEMORY: begin
                if (mem_ready) begin
                    next_state = WRITEBACK;
                end else begin
                    next_state = MEMORY;
                end
            end

            WRITEBACK: begin
                next_state = FETCH;
            end

            default: next_state = FETCH;
        endcase
    end

    // Memory control
    always_comb begin
        mem_addr = 16'h0000;
        mem_data_out = 8'h00;
        mem_read = 1'b0;
        mem_write = 1'b0;
        pc_increment = 1'b0;
        sp_push = 1'b0;
        sp_pop = 1'b0;
        pc_branch_target = 16'h0000;
        manual_set_c = 1'b0;
        manual_clear_c = 1'b0;

        case (state)
            FETCH: begin
                mem_addr = reg_pc;
                mem_read = 1'b1;
                if (mem_ready) begin
                    pc_increment = 1'b1;
                end
            end

            DECODE: begin
                if (instruction_length > 2'd1) begin
                    mem_addr = reg_pc;
                    mem_read = 1'b1;
                    if (mem_ready) begin
                        pc_increment = 1'b1;
                    end
                end
            end

            EXECUTE: begin
                if (instruction_length == 2'd3) begin
                    mem_addr = reg_pc;
                    mem_read = 1'b1;
                    if (mem_ready) begin
                        pc_increment = 1'b1;
                    end
                end

                // Handle special instructions
                if (opcode == 8'h38) begin  // SEC
                    manual_set_c = 1'b1;
                end else if (opcode == 8'h18) begin  // CLC
                    manual_clear_c = 1'b1;
                end
            end

            MEMORY: begin
                if (decoder_stack_push || decoder_stack_pop) begin
                    mem_addr = {8'h01, reg_sp};
                    if (decoder_stack_push) begin
                        mem_write = 1'b1;
                        mem_data_out = reg_a;  // Simplified - always push A
                        sp_push = 1'b1;
                    end else begin
                        mem_read = 1'b1;
                        sp_pop = 1'b1;
                    end
                end else begin
                    mem_addr = effective_addr;
                    mem_read = decoder_mem_read;
                    mem_write = decoder_mem_write;
                    if (decoder_mem_write) begin
                        mem_data_out = reg_a;  // Simplified - always write A
                    end
                end
            end

            WRITEBACK: begin
                // Handle branches and jumps
                if (decoder_is_jump) begin
                    pc_branch_target = effective_addr;
                end else if (decoder_is_branch) begin
                    // Simplified branch logic - always taken for demo
                    pc_branch_target = reg_pc + {{8{operand_low[7]}}, operand_low};
                end
            end
        endcase
    end

    // Debug outputs
    assign current_opcode = opcode;
    assign cpu_state = state;

endmodule