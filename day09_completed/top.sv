// Day 09 Completed: LCD Controller System
// Complete 6502 CPU with LCD display for register monitoring

module top (
    input  wire clk,
    input  wire rst_n,
    input  wire [3:0] switches,

    // LCD interface (HD44780 compatible)
    output wire lcd_rs,     // Register select
    output wire lcd_rw,     // Read/Write (tied to write)
    output wire lcd_en,     // Enable
    output wire [3:0] lcd_data,  // 4-bit data

    // Debug LEDs
    output wire [7:0] debug_leds,

    // Additional debug outputs
    output wire debug_cpu_clk,
    output wire debug_lcd_ready,
    output wire debug_cpu_running
);

    // Internal signals
    logic [7:0]  cpu_reg_a;
    logic [7:0]  cpu_reg_x;
    logic [7:0]  cpu_reg_y;
    logic [15:0] cpu_reg_pc;
    logic [7:0]  cpu_opcode;
    logic [2:0]  cpu_state;
    logic        lcd_ready;

    // System status indicators
    logic [25:0] heartbeat_counter;
    logic        heartbeat;
    logic        system_active;

    // CPU + LCD System
    cpu_lcd_system cpu_lcd (
        .clk(clk),
        .rst_n(rst_n),
        .switches(switches),
        .lcd_rs(lcd_rs),
        .lcd_rw(lcd_rw),
        .lcd_en(lcd_en),
        .lcd_data(lcd_data),
        .debug_reg_a(cpu_reg_a),
        .debug_reg_x(cpu_reg_x),
        .debug_reg_y(cpu_reg_y),
        .debug_reg_pc(cpu_reg_pc),
        .debug_opcode(cpu_opcode),
        .debug_cpu_state(cpu_state),
        .debug_lcd_ready(lcd_ready)
    );

    // Heartbeat generator for system activity indication
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            heartbeat_counter <= 26'b0;
            heartbeat <= 1'b0;
        end else begin
            heartbeat_counter <= heartbeat_counter + 1;
            heartbeat <= heartbeat_counter[24];  // ~0.6 Hz blink
        end
    end

    // System activity detection
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            system_active <= 1'b0;
        end else begin
            // System is active if CPU is running or LCD is updating
            system_active <= (cpu_state != 3'b000) || !lcd_ready;
        end
    end

    // Debug LED assignments
    assign debug_leds[0] = heartbeat;           // Heartbeat indicator
    assign debug_leds[1] = system_active;      // System activity
    assign debug_leds[2] = lcd_ready;          // LCD ready status
    assign debug_leds[3] = switches[0];        // Switch echo
    assign debug_leds[7:4] = cpu_reg_a[3:0];   // Lower nibble of accumulator

    // Additional debug outputs
    assign debug_cpu_clk = cpu_lcd.cpu_clk;
    assign debug_lcd_ready = lcd_ready;
    assign debug_cpu_running = system_active;

endmodule