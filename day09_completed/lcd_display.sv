// LCD Display Interface
// High-level interface for text display on LCD

module lcd_display (
    input  logic        clk,
    input  logic        rst_n,

    // CPU interface
    input  logic [7:0]  char_data,
    input  logic        char_write,
    input  logic [4:0]  cursor_pos,   // 0-31 for 16x2 display
    input  logic        cursor_set,
    input  logic        clear_screen,

    // LCD controller interface
    output logic [7:0]  lcd_data,
    output logic        lcd_write,
    output logic        lcd_cmd_data,
    input  logic        lcd_busy,

    // Status
    output logic        ready
);

    // State machine states
    typedef enum logic [3:0] {
        IDLE,
        CLEAR_SEND_CMD,
        CLEAR_WAIT,
        CURSOR_SEND_CMD,
        CURSOR_WAIT,
        CHAR_SEND_DATA,
        CHAR_WAIT,
        DONE
    } state_t;

    state_t state, next_state;

    // Internal registers
    logic [7:0] command_data;
    logic       operation_pending;
    logic [2:0] operation_type;  // 0=clear, 1=cursor, 2=char

    // Address calculation for cursor positioning
    logic [7:0] ddram_address;
    always_comb begin
        if (cursor_pos < 16) begin
            // First line: addresses 0x00-0x0F
            ddram_address = 8'h80 | cursor_pos[3:0];
        end else begin
            // Second line: addresses 0x40-0x4F
            ddram_address = 8'hC0 | (cursor_pos[3:0]);
        end
    end

    // State machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            command_data <= 8'h00;
            operation_pending <= 1'b0;
            operation_type <= 3'b000;
        end else begin
            state <= next_state;

            // Capture operations when not busy
            if (state == IDLE && !lcd_busy) begin
                if (clear_screen && !operation_pending) begin
                    operation_pending <= 1'b1;
                    operation_type <= 3'b000;  // Clear
                    command_data <= 8'h01;     // Clear display command
                end else if (cursor_set && !operation_pending) begin
                    operation_pending <= 1'b1;
                    operation_type <= 3'b001;  // Cursor
                    command_data <= ddram_address;
                end else if (char_write && !operation_pending) begin
                    operation_pending <= 1'b1;
                    operation_type <= 3'b010;  // Character
                    command_data <= char_data;
                end
            end

            // Clear pending flag when operation starts
            if (state == CLEAR_SEND_CMD || state == CURSOR_SEND_CMD || state == CHAR_SEND_DATA) begin
                operation_pending <= 1'b0;
            end
        end
    end

    // Next state logic
    always_comb begin
        next_state = state;

        case (state)
            IDLE: begin
                if (!lcd_busy && operation_pending) begin
                    case (operation_type)
                        3'b000: next_state = CLEAR_SEND_CMD;   // Clear
                        3'b001: next_state = CURSOR_SEND_CMD;  // Cursor
                        3'b010: next_state = CHAR_SEND_DATA;   // Character
                        default: next_state = IDLE;
                    endcase
                end
            end

            CLEAR_SEND_CMD: begin
                next_state = CLEAR_WAIT;
            end

            CLEAR_WAIT: begin
                if (!lcd_busy) begin
                    next_state = DONE;
                end
            end

            CURSOR_SEND_CMD: begin
                next_state = CURSOR_WAIT;
            end

            CURSOR_WAIT: begin
                if (!lcd_busy) begin
                    next_state = DONE;
                end
            end

            CHAR_SEND_DATA: begin
                next_state = CHAR_WAIT;
            end

            CHAR_WAIT: begin
                if (!lcd_busy) begin
                    next_state = DONE;
                end
            end

            DONE: begin
                next_state = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end

    // Output control
    always_comb begin
        lcd_data = 8'h00;
        lcd_write = 1'b0;
        lcd_cmd_data = 1'b0;  // Default to command
        ready = 1'b0;

        case (state)
            IDLE: begin
                ready = !operation_pending && !lcd_busy;
            end

            CLEAR_SEND_CMD: begin
                lcd_data = command_data;
                lcd_write = 1'b1;
                lcd_cmd_data = 1'b0;  // Command
            end

            CURSOR_SEND_CMD: begin
                lcd_data = command_data;
                lcd_write = 1'b1;
                lcd_cmd_data = 1'b0;  // Command
            end

            CHAR_SEND_DATA: begin
                lcd_data = command_data;
                lcd_write = 1'b1;
                lcd_cmd_data = 1'b1;  // Data
            end

            DONE: begin
                ready = 1'b1;
            end

            default: begin
                ready = 1'b0;
            end
        endcase
    end

endmodule