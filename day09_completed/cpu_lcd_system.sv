// CPU + LCD Integration System
// Displays CPU register values on LCD

module cpu_lcd_system (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [3:0]  switches,

    // LCD interface
    output logic        lcd_rs,
    output logic        lcd_rw,
    output logic        lcd_en,
    output logic [3:0]  lcd_data,

    // Debug outputs
    output logic [7:0]  debug_reg_a,
    output logic [7:0]  debug_reg_x,
    output logic [7:0]  debug_reg_y,
    output logic [15:0] debug_reg_pc,
    output logic [7:0]  debug_opcode,
    output logic [2:0]  debug_cpu_state,
    output logic        debug_lcd_ready
);

    // CPU signals
    logic [15:0] cpu_mem_addr;
    logic [7:0]  cpu_mem_data_out;
    logic [7:0]  cpu_mem_data_in;
    logic        cpu_mem_read;
    logic        cpu_mem_write;
    logic        cpu_mem_ready;

    // Memory system signals
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

    // LCD interface signals
    logic [7:0]  lcd_controller_data;
    logic        lcd_controller_write;
    logic        lcd_controller_cmd_data;
    logic        lcd_controller_busy;

    logic [7:0]  lcd_display_char;
    logic        lcd_display_char_write;
    logic [4:0]  lcd_display_cursor_pos;
    logic        lcd_display_cursor_set;
    logic        lcd_display_clear;
    logic        lcd_display_ready;

    // Update control
    logic [25:0] update_counter;
    logic        update_trigger;
    logic [3:0]  display_state;
    logic [7:0]  hex_char;

    // CPU clock divider (slower for LCD updates)
    logic [3:0] cpu_clk_div;
    logic cpu_clk;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cpu_clk_div <= 4'b0000;
        end else begin
            cpu_clk_div <= cpu_clk_div + 1;
        end
    end

    // CPU clock selection
    always_comb begin
        case (switches[1:0])
            2'b00: cpu_clk = cpu_clk_div[3];  // Slowest
            2'b01: cpu_clk = cpu_clk_div[2];  // Slow
            2'b10: cpu_clk = cpu_clk_div[1];  // Medium
            2'b11: cpu_clk = clk;             // Fast
            default: cpu_clk = cpu_clk_div[3];
        endcase
    end

    // 6502 CPU Core (from Day 08)
    cpu_core cpu (
        .clk(cpu_clk),
        .rst_n(rst_n),
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
        .debug_status_reg(),
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

    // ROM Instance
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

    // Memory data multiplexer
    always_comb begin
        if (ram_cs) begin
            ext_data_in = ram_data_out;
        end else if (rom_cs) begin
            ext_data_in = rom_data_out;
        end else if (io_cs) begin
            ext_data_in = {4'h0, switches};
        end else begin
            ext_data_in = 8'h00;
        end
    end

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

    // LCD Display Interface
    lcd_display lcd_disp (
        .clk(clk),
        .rst_n(rst_n),
        .char_data(lcd_display_char),
        .char_write(lcd_display_char_write),
        .cursor_pos(lcd_display_cursor_pos),
        .cursor_set(lcd_display_cursor_set),
        .clear_screen(lcd_display_clear),
        .lcd_data(lcd_controller_data),
        .lcd_write(lcd_controller_write),
        .lcd_cmd_data(lcd_controller_cmd_data),
        .lcd_busy(lcd_controller_busy),
        .ready(lcd_display_ready)
    );

    // Update timer (update LCD every ~0.1 seconds)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            update_counter <= 26'b0;
            update_trigger <= 1'b0;
        end else begin
            update_counter <= update_counter + 1;
            update_trigger <= update_counter[25];  // About 0.5 seconds
            if (update_trigger) begin
                update_counter <= 26'b0;
            end
        end
    end

    // Hexadecimal to ASCII conversion
    function automatic logic [7:0] hex_to_ascii(input logic [3:0] hex_digit);
        case (hex_digit)
            4'h0: hex_to_ascii = 8'h30;  // '0'
            4'h1: hex_to_ascii = 8'h31;  // '1'
            4'h2: hex_to_ascii = 8'h32;  // '2'
            4'h3: hex_to_ascii = 8'h33;  // '3'
            4'h4: hex_to_ascii = 8'h34;  // '4'
            4'h5: hex_to_ascii = 8'h35;  // '5'
            4'h6: hex_to_ascii = 8'h36;  // '6'
            4'h7: hex_to_ascii = 8'h37;  // '7'
            4'h8: hex_to_ascii = 8'h38;  // '8'
            4'h9: hex_to_ascii = 8'h39;  // '9'
            4'hA: hex_to_ascii = 8'h41;  // 'A'
            4'hB: hex_to_ascii = 8'h42;  // 'B'
            4'hC: hex_to_ascii = 8'h43;  // 'C'
            4'hD: hex_to_ascii = 8'h44;  // 'D'
            4'hE: hex_to_ascii = 8'h45;  // 'E'
            4'hF: hex_to_ascii = 8'h46;  // 'F'
            default: hex_to_ascii = 8'h30;
        endcase
    endfunction

    // LCD update state machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            display_state <= 4'h0;
            lcd_display_char <= 8'h00;
            lcd_display_char_write <= 1'b0;
            lcd_display_cursor_pos <= 5'h00;
            lcd_display_cursor_set <= 1'b0;
            lcd_display_clear <= 1'b0;
        end else begin
            // Default values
            lcd_display_char_write <= 1'b0;
            lcd_display_cursor_set <= 1'b0;
            lcd_display_clear <= 1'b0;

            if (update_trigger && lcd_display_ready) begin
                case (display_state)
                    4'h0: begin  // Clear screen
                        lcd_display_clear <= 1'b1;
                        display_state <= 4'h1;
                    end

                    4'h1: begin  // "A:"
                        lcd_display_cursor_pos <= 5'd0;
                        lcd_display_cursor_set <= 1'b1;
                        display_state <= 4'h2;
                    end

                    4'h2: begin
                        lcd_display_char <= 8'h41;  // 'A'
                        lcd_display_char_write <= 1'b1;
                        display_state <= 4'h3;
                    end

                    4'h3: begin
                        lcd_display_char <= 8'h3A;  // ':'
                        lcd_display_char_write <= 1'b1;
                        display_state <= 4'h4;
                    end

                    4'h4: begin  // A register high nibble
                        lcd_display_char <= hex_to_ascii(debug_reg_a[7:4]);
                        lcd_display_char_write <= 1'b1;
                        display_state <= 4'h5;
                    end

                    4'h5: begin  // A register low nibble
                        lcd_display_char <= hex_to_ascii(debug_reg_a[3:0]);
                        lcd_display_char_write <= 1'b1;
                        display_state <= 4'h6;
                    end

                    4'h6: begin  // Space + "X:"
                        lcd_display_char <= 8'h20;  // ' '
                        lcd_display_char_write <= 1'b1;
                        display_state <= 4'h7;
                    end

                    4'h7: begin
                        lcd_display_char <= 8'h58;  // 'X'
                        lcd_display_char_write <= 1'b1;
                        display_state <= 4'h8;
                    end

                    4'h8: begin
                        lcd_display_char <= 8'h3A;  // ':'
                        lcd_display_char_write <= 1'b1;
                        display_state <= 4'h9;
                    end

                    4'h9: begin  // X register high nibble
                        lcd_display_char <= hex_to_ascii(debug_reg_x[7:4]);
                        lcd_display_char_write <= 1'b1;
                        display_state <= 4'hA;
                    end

                    4'hA: begin  // X register low nibble
                        lcd_display_char <= hex_to_ascii(debug_reg_x[3:0]);
                        lcd_display_char_write <= 1'b1;
                        display_state <= 4'hB;
                    end

                    4'hB: begin  // Move to second line
                        lcd_display_cursor_pos <= 5'd16;  // Second line start
                        lcd_display_cursor_set <= 1'b1;
                        display_state <= 4'hC;
                    end

                    4'hC: begin  // "PC:"
                        lcd_display_char <= 8'h50;  // 'P'
                        lcd_display_char_write <= 1'b1;
                        display_state <= 4'hD;
                    end

                    4'hD: begin
                        lcd_display_char <= 8'h43;  // 'C'
                        lcd_display_char_write <= 1'b1;
                        display_state <= 4'hE;
                    end

                    4'hE: begin
                        lcd_display_char <= 8'h3A;  // ':'
                        lcd_display_char_write <= 1'b1;
                        display_state <= 4'hF;
                    end

                    4'hF: begin  // PC high byte, high nibble
                        lcd_display_char <= hex_to_ascii(debug_reg_pc[15:12]);
                        lcd_display_char_write <= 1'b1;
                        display_state <= 4'h0;  // Loop back
                    end

                    default: display_state <= 4'h0;
                endcase
            end
        end
    end

    assign debug_lcd_ready = lcd_display_ready;

endmodule