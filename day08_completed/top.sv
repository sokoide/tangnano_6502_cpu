// Day 08 Completed: Integrated 6502 CPU Core
// Complete CPU system with memory and peripherals

module top (
    input  wire clk,
    input  wire rst_n,
    input  wire [3:0] switches,

    // CPU debug outputs
    output wire [7:0]  debug_reg_a,
    output wire [7:0]  debug_reg_x,
    output wire [7:0]  debug_reg_y,
    output wire [7:0]  debug_reg_sp,
    output wire [15:0] debug_reg_pc,
    output wire [7:0]  debug_status_reg,

    // Memory debug outputs
    output wire [15:0] debug_mem_addr,
    output wire [7:0]  debug_mem_data,
    output wire debug_mem_read,
    output wire debug_mem_write,

    // System debug outputs
    output wire [7:0]  debug_opcode,
    output wire [2:0]  debug_cpu_state,
    output wire debug_system_ready
);

    // Clock divider for CPU (slower than memory for debugging)
    logic [3:0] cpu_clk_div;
    logic cpu_clk;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cpu_clk_div <= 4'b0000;
        end else begin
            cpu_clk_div <= cpu_clk_div + 1;
        end
    end

    // CPU clock selection (switch controlled)
    always_comb begin
        case (switches[1:0])
            2'b00: cpu_clk = cpu_clk_div[3];  // Slowest (1.69MHz)
            2'b01: cpu_clk = cpu_clk_div[2];  // Slow (3.375MHz)
            2'b10: cpu_clk = cpu_clk_div[1];  // Medium (6.75MHz)
            2'b11: cpu_clk = clk;             // Full speed (27MHz)
            default: cpu_clk = cpu_clk_div[3];
        endcase
    end

    // CPU to memory interface
    logic [15:0] cpu_mem_addr;
    logic [7:0]  cpu_mem_data_out;
    logic [7:0]  cpu_mem_data_in;
    logic        cpu_mem_read;
    logic        cpu_mem_write;
    logic        cpu_mem_ready;

    // Memory controller interface
    logic [15:0] ext_addr;
    logic [7:0]  ext_data_out;
    logic [7:0]  ext_data_in;
    logic        ext_oe;
    logic        ext_we;
    logic        ram_cs;
    logic        rom_cs;
    logic        io_cs;

    // RAM and ROM data
    logic [7:0]  ram_data_out;
    logic [7:0]  rom_data_out;

    // 6502 CPU Core
    cpu_core cpu (
        .clk(cpu_clk),
        .rst_n(rst_n),
        .mem_addr(cpu_mem_addr),
        .mem_data_out(cpu_mem_data_out),
        .mem_data_in(cpu_mem_data_in),
        .mem_read(cpu_mem_read),
        .mem_write(cpu_mem_write),
        .mem_ready(cpu_mem_ready),
        .irq_n(1'b1),                    // No interrupts for now
        .nmi_n(1'b1),
        .debug_reg_a(debug_reg_a),
        .debug_reg_x(debug_reg_x),
        .debug_reg_y(debug_reg_y),
        .debug_reg_sp(debug_reg_sp),
        .debug_reg_pc(debug_reg_pc),
        .debug_status_reg(debug_status_reg),
        .debug_opcode(debug_opcode),
        .debug_cpu_state(debug_cpu_state),
        .debug_alu_result()
    );

    // Memory Controller (from Day 07)
    memory_controller mem_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .cpu_addr(cpu_mem_addr),
        .cpu_data_out(cpu_mem_data_out),
        .cpu_data_in(cpu_mem_data_in),
        .cpu_mem_read(cpu_mem_read),
        .cpu_mem_write(cpu_mem_write),
        .cpu_ready(cpu_mem_ready),
        .stack_push(1'b0),               // Stack handled by CPU core
        .stack_pop(1'b0),
        .stack_data_out(8'h00),
        .stack_data_in(),
        .stack_pointer(),
        .ext_addr(ext_addr),
        .ext_data_out(ext_data_out),
        .ext_data_in(ext_data_in),
        .ext_oe(ext_oe),
        .ext_we(ext_we),
        .ram_select(ram_cs),
        .rom_select(rom_cs),
        .io_select(io_cs)
    );

    // RAM Instance (32KB)
    simple_ram #(
        .ADDR_WIDTH(15),
        .DATA_WIDTH(8)
    ) ram_inst (
        .clk(clk),
        .rst_n(rst_n),
        .addr(ext_addr[14:0]),
        .data_in(ext_data_out),
        .data_out(ram_data_out),
        .we(ext_we && ram_cs),
        .oe(ext_oe && ram_cs),
        .cs(ram_cs)
    );

    // ROM Instance (16KB) with 6502 test program
    test_rom #(
        .ADDR_WIDTH(14),
        .DATA_WIDTH(8)
    ) rom_inst (
        .clk(clk),
        .rst_n(rst_n),
        .addr(ext_addr[13:0]),
        .data_out(rom_data_out),
        .oe(ext_oe && rom_cs),
        .cs(rom_cs)
    );

    // Memory data input multiplexer
    always_comb begin
        if (ram_cs) begin
            ext_data_in = ram_data_out;
        end else if (rom_cs) begin
            ext_data_in = rom_data_out;
        end else if (io_cs) begin
            // Simple I/O: switches readable at any I/O address
            ext_data_in = {4'h0, switches};
        end else begin
            ext_data_in = 8'h00;
        end
    end

    // Debug outputs
    assign debug_mem_addr = cpu_mem_addr;
    assign debug_mem_data = cpu_mem_data_out;
    assign debug_mem_read = cpu_mem_read;
    assign debug_mem_write = cpu_mem_write;
    assign debug_system_ready = cpu_mem_ready;

endmodule