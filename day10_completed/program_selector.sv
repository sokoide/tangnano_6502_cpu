// Program Selector for Assembly Examples
// Allows switching between different example programs

module program_selector (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [3:0]  program_select,  // Switch selection
    input  logic        program_start,   // Start button

    // CPU control
    output logic        cpu_reset,
    output logic [15:0] start_address,

    // Status outputs
    output logic [3:0]  current_program,
    output logic        program_running
);

    // Program start addresses
    localparam logic [15:0] PROGRAM_ADDRESSES [0:15] = '{
        16'hC000,  // Program 0: Basic Arithmetic
        16'hC020,  // Program 1: Loop with Counter
        16'hC040,  // Program 2: Data Manipulation
        16'hC060,  // Program 3: Subroutine with Stack
        16'hC080,  // Program 4: Array Processing
        16'hC0C0,  // Program 5: String Operations
        16'hC0E0,  // Program 6: Math Functions
        16'hC100,  // Program 7: I/O Operations
        16'hC000,  // Program 8: Back to start
        16'hC000,  // Program 9: Back to start
        16'hC000,  // Program 10: Back to start
        16'hC000,  // Program 11: Back to start
        16'hC000,  // Program 12: Back to start
        16'hC000,  // Program 13: Back to start
        16'hC000,  // Program 14: Back to start
        16'hC000   // Program 15: Back to start
    };

    // Internal registers
    logic [3:0]  selected_program;
    logic        reset_active;
    logic [3:0]  reset_counter;
    logic        start_pressed;
    logic        start_prev;

    // Edge detection for start button
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            start_prev <= 1'b0;
            start_pressed <= 1'b0;
        end else begin
            start_prev <= program_start;
            start_pressed <= program_start && !start_prev;
        end
    end

    // Program selection and reset control
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            selected_program <= 4'h0;
            reset_active <= 1'b1;
            reset_counter <= 4'hF;
            program_running <= 1'b0;
        end else begin
            // Handle reset timing
            if (reset_counter > 0) begin
                reset_counter <= reset_counter - 1;
                reset_active <= 1'b1;
            end else begin
                reset_active <= 1'b0;
                program_running <= 1'b1;
            end

            // Handle program selection
            if (start_pressed || selected_program != program_select) begin
                selected_program <= program_select;
                reset_counter <= 4'hF;  // Start reset sequence
                program_running <= 1'b0;
            end
        end
    end

    // Output assignments
    assign cpu_reset = ~rst_n || reset_active;
    assign start_address = PROGRAM_ADDRESSES[selected_program];
    assign current_program = selected_program;

endmodule