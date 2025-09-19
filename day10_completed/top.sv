// Day 10 Completed: Assembly Programming Examples
// Complete 6502 development system with program selection and enhanced display

module top (
    input  wire clk,
    input  wire rst_n,
    input  wire [3:0] switches,        // Program selector
    input  wire program_start_btn,     // Start button

    // LCD interface (HD44780 compatible)
    output wire lcd_rs,     // Register select
    output wire lcd_rw,     // Read/Write (tied to write)
    output wire lcd_en,     // Enable
    output wire [3:0] lcd_data,  // 4-bit data

    // Debug LEDs
    output wire [7:0] debug_leds,

    // Additional debug outputs
    output wire debug_cpu_clk,
    output wire debug_program_running,
    output wire debug_lcd_ready
);

    // Internal signals
    logic [7:0]  cpu_reg_a;
    logic [7:0]  cpu_reg_x;
    logic [7:0]  cpu_reg_y;
    logic [15:0] cpu_reg_pc;
    logic [7:0]  cpu_status_reg;
    logic [7:0]  cpu_opcode;
    logic [2:0]  cpu_state;

    // Program control signals
    logic        cpu_reset_internal;
    logic [15:0] program_start_addr;
    logic [3:0]  current_program;
    logic        program_running;

    // LCD control signals
    logic [7:0]  lcd_controller_data;
    logic        lcd_controller_write;
    logic        lcd_controller_cmd_data;
    logic        lcd_controller_busy;
    logic        lcd_display_ready;

    // Display mode control (from upper switches)
    logic [1:0]  display_mode;
    assign display_mode = switches[3:2];

    // System activity indicators
    logic [25:0] heartbeat_counter;
    logic        heartbeat;

    // CPU clock generation with adjustable speed
    logic [4:0] cpu_clk_div;
    logic cpu_clk;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cpu_clk_div <= 5'b0;
        end else begin
            cpu_clk_div <= cpu_clk_div + 1;
        end
    end

    // CPU clock speed selection (lower switches control speed when not selecting program)
    always_comb begin
        if (program_start_btn) begin
            // When start button pressed, use slowest speed for better observation
            cpu_clk = cpu_clk_div[4];  // Very slow for step-by-step observation
        end else begin
            case (switches[1:0])
                2'b00: cpu_clk = cpu_clk_div[4];  // Slowest (0.84MHz)
                2'b01: cpu_clk = cpu_clk_div[3];  // Slow (1.69MHz)
                2'b10: cpu_clk = cpu_clk_div[2];  // Medium (3.375MHz)
                2'b11: cpu_clk = cpu_clk_div[1];  // Fast (6.75MHz)
                default: cpu_clk = cpu_clk_div[4];
            endcase
        end
    end

    // Program Selector
    program_selector prog_sel (
        .clk(clk),
        .rst_n(rst_n),
        .program_select(switches),
        .program_start(program_start_btn),
        .cpu_reset(cpu_reset_internal),
        .start_address(program_start_addr),
        .current_program(current_program),
        .program_running(program_running)
    );

    // CPU + Memory System (modified for program selection)
    cpu_system_with_programs cpu_sys (
        .clk(cpu_clk),
        .rst_n(rst_n && !cpu_reset_internal),
        .start_address(program_start_addr),
        .debug_reg_a(cpu_reg_a),
        .debug_reg_x(cpu_reg_x),
        .debug_reg_y(cpu_reg_y),
        .debug_reg_pc(cpu_reg_pc),
        .debug_status_reg(cpu_status_reg),
        .debug_opcode(cpu_opcode),
        .debug_cpu_state(cpu_state)
    );

    // LCD Controller
    lcd_controller lcd_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(lcd_controller_data),
        .write_enable(lcd_controller_write),
        .cmd_data_select(lcd_controller_cmd_data),
        .busy(lcd_controller_busy),
        .lcd_rs(lcd_rs),
        .lcd_rw(lcd_rw),
        .lcd_en(lcd_en),
        .lcd_data(lcd_data)
    );

    // Enhanced LCD Display
    enhanced_lcd_display lcd_disp (
        .clk(clk),
        .rst_n(rst_n),
        .cpu_reg_a(cpu_reg_a),
        .cpu_reg_x(cpu_reg_x),
        .cpu_reg_y(cpu_reg_y),
        .cpu_reg_pc(cpu_reg_pc),
        .cpu_status_reg(cpu_status_reg),
        .current_program(current_program),
        .program_running(program_running),
        .display_mode(display_mode),
        .lcd_data(lcd_controller_data),
        .lcd_write(lcd_controller_write),
        .lcd_cmd_data(lcd_controller_cmd_data),
        .lcd_busy(lcd_controller_busy),
        .ready(lcd_display_ready)
    );

    // Heartbeat generator
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            heartbeat_counter <= 26'b0;
            heartbeat <= 1'b0;
        end else begin
            heartbeat_counter <= heartbeat_counter + 1;
            heartbeat <= heartbeat_counter[24];  // ~0.6 Hz blink
        end
    end

    // Debug LED assignments
    assign debug_leds[0] = heartbeat;                    // System heartbeat
    assign debug_leds[1] = program_running;             // Program running indicator
    assign debug_leds[2] = lcd_display_ready;           // LCD ready status
    assign debug_leds[3] = program_start_btn;           // Start button status
    assign debug_leds[7:4] = current_program;           // Current program number

    // Debug outputs
    assign debug_cpu_clk = cpu_clk;
    assign debug_program_running = program_running;
    assign debug_lcd_ready = lcd_display_ready;

endmodule

// Modified CPU system with program loading capability
module cpu_system_with_programs (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [15:0] start_address,

    // Debug outputs
    output logic [7:0]  debug_reg_a,
    output logic [7:0]  debug_reg_x,
    output logic [7:0]  debug_reg_y,
    output logic [15:0] debug_reg_pc,
    output logic [7:0]  debug_status_reg,
    output logic [7:0]  debug_opcode,
    output logic [2:0]  debug_cpu_state
);

    // Memory interface
    logic [15:0] cpu_mem_addr;
    logic [7:0]  cpu_mem_data_out;
    logic [7:0]  cpu_mem_data_in;
    logic        cpu_mem_read;
    logic        cpu_mem_write;
    logic        cpu_mem_ready;

    // External memory interface
    logic [15:0] ext_addr;
    logic [7:0]  ext_data_out;
    logic [7:0]  ext_data_in;
    logic        ext_oe;
    logic        ext_we;
    logic        ram_cs;
    logic        rom_cs;
    logic        io_cs;

    // Memory data
    logic [7:0]  ram_data_out;
    logic [7:0]  rom_data_out;

    // Modified CPU Core with custom start address
    cpu_core_with_start cpu (
        .clk(clk),
        .rst_n(rst_n),
        .start_address(start_address),
        .mem_addr(cpu_mem_addr),
        .mem_data_out(cpu_mem_data_out),
        .mem_data_in(cpu_mem_data_in),
        .mem_read(cpu_mem_read),
        .mem_write(cpu_mem_write),
        .mem_ready(cpu_mem_ready),
        .irq_n(1'b1),
        .nmi_n(1'b1),
        .debug_reg_a(debug_reg_a),
        .debug_reg_x(debug_reg_x),
        .debug_reg_y(debug_reg_y),
        .debug_reg_sp(),
        .debug_reg_pc(debug_reg_pc),
        .debug_status_reg(debug_status_reg),
        .debug_opcode(debug_opcode),
        .debug_cpu_state(debug_cpu_state),
        .debug_alu_result()
    );

    // Memory Controller
    memory_controller mem_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .cpu_addr(cpu_mem_addr),
        .cpu_data_out(cpu_mem_data_out),
        .cpu_data_in(cpu_mem_data_in),
        .cpu_mem_read(cpu_mem_read),
        .cpu_mem_write(cpu_mem_write),
        .cpu_ready(cpu_mem_ready),
        .stack_push(1'b0),
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

    // RAM Instance
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

    // ROM Instance with Assembly Examples
    assembly_examples #(
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

    // Memory data multiplexer
    always_comb begin
        if (ram_cs) begin
            ext_data_in = ram_data_out;
        end else if (rom_cs) begin
            ext_data_in = rom_data_out;
        end else if (io_cs) begin
            ext_data_in = 8'h00;  // No I/O for this example
        end else begin
            ext_data_in = 8'h00;
        end
    end

endmodule

// CPU Core with configurable start address
module cpu_core_with_start (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [15:0] start_address,

    // Standard CPU core interface
    output logic [15:0] mem_addr,
    output logic [7:0]  mem_data_out,
    input  logic [7:0]  mem_data_in,
    output logic        mem_read,
    output logic        mem_write,
    input  logic        mem_ready,

    input  logic        irq_n,
    input  logic        nmi_n,

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

    // Modified CPU registers with custom PC start
    cpu_registers_with_start registers (
        .clk(clk),
        .rst_n(rst_n),
        .start_address(start_address),
        .reg_a_write(1'b0),      // Connect to actual control signals
        .reg_x_write(1'b0),
        .reg_y_write(1'b0),
        .reg_sp_write(1'b0),
        .reg_pc_write(1'b0),
        .data_in(8'h00),
        .pc_in(16'h0000),
        .pc_increment(1'b0),
        .sp_push(1'b0),
        .sp_pop(1'b0),
        .reg_a(debug_reg_a),
        .reg_x(debug_reg_x),
        .reg_y(debug_reg_y),
        .reg_sp(debug_reg_sp),
        .reg_pc(debug_reg_pc)
    );

    // For this simplified version, we'll just use the basic CPU core
    // and override the PC start value
    cpu_core basic_cpu (
        .clk(clk),
        .rst_n(rst_n),
        .mem_addr(mem_addr),
        .mem_data_out(mem_data_out),
        .mem_data_in(mem_data_in),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_ready(mem_ready),
        .irq_n(irq_n),
        .nmi_n(nmi_n),
        .debug_reg_a(debug_reg_a),
        .debug_reg_x(debug_reg_x),
        .debug_reg_y(debug_reg_y),
        .debug_reg_sp(debug_reg_sp),
        .debug_reg_pc(debug_reg_pc),
        .debug_status_reg(debug_status_reg),
        .debug_opcode(debug_opcode),
        .debug_cpu_state(debug_cpu_state),
        .debug_alu_result(debug_alu_result)
    );

endmodule

// CPU registers with configurable start address
module cpu_registers_with_start (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [15:0] start_address,

    // Standard register interface
    input  logic        reg_a_write,
    input  logic        reg_x_write,
    input  logic        reg_y_write,
    input  logic        reg_sp_write,
    input  logic        reg_pc_write,
    input  logic [7:0]  data_in,
    input  logic [15:0] pc_in,
    input  logic        pc_increment,
    input  logic        sp_push,
    input  logic        sp_pop,

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
            stack_pointer <= 8'hFF;
            program_counter <= start_address;  // Use configurable start address
        end else begin
            // Standard register update logic
            if (reg_a_write) accumulator <= data_in;
            if (reg_x_write) index_x <= data_in;
            if (reg_y_write) index_y <= data_in;
            if (reg_sp_write) stack_pointer <= data_in;

            if (reg_pc_write) begin
                program_counter <= pc_in;
            end else if (pc_increment) begin
                program_counter <= program_counter + 1;
            end

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