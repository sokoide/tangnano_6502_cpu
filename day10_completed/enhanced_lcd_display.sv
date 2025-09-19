// Enhanced LCD Display with Program Information
// Shows current program status and CPU state

module enhanced_lcd_display (
    input  logic        clk,
    input  logic        rst_n,

    // CPU state inputs
    input  logic [7:0]  cpu_reg_a,
    input  logic [7:0]  cpu_reg_x,
    input  logic [7:0]  cpu_reg_y,
    input  logic [15:0] cpu_reg_pc,
    input  logic [7:0]  cpu_status_reg,

    // Program selector inputs
    input  logic [3:0]  current_program,
    input  logic        program_running,

    // Display mode control
    input  logic [1:0]  display_mode,  // 0=CPU regs, 1=Program info, 2=Status, 3=Memory

    // LCD controller interface
    output logic [7:0]  lcd_data,
    output logic        lcd_write,
    output logic        lcd_cmd_data,
    input  logic        lcd_busy,

    // Status
    output logic        ready
);

    // Display update states
    typedef enum logic [4:0] {
        IDLE,
        CLEAR_SCREEN,
        SET_CURSOR_LINE1,
        WRITE_LINE1_START,
        WRITE_LINE1_DATA,
        SET_CURSOR_LINE2,
        WRITE_LINE2_START,
        WRITE_LINE2_DATA,
        DISPLAY_DONE
    } display_state_t;

    display_state_t state, next_state;

    // Internal registers
    logic [25:0] update_counter;
    logic        update_trigger;
    logic [4:0]  char_index;
    logic [7:0]  display_buffer [0:31];  // 16 chars x 2 lines
    logic        buffer_ready;

    // Program names
    localparam string PROGRAM_NAMES [0:7] = '{
        "ARITHMETIC ",   // 11 chars
        "LOOP COUNT ",
        "BIT MANIP  ",
        "SUBROUTINE ",
        "ARRAY PROC ",
        "STRING OPS ",
        "MATH FUNCS ",
        "I/O EXAMPLE"
    };

    // Status flag names
    function automatic logic [7:0] get_status_char(input logic [7:0] status_reg, input integer flag_pos);
        case (flag_pos)
            7: get_status_char = status_reg[7] ? 8'h4E : 8'h2D;  // N or -
            6: get_status_char = status_reg[6] ? 8'h56 : 8'h2D;  // V or -
            5: get_status_char = 8'h31;                          // Always 1
            4: get_status_char = status_reg[4] ? 8'h42 : 8'h2D;  // B or -
            3: get_status_char = status_reg[3] ? 8'h44 : 8'h2D;  // D or -
            2: get_status_char = status_reg[2] ? 8'h49 : 8'h2D;  // I or -
            1: get_status_char = status_reg[1] ? 8'h5A : 8'h2D;  // Z or -
            0: get_status_char = status_reg[0] ? 8'h43 : 8'h2D;  // C or -
            default: get_status_char = 8'h2D;                    // -
        endcase
    endfunction

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

    // Update timer (refresh every ~0.5 seconds)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            update_counter <= 26'b0;
            update_trigger <= 1'b0;
        end else begin
            update_counter <= update_counter + 1;
            update_trigger <= update_counter[25];
            if (update_trigger) begin
                update_counter <= 26'b0;
            end
        end
    end

    // Display buffer preparation
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buffer_ready <= 1'b0;
            for (int i = 0; i < 32; i++) begin
                display_buffer[i] <= 8'h20;  // Space
            end
        end else begin
            if (update_trigger) begin
                case (display_mode)
                    2'b00: begin  // CPU Registers mode
                        // Line 1: "A:XX X:XX Y:XX"
                        display_buffer[0]  <= 8'h41;  // 'A'
                        display_buffer[1]  <= 8'h3A;  // ':'
                        display_buffer[2]  <= hex_to_ascii(cpu_reg_a[7:4]);
                        display_buffer[3]  <= hex_to_ascii(cpu_reg_a[3:0]);
                        display_buffer[4]  <= 8'h20;  // ' '
                        display_buffer[5]  <= 8'h58;  // 'X'
                        display_buffer[6]  <= 8'h3A;  // ':'
                        display_buffer[7]  <= hex_to_ascii(cpu_reg_x[7:4]);
                        display_buffer[8]  <= hex_to_ascii(cpu_reg_x[3:0]);
                        display_buffer[9]  <= 8'h20;  // ' '
                        display_buffer[10] <= 8'h59;  // 'Y'
                        display_buffer[11] <= 8'h3A;  // ':'
                        display_buffer[12] <= hex_to_ascii(cpu_reg_y[7:4]);
                        display_buffer[13] <= hex_to_ascii(cpu_reg_y[3:0]);
                        display_buffer[14] <= 8'h20;  // ' '
                        display_buffer[15] <= 8'h20;  // ' '

                        // Line 2: "PC:XXXX RUN"
                        display_buffer[16] <= 8'h50;  // 'P'
                        display_buffer[17] <= 8'h43;  // 'C'
                        display_buffer[18] <= 8'h3A;  // ':'
                        display_buffer[19] <= hex_to_ascii(cpu_reg_pc[15:12]);
                        display_buffer[20] <= hex_to_ascii(cpu_reg_pc[11:8]);
                        display_buffer[21] <= hex_to_ascii(cpu_reg_pc[7:4]);
                        display_buffer[22] <= hex_to_ascii(cpu_reg_pc[3:0]);
                        display_buffer[23] <= 8'h20;  // ' '
                        display_buffer[24] <= program_running ? 8'h52 : 8'h53;  // 'R' or 'S'
                        display_buffer[25] <= program_running ? 8'h55 : 8'h54;  // 'U' or 'T'
                        display_buffer[26] <= program_running ? 8'h4E : 8'h4F;  // 'N' or 'O'
                        display_buffer[27] <= program_running ? 8'h20 : 8'h50;  // ' ' or 'P'
                        display_buffer[28] <= 8'h20;  // ' '
                        display_buffer[29] <= 8'h20;  // ' '
                        display_buffer[30] <= 8'h20;  // ' '
                        display_buffer[31] <= 8'h20;  // ' '
                    end

                    2'b01: begin  // Program Info mode
                        // Line 1: "PROG X: NAME"
                        display_buffer[0]  <= 8'h50;  // 'P'
                        display_buffer[1]  <= 8'h52;  // 'R'
                        display_buffer[2]  <= 8'h4F;  // 'O'
                        display_buffer[3]  <= 8'h47;  // 'G'
                        display_buffer[4]  <= 8'h20;  // ' '
                        display_buffer[5]  <= hex_to_ascii(current_program);
                        display_buffer[6]  <= 8'h3A;  // ':'
                        display_buffer[7]  <= 8'h20;  // ' '

                        // Copy program name (8 chars max)
                        for (int i = 0; i < 8; i++) begin
                            if (current_program < 8) begin
                                display_buffer[8+i] <= PROGRAM_NAMES[current_program][i*8 +: 8];
                            end else begin
                                display_buffer[8+i] <= 8'h55;  // 'U' for unknown
                            end
                        end

                        // Line 2: Status flags "NV-BDIZC"
                        display_buffer[16] <= get_status_char(cpu_status_reg, 7);  // N
                        display_buffer[17] <= get_status_char(cpu_status_reg, 6);  // V
                        display_buffer[18] <= 8'h2D;                               // -
                        display_buffer[19] <= get_status_char(cpu_status_reg, 4);  // B
                        display_buffer[20] <= get_status_char(cpu_status_reg, 3);  // D
                        display_buffer[21] <= get_status_char(cpu_status_reg, 2);  // I
                        display_buffer[22] <= get_status_char(cpu_status_reg, 1);  // Z
                        display_buffer[23] <= get_status_char(cpu_status_reg, 0);  // C
                        for (int i = 24; i < 32; i++) begin
                            display_buffer[i] <= 8'h20;  // Space
                        end
                    end

                    2'b10: begin  // Status/Debug mode
                        // Line 1: "STATUS: XX"
                        display_buffer[0]  <= 8'h53;  // 'S'
                        display_buffer[1]  <= 8'h54;  // 'T'
                        display_buffer[2]  <= 8'h41;  // 'A'
                        display_buffer[3]  <= 8'h54;  // 'T'
                        display_buffer[4]  <= 8'h55;  // 'U'
                        display_buffer[5]  <= 8'h53;  // 'S'
                        display_buffer[6]  <= 8'h3A;  // ':'
                        display_buffer[7]  <= 8'h20;  // ' '
                        display_buffer[8]  <= hex_to_ascii(cpu_status_reg[7:4]);
                        display_buffer[9]  <= hex_to_ascii(cpu_status_reg[3:0]);
                        for (int i = 10; i < 16; i++) begin
                            display_buffer[i] <= 8'h20;  // Space
                        end

                        // Line 2: "MODE: CPU REG"
                        display_buffer[16] <= 8'h4D;  // 'M'
                        display_buffer[17] <= 8'h4F;  // 'O'
                        display_buffer[18] <= 8'h44;  // 'D'
                        display_buffer[19] <= 8'h45;  // 'E'
                        display_buffer[20] <= 8'h3A;  // ':'
                        display_buffer[21] <= 8'h20;  // ' '
                        case (display_mode)
                            2'b00: begin
                                display_buffer[22] <= 8'h43;  // 'C'
                                display_buffer[23] <= 8'h50;  // 'P'
                                display_buffer[24] <= 8'h55;  // 'U'
                                display_buffer[25] <= 8'h20;  // ' '
                                display_buffer[26] <= 8'h52;  // 'R'
                                display_buffer[27] <= 8'h45;  // 'E'
                                display_buffer[28] <= 8'h47;  // 'G'
                                display_buffer[29] <= 8'h20;  // ' '
                            end
                            2'b01: begin
                                display_buffer[22] <= 8'h50;  // 'P'
                                display_buffer[23] <= 8'h52;  // 'R'
                                display_buffer[24] <= 8'h4F;  // 'O'
                                display_buffer[25] <= 8'h47;  // 'G'
                                display_buffer[26] <= 8'h52;  // 'R'
                                display_buffer[27] <= 8'h41;  // 'A'
                                display_buffer[28] <= 8'h4D;  // 'M'
                                display_buffer[29] <= 8'h20;  // ' '
                            end
                            default: begin
                                display_buffer[22] <= 8'h44;  // 'D'
                                display_buffer[23] <= 8'h45;  // 'E'
                                display_buffer[24] <= 8'h42;  // 'B'
                                display_buffer[25] <= 8'h55;  // 'U'
                                display_buffer[26] <= 8'h47;  // 'G'
                                display_buffer[27] <= 8'h20;  // ' '
                                display_buffer[28] <= 8'h20;  // ' '
                                display_buffer[29] <= 8'h20;  // ' '
                            end
                        endcase
                        display_buffer[30] <= 8'h20;  // ' '
                        display_buffer[31] <= 8'h20;  // ' '
                    end

                    default: begin  // Memory/Other mode
                        // Line 1: "MEMORY VIEW"
                        display_buffer[0]  <= 8'h4D;  // 'M'
                        display_buffer[1]  <= 8'h45;  // 'E'
                        display_buffer[2]  <= 8'h4D;  // 'M'
                        display_buffer[3]  <= 8'h4F;  // 'O'
                        display_buffer[4]  <= 8'h52;  // 'R'
                        display_buffer[5]  <= 8'h59;  // 'Y'
                        display_buffer[6]  <= 8'h20;  // ' '
                        display_buffer[7]  <= 8'h56;  // 'V'
                        display_buffer[8]  <= 8'h49;  // 'I'
                        display_buffer[9]  <= 8'h45;  // 'E'
                        display_buffer[10] <= 8'h57;  // 'W'
                        for (int i = 11; i < 16; i++) begin
                            display_buffer[i] <= 8'h20;  // Space
                        end

                        // Line 2: PC address content
                        display_buffer[16] <= 8'h5B;  // '['
                        display_buffer[17] <= hex_to_ascii(cpu_reg_pc[15:12]);
                        display_buffer[18] <= hex_to_ascii(cpu_reg_pc[11:8]);
                        display_buffer[19] <= hex_to_ascii(cpu_reg_pc[7:4]);
                        display_buffer[20] <= hex_to_ascii(cpu_reg_pc[3:0]);
                        display_buffer[21] <= 8'h5D;  // ']'
                        display_buffer[22] <= 8'h3D;  // '='
                        display_buffer[23] <= 8'h3F;  // '?' (placeholder)
                        display_buffer[24] <= 8'h3F;  // '?' (placeholder)
                        for (int i = 25; i < 32; i++) begin
                            display_buffer[i] <= 8'h20;  // Space
                        end
                    end
                endcase
                buffer_ready <= 1'b1;
            end
        end
    end

    // Display state machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            char_index <= 5'b0;
        end else begin
            state <= next_state;

            case (state)
                WRITE_LINE1_DATA, WRITE_LINE2_DATA: begin
                    if (!lcd_busy) begin
                        char_index <= char_index + 1;
                    end
                end

                DISPLAY_DONE: begin
                    char_index <= 5'b0;
                    buffer_ready <= 1'b0;
                end

                default: begin
                    if (state == IDLE) begin
                        char_index <= 5'b0;
                    end
                end
            endcase
        end
    end

    // Next state logic
    always_comb begin
        next_state = state;

        case (state)
            IDLE: begin
                if (buffer_ready && !lcd_busy) begin
                    next_state = CLEAR_SCREEN;
                end
            end

            CLEAR_SCREEN: begin
                if (!lcd_busy) begin
                    next_state = SET_CURSOR_LINE1;
                end
            end

            SET_CURSOR_LINE1: begin
                if (!lcd_busy) begin
                    next_state = WRITE_LINE1_START;
                end
            end

            WRITE_LINE1_START: begin
                next_state = WRITE_LINE1_DATA;
            end

            WRITE_LINE1_DATA: begin
                if (!lcd_busy) begin
                    if (char_index >= 15) begin
                        next_state = SET_CURSOR_LINE2;
                    end
                end
            end

            SET_CURSOR_LINE2: begin
                if (!lcd_busy) begin
                    next_state = WRITE_LINE2_START;
                end
            end

            WRITE_LINE2_START: begin
                next_state = WRITE_LINE2_DATA;
            end

            WRITE_LINE2_DATA: begin
                if (!lcd_busy) begin
                    if (char_index >= 31) begin
                        next_state = DISPLAY_DONE;
                    end
                end
            end

            DISPLAY_DONE: begin
                next_state = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end

    // Output control
    always_comb begin
        lcd_data = 8'h00;
        lcd_write = 1'b0;
        lcd_cmd_data = 1'b0;
        ready = 1'b0;

        case (state)
            IDLE: begin
                ready = !buffer_ready;
            end

            CLEAR_SCREEN: begin
                lcd_data = 8'h01;     // Clear display command
                lcd_write = 1'b1;
                lcd_cmd_data = 1'b0;  // Command
            end

            SET_CURSOR_LINE1: begin
                lcd_data = 8'h80;     // Set DDRAM address to line 1
                lcd_write = 1'b1;
                lcd_cmd_data = 1'b0;  // Command
            end

            WRITE_LINE1_DATA: begin
                lcd_data = display_buffer[char_index];
                lcd_write = 1'b1;
                lcd_cmd_data = 1'b1;  // Data
            end

            SET_CURSOR_LINE2: begin
                lcd_data = 8'hC0;     // Set DDRAM address to line 2
                lcd_write = 1'b1;
                lcd_cmd_data = 1'b0;  // Command
            end

            WRITE_LINE2_DATA: begin
                lcd_data = display_buffer[char_index];
                lcd_write = 1'b1;
                lcd_cmd_data = 1'b1;  // Data
            end

            DISPLAY_DONE: begin
                ready = 1'b1;
            end

            default: ready = 1'b0;
        endcase
    end

endmodule