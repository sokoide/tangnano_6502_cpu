// Day 07 Completed: Memory Interface and Stack
// Complete memory system with RAM, ROM, and stack operations

module top (
    input  wire clk,
    input  wire rst_n,
    input  wire [3:0] switches,           // Control switches

    // Debug outputs for memory system
    output wire [15:0] debug_mem_addr,    // Current memory address
    output wire [7:0]  debug_mem_data,    // Memory data
    output wire debug_mem_read,           // Memory read signal
    output wire debug_mem_write,          // Memory write signal
    output wire debug_ram_select,         // RAM chip select
    output wire debug_rom_select,         // ROM chip select

    // Debug outputs for stack
    output wire [7:0]  debug_stack_ptr,   // Stack pointer value
    output wire [15:0] debug_stack_addr,  // Stack address
    output wire debug_stack_push,         // Stack push operation
    output wire debug_stack_pop,          // Stack pop operation

    // System status
    output wire [7:0]  debug_system_state,// System state indicator
    output wire debug_ready               // System ready
);

    // Test sequence control
    logic [27:0] test_counter;
    logic [4:0]  test_sequence;
    logic [2:0]  operation_state;

    // Memory system signals
    logic [15:0] mem_addr;
    logic [7:0]  mem_data_out;
    logic [7:0]  mem_data_in;
    logic        mem_read;
    logic        mem_write;
    logic        mem_ready;

    // Stack signals
    logic        stack_push;
    logic        stack_pop;
    logic [7:0]  stack_data_out;
    logic [7:0]  stack_data_in;
    logic [7:0]  stack_pointer;

    // External memory signals
    logic [15:0] ext_addr;
    logic [7:0]  ext_data_out;
    logic [7:0]  ext_data_in;
    logic        ext_oe;
    logic        ext_we;

    // Memory map signals
    logic        ram_cs;
    logic        rom_cs;
    logic        io_cs;

    // RAM signals
    logic [7:0]  ram_data_out;

    // ROM signals
    logic [7:0]  rom_data_out;

    // Test data
    logic [7:0]  test_values [0:7];

    // Initialize test data
    initial begin
        test_values[0] = 8'h42;
        test_values[1] = 8'h84;
        test_values[2] = 8'hAA;
        test_values[3] = 8'h55;
        test_values[4] = 8'hFF;
        test_values[5] = 8'h00;
        test_values[6] = 8'h13;
        test_values[7] = 8'h37;
    end

    // Memory Controller
    memory_controller mem_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .cpu_addr(mem_addr),
        .cpu_data_out(mem_data_out),
        .cpu_data_in(mem_data_in),
        .cpu_mem_read(mem_read),
        .cpu_mem_write(mem_write),
        .cpu_ready(mem_ready),
        .stack_push(stack_push),
        .stack_pop(stack_pop),
        .stack_data_out(stack_data_out),
        .stack_data_in(stack_data_in),
        .stack_pointer(stack_pointer),
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

    // ROM Instance (16KB)
    simple_rom #(
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
        end else begin
            ext_data_in = 8'h00;  // Default for I/O space
        end
    end

    // Test sequence controller
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            test_counter <= 28'b0;
            test_sequence <= 5'b00000;
            operation_state <= 3'b000;

            mem_addr <= 16'h0000;
            mem_data_out <= 8'h00;
            mem_read <= 1'b0;
            mem_write <= 1'b0;
            stack_push <= 1'b0;
            stack_pop <= 1'b0;
            stack_data_out <= 8'h00;
        end else begin
            test_counter <= test_counter + 1;

            // Default state
            mem_read <= 1'b0;
            mem_write <= 1'b0;
            stack_push <= 1'b0;
            stack_pop <= 1'b0;

            // Manual control with switches
            if (switches[3]) begin
                test_sequence <= {1'b0, switches[2:0]};
                test_counter <= 28'b0;
                operation_state <= 3'b000;
            end

            // Auto-advance every ~0.1 seconds
            if (test_counter[24]) begin
                test_counter <= 28'b0;
                if (operation_state == 3'b111) begin
                    operation_state <= 3'b000;
                    test_sequence <= test_sequence + 1;
                end else begin
                    operation_state <= operation_state + 1;
                end
            end

            // Test operations based on sequence
            case (test_sequence)
                // Memory write test to RAM
                5'b00000: begin
                    case (operation_state)
                        3'b000: begin
                            mem_addr <= 16'h0200;
                            mem_data_out <= test_values[0];
                            mem_write <= 1'b1;
                        end
                        3'b001: begin
                            mem_addr <= 16'h0201;
                            mem_data_out <= test_values[1];
                            mem_write <= 1'b1;
                        end
                    endcase
                end

                // Memory read test from RAM
                5'b00001: begin
                    case (operation_state)
                        3'b000: begin
                            mem_addr <= 16'h0200;
                            mem_read <= 1'b1;
                        end
                        3'b001: begin
                            mem_addr <= 16'h0201;
                            mem_read <= 1'b1;
                        end
                    endcase
                end

                // ROM read test
                5'b00010: begin
                    case (operation_state)
                        3'b000: begin
                            mem_addr <= 16'hC000;  // ROM start
                            mem_read <= 1'b1;
                        end
                        3'b001: begin
                            mem_addr <= 16'hC001;
                            mem_read <= 1'b1;
                        end
                        3'b010: begin
                            mem_addr <= 16'hFFFC;  // Reset vector
                            mem_read <= 1'b1;
                        end
                    endcase
                end

                // Stack push test
                5'b00011: begin
                    case (operation_state)
                        3'b000: begin
                            stack_data_out <= test_values[2];
                            stack_push <= 1'b1;
                        end
                        3'b001: begin
                            stack_data_out <= test_values[3];
                            stack_push <= 1'b1;
                        end
                        3'b010: begin
                            stack_data_out <= test_values[4];
                            stack_push <= 1'b1;
                        end
                    endcase
                end

                // Stack pop test
                5'b00100: begin
                    case (operation_state)
                        3'b000: begin
                            stack_pop <= 1'b1;
                        end
                        3'b001: begin
                            stack_pop <= 1'b1;
                        end
                        3'b010: begin
                            stack_pop <= 1'b1;
                        end
                    endcase
                end

                // Zero page access test
                5'b00101: begin
                    case (operation_state)
                        3'b000: begin
                            mem_addr <= 16'h0080;  // Zero page
                            mem_data_out <= test_values[5];
                            mem_write <= 1'b1;
                        end
                        3'b001: begin
                            mem_addr <= 16'h0080;
                            mem_read <= 1'b1;
                        end
                    endcase
                end

                // Stack page direct access
                5'b00110: begin
                    case (operation_state)
                        3'b000: begin
                            mem_addr <= 16'h01FE;  // Stack page
                            mem_data_out <= test_values[6];
                            mem_write <= 1'b1;
                        end
                        3'b001: begin
                            mem_addr <= 16'h01FE;
                            mem_read <= 1'b1;
                        end
                    endcase
                end

                default: begin
                    // Loop back to start
                    test_sequence <= 5'b00000;
                end
            endcase
        end
    end

    // Debug outputs
    assign debug_mem_addr = ext_addr;
    assign debug_mem_data = ext_data_out;
    assign debug_mem_read = mem_read;
    assign debug_mem_write = mem_write;
    assign debug_ram_select = ram_cs;
    assign debug_rom_select = rom_cs;

    assign debug_stack_ptr = stack_pointer;
    assign debug_stack_addr = {8'h01, stack_pointer};
    assign debug_stack_push = stack_push;
    assign debug_stack_pop = stack_pop;

    assign debug_system_state = {test_sequence[2:0], operation_state, mem_ready, 1'b0};
    assign debug_ready = mem_ready;

endmodule