// LCD Controller for HD44780-compatible displays
// Supports 16x2 and 20x4 LCD displays with 4-bit interface

module lcd_controller (
    input  logic       clk,
    input  logic       rst_n,

    // CPU interface
    input  logic [7:0] data_in,
    input  logic       write_enable,
    input  logic       cmd_data_select,  // 0=command, 1=data
    output logic       busy,

    // LCD interface (4-bit mode)
    output logic       lcd_rs,    // Register select (0=cmd, 1=data)
    output logic       lcd_rw,    // Read/Write (always 0 for write)
    output logic       lcd_en,    // Enable pulse
    output logic [3:0] lcd_data   // 4-bit data bus
);

    // Timing parameters (for 27MHz clock)
    localparam DELAY_15MS  = 27'd405000;   // 15ms initialization delay
    localparam DELAY_4_1MS = 27'd110700;   // 4.1ms initialization delay
    localparam DELAY_100US = 27'd2700;     // 100us initialization delay
    localparam DELAY_40US  = 27'd1080;     // 40us command delay
    localparam DELAY_2MS   = 27'd54000;    // 2ms clear/home delay
    localparam ENABLE_HIGH = 27'd27;       // 1us enable pulse width
    localparam ENABLE_LOW  = 27'd27;       // 1us enable low time

    // State machine states
    typedef enum logic [4:0] {
        POWER_UP,
        INIT_DELAY_15MS,
        INIT_FUNC_SET_1,
        INIT_DELAY_4_1MS,
        INIT_FUNC_SET_2,
        INIT_DELAY_100US,
        INIT_FUNC_SET_3,
        INIT_DELAY_40US_1,
        INIT_FUNC_SET_4BIT,
        INIT_DELAY_40US_2,
        INIT_DISPLAY_OFF,
        INIT_DELAY_40US_3,
        INIT_DISPLAY_CLEAR,
        INIT_DELAY_2MS,
        INIT_ENTRY_MODE,
        INIT_DELAY_40US_4,
        INIT_DISPLAY_ON,
        INIT_DELAY_40US_5,
        READY,
        WRITE_HIGH_NIBBLE,
        ENABLE_HIGH_1,
        ENABLE_LOW_1,
        WRITE_LOW_NIBBLE,
        ENABLE_HIGH_2,
        ENABLE_LOW_2,
        WRITE_DELAY
    } state_t;

    state_t state, next_state;

    // Internal registers
    logic [26:0] delay_counter;
    logic [7:0]  write_data;
    logic        cmd_data_reg;
    logic        write_pending;

    // Control signals
    logic start_write;
    logic enable_pulse;
    logic high_nibble;

    // State machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= POWER_UP;
            delay_counter <= 27'b0;
            write_data <= 8'h00;
            cmd_data_reg <= 1'b0;
            write_pending <= 1'b0;
        end else begin
            state <= next_state;

            // Delay counter
            if (delay_counter > 0) begin
                delay_counter <= delay_counter - 1;
            end

            // Capture write request
            if (write_enable && state == READY && !write_pending) begin
                write_data <= data_in;
                cmd_data_reg <= cmd_data_select;
                write_pending <= 1'b1;
            end

            if (state == WRITE_HIGH_NIBBLE) begin
                write_pending <= 1'b0;
            end
        end
    end

    // Next state logic
    always_comb begin
        next_state = state;
        start_write = 1'b0;

        case (state)
            POWER_UP: begin
                delay_counter = DELAY_15MS;
                next_state = INIT_DELAY_15MS;
            end

            INIT_DELAY_15MS: begin
                if (delay_counter == 0) begin
                    next_state = INIT_FUNC_SET_1;
                end
            end

            INIT_FUNC_SET_1: begin
                delay_counter = DELAY_4_1MS;
                next_state = INIT_DELAY_4_1MS;
            end

            INIT_DELAY_4_1MS: begin
                if (delay_counter == 0) begin
                    next_state = INIT_FUNC_SET_2;
                end
            end

            INIT_FUNC_SET_2: begin
                delay_counter = DELAY_100US;
                next_state = INIT_DELAY_100US;
            end

            INIT_DELAY_100US: begin
                if (delay_counter == 0) begin
                    next_state = INIT_FUNC_SET_3;
                end
            end

            INIT_FUNC_SET_3: begin
                delay_counter = DELAY_40US;
                next_state = INIT_DELAY_40US_1;
            end

            INIT_DELAY_40US_1: begin
                if (delay_counter == 0) begin
                    next_state = INIT_FUNC_SET_4BIT;
                end
            end

            INIT_FUNC_SET_4BIT: begin
                delay_counter = DELAY_40US;
                next_state = INIT_DELAY_40US_2;
            end

            INIT_DELAY_40US_2: begin
                if (delay_counter == 0) begin
                    next_state = INIT_DISPLAY_OFF;
                end
            end

            INIT_DISPLAY_OFF: begin
                delay_counter = DELAY_40US;
                next_state = INIT_DELAY_40US_3;
            end

            INIT_DELAY_40US_3: begin
                if (delay_counter == 0) begin
                    next_state = INIT_DISPLAY_CLEAR;
                end
            end

            INIT_DISPLAY_CLEAR: begin
                delay_counter = DELAY_2MS;
                next_state = INIT_DELAY_2MS;
            end

            INIT_DELAY_2MS: begin
                if (delay_counter == 0) begin
                    next_state = INIT_ENTRY_MODE;
                end
            end

            INIT_ENTRY_MODE: begin
                delay_counter = DELAY_40US;
                next_state = INIT_DELAY_40US_4;
            end

            INIT_DELAY_40US_4: begin
                if (delay_counter == 0) begin
                    next_state = INIT_DISPLAY_ON;
                end
            end

            INIT_DISPLAY_ON: begin
                delay_counter = DELAY_40US;
                next_state = INIT_DELAY_40US_5;
            end

            INIT_DELAY_40US_5: begin
                if (delay_counter == 0) begin
                    next_state = READY;
                end
            end

            READY: begin
                if (write_pending) begin
                    next_state = WRITE_HIGH_NIBBLE;
                    start_write = 1'b1;
                end
            end

            WRITE_HIGH_NIBBLE: begin
                delay_counter = ENABLE_HIGH;
                next_state = ENABLE_HIGH_1;
            end

            ENABLE_HIGH_1: begin
                if (delay_counter == 0) begin
                    delay_counter = ENABLE_LOW;
                    next_state = ENABLE_LOW_1;
                end
            end

            ENABLE_LOW_1: begin
                if (delay_counter == 0) begin
                    next_state = WRITE_LOW_NIBBLE;
                end
            end

            WRITE_LOW_NIBBLE: begin
                delay_counter = ENABLE_HIGH;
                next_state = ENABLE_HIGH_2;
            end

            ENABLE_HIGH_2: begin
                if (delay_counter == 0) begin
                    delay_counter = ENABLE_LOW;
                    next_state = ENABLE_LOW_2;
                end
            end

            ENABLE_LOW_2: begin
                if (delay_counter == 0) begin
                    delay_counter = DELAY_40US;
                    next_state = WRITE_DELAY;
                end
            end

            WRITE_DELAY: begin
                if (delay_counter == 0) begin
                    next_state = READY;
                end
            end

            default: next_state = POWER_UP;
        endcase
    end

    // Output control
    always_comb begin
        lcd_rs = 1'b0;
        lcd_rw = 1'b0;  // Always write mode
        lcd_en = 1'b0;
        lcd_data = 4'h0;
        busy = 1'b1;

        case (state)
            // Initialization sequence
            INIT_FUNC_SET_1, INIT_FUNC_SET_2, INIT_FUNC_SET_3: begin
                lcd_data = 4'h3;  // Function set (8-bit mode initially)
            end

            INIT_FUNC_SET_4BIT: begin
                lcd_data = 4'h2;  // Function set (4-bit mode)
            end

            INIT_DISPLAY_OFF: begin
                lcd_data = 4'h0;  // Display off command high nibble
            end

            INIT_DISPLAY_CLEAR: begin
                lcd_data = 4'h0;  // Clear display command high nibble
            end

            INIT_ENTRY_MODE: begin
                lcd_data = 4'h0;  // Entry mode set command high nibble
            end

            INIT_DISPLAY_ON: begin
                lcd_data = 4'h0;  // Display on command high nibble
            end

            READY: begin
                busy = 1'b0;
            end

            // Write sequence
            WRITE_HIGH_NIBBLE: begin
                lcd_rs = cmd_data_reg;
                lcd_data = write_data[7:4];  // High nibble
            end

            ENABLE_HIGH_1: begin
                lcd_rs = cmd_data_reg;
                lcd_en = 1'b1;
                lcd_data = write_data[7:4];
            end

            ENABLE_LOW_1: begin
                lcd_rs = cmd_data_reg;
                lcd_data = write_data[7:4];
            end

            WRITE_LOW_NIBBLE: begin
                lcd_rs = cmd_data_reg;
                lcd_data = write_data[3:0];  // Low nibble
            end

            ENABLE_HIGH_2: begin
                lcd_rs = cmd_data_reg;
                lcd_en = 1'b1;
                lcd_data = write_data[3:0];
            end

            ENABLE_LOW_2: begin
                lcd_rs = cmd_data_reg;
                lcd_data = write_data[3:0];
            end
        endcase
    end

endmodule