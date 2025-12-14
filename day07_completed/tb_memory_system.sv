// Testbench for 6502 Memory System
// Tests memory interface, stack operations, and memory mapping

module tb_memory_system;

    logic clk, rst_n;
    logic [15:0] cpu_addr;
    logic [7:0] cpu_data_out, cpu_data_in;
    logic cpu_mem_read, cpu_mem_write, cpu_ready;

    logic stack_push, stack_pop;
    logic [7:0] stack_data_out, stack_data_in;
    logic [ 7:0] stack_pointer;

    logic [15:0] ext_addr;
    logic [7:0] ext_data_out, ext_data_in;
    logic ext_oe, ext_we;
    logic ram_select, rom_select, io_select;

    // RAM and ROM data
    logic [7:0] ram_data, rom_data;

    // Test target instantiation
    memory_controller mem_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .cpu_addr(cpu_addr),
        .cpu_data_out(cpu_data_out),
        .cpu_data_in(cpu_data_in),
        .cpu_mem_read(cpu_mem_read),
        .cpu_mem_write(cpu_mem_write),
        .cpu_ready(cpu_ready),
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
        .ram_select(ram_select),
        .rom_select(rom_select),
        .io_select(io_select)
    );

    // Simple RAM model
    logic [7:0] ram_array[0:32767];  // 32KB
    always_ff @(posedge clk) begin
        if (ram_select && ext_we) begin
            ram_array[ext_addr[14:0]] <= ext_data_out;
        end
    end
    assign ram_data = ram_select ? ram_array[ext_addr[14:0]] : 8'hZZ;

    // Simple ROM model
    logic [7:0] rom_array[0:16383];  // 16KB
    initial begin
        for (int i = 0; i < 16384; i++) begin
            rom_array[i] = 8'hA5 + i[7:0];  // Test pattern
        end
    end
    assign rom_data = rom_select ? rom_array[ext_addr[13:0]] : 8'hZZ;

    // External data input
    assign ext_data_in = ram_select ? ram_data : rom_select ? rom_data : 8'h00;

    // Clock generation
    always #5 clk = ~clk;

    // Trace external bus activity
    always_ff @(posedge clk) begin
        if (ext_we) begin
            $display("  [bus] WRITE addr=$%04X data=$%02X (ram=%b rom=%b io=%b)", ext_addr,
                     ext_data_out, ram_select, rom_select, io_select);
        end
        if (ext_oe) begin
            $display("  [bus] READ  addr=$%04X (ram=%b rom=%b io=%b)", ext_addr, ram_select,
                     rom_select, io_select);
        end
    end

    task automatic cpu_write(input logic [15:0] addr, input logic [7:0] data);
        // Start on a clean IDLE cycle (cpu_ready can be high in WAIT or IDLE).
        while (!cpu_ready) @(posedge clk);
        @(posedge clk);
        cpu_addr = addr;
        cpu_data_out = data;
        cpu_mem_write = 1'b1;
        @(negedge cpu_ready);
        @(posedge cpu_ready);
        cpu_mem_write = 1'b0;
        #1;
    endtask

    task automatic cpu_read_expect(input logic [15:0] addr, input logic [7:0] expected);
        while (!cpu_ready) @(posedge clk);
        @(posedge clk);
        cpu_addr = addr;
        cpu_mem_read = 1'b1;
        @(negedge cpu_ready);
        @(posedge cpu_ready);
        cpu_mem_read = 1'b0;
        assert (cpu_data_in == expected)
        else $error("Read failed @ $%04X: expected $%02X, got $%02X", addr, expected, cpu_data_in);
        #1;
    endtask

    task automatic stack_push_byte(input logic [7:0] data);
        while (!cpu_ready) @(posedge clk);
        @(posedge clk);
        stack_data_out = data;
        stack_push = 1'b1;
        @(negedge cpu_ready);
        @(posedge cpu_ready);
        stack_push = 1'b0;
        #1;
    endtask

    task automatic stack_pop_expect(input logic [7:0] expected);
        while (!cpu_ready) @(posedge clk);
        @(posedge clk);
        stack_pop = 1'b1;
        @(negedge cpu_ready);
        @(posedge cpu_ready);
        stack_pop = 1'b0;
        assert (stack_data_in == expected)
        else $error("Stack pop failed: expected $%02X, got $%02X", expected, stack_data_in);
        #1;
    endtask

    initial begin
        clk = 0;
        rst_n = 0;
        cpu_addr = 16'h0000;
        cpu_data_out = 8'h00;
        cpu_mem_read = 0;
        cpu_mem_write = 0;
        stack_push = 0;
        stack_pop = 0;
        stack_data_out = 8'h00;

        // Initialize RAM
        for (int i = 0; i < 32768; i++) begin
            ram_array[i] = 8'h00;
        end

        $display("Starting 6502 Memory System tests...");

        $dumpfile("tb_memory_system.vcd");
        $dumpvars(0, tb_memory_system);

        // Reset
        #20 rst_n = 1;
        #10;

        // Test 1: Memory address decoding
        $display("\nTest 1: Memory address decoding");

        cpu_addr = 16'h4000;  // RAM
        #10;
        assert (ram_select == 1'b1)
        else $error("RAM not selected for address $4000");
        assert (rom_select == 1'b0)
        else $error("ROM incorrectly selected for address $4000");

        cpu_addr = 16'hC000;  // ROM
        #10;
        assert (rom_select == 1'b1)
        else $error("ROM not selected for address $C000");
        assert (ram_select == 1'b0)
        else $error("RAM incorrectly selected for address $C000");

        cpu_addr = 16'h9000;  // I/O
        #10;
        assert (io_select == 1'b1)
        else $error("I/O not selected for address $9000");
        $display("Test 1 passed: Address decoding working correctly");

        // Test 2: RAM write/read
        $display("\nTest 2: RAM write/read operations");

        cpu_write(16'h0200, 8'h42);
        cpu_read_expect(16'h0200, 8'h42);
        $display("Test 2 passed: RAM write/read = $%02X", cpu_data_in);

        // Test 3: ROM read
        $display("\nTest 3: ROM read operations");

        cpu_read_expect(16'hC010, 8'hB5);
        $display("Test 3 passed: ROM read = $%02X", cpu_data_in);

        // Test 4: Stack push operations
        $display("\nTest 4: Stack push operations");

        stack_push_byte(8'h55);
        $display("  SP after push #1 = $%02X", stack_pointer);
        assert (stack_pointer == 8'hFE)
        else $error("Stack pointer not decremented correctly");
        #10;

        stack_push_byte(8'hAA);
        $display("  SP after push #2 = $%02X", stack_pointer);
        assert (stack_pointer == 8'hFD)
        else $error("Stack pointer not decremented correctly");
        $display("Test 4 passed: Stack pushes, SP = $%02X", stack_pointer);

        // Test 5: Stack pop operations
        $display("\nTest 5: Stack pop operations");

        stack_pop_expect(8'hAA);
        assert (stack_pointer == 8'hFE)
        else $error("Stack pointer not incremented correctly");
        #10;

        stack_pop_expect(8'h55);
        assert (stack_pointer == 8'hFF)
        else $error("Stack pointer not incremented correctly");
        $display("Test 5 passed: Stack pops, SP = $%02X", stack_pointer);

        // Test 6: Zero page access
        $display("\nTest 6: Zero page access");

        cpu_write(16'h0080, 8'h33);
        $display("  RAM[0080] after write = $%02X", ram_array[15'h0080]);
        cpu_read_expect(16'h0080, 8'h33);
        $display("Test 6 passed: Zero page write/read = $%02X", cpu_data_in);

        // Test 7: Stack page direct access
        $display("\nTest 7: Stack page direct access");

        cpu_write(16'h01F0, 8'h77);
        cpu_read_expect(16'h01F0, 8'h77);
        $display("Test 7 passed: Stack page write/read = $%02X", cpu_data_in);

        $display("\nAll 6502 Memory System tests completed successfully!");
        $finish;
    end

endmodule
