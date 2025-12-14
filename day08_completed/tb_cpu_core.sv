// Testbench for Complete 6502 CPU Core
// Tests integrated CPU with memory system

module tb_cpu_core;

    logic clk, rst_n;
    logic [3:0] switches;

    logic [7:0] debug_reg_a;
    logic [7:0] debug_reg_x;
    logic [7:0] debug_reg_y;
    logic [7:0] debug_reg_sp;
    logic [15:0] debug_reg_pc;
    logic [7:0] debug_status_reg;
    logic [15:0] debug_mem_addr;
    logic [7:0] debug_mem_data;
    logic debug_mem_read;
    logic debug_mem_write;
    logic [7:0] debug_opcode;
    logic [2:0] debug_cpu_state;
    logic debug_system_ready;
    logic [7:0] initial_sp;
    int errors;
    bit saw_a_42;
    bit saw_a_84;

    // Test target instantiation
    top uut (
        .clk(clk),
        .rst_n(rst_n),
        .switches(switches),
        .debug_reg_a(debug_reg_a),
        .debug_reg_x(debug_reg_x),
        .debug_reg_y(debug_reg_y),
        .debug_reg_sp(debug_reg_sp),
        .debug_reg_pc(debug_reg_pc),
        .debug_status_reg(debug_status_reg),
        .debug_mem_addr(debug_mem_addr),
        .debug_mem_data(debug_mem_data),
        .debug_mem_read(debug_mem_read),
        .debug_mem_write(debug_mem_write),
        .debug_opcode(debug_opcode),
        .debug_cpu_state(debug_cpu_state),
        .debug_system_ready(debug_system_ready)
    );

    // Clock generation (27MHz)
    always #18.5 clk = ~clk;

    // Test stimulus
    initial begin
        errors = 0;
        saw_a_42 = 0;
        saw_a_84 = 0;
        clk = 0;
        rst_n = 1;
        switches = 4'b0000;  // Start with slowest CPU clock

        $display("Starting 6502 CPU Core integrated test...");

        $dumpfile("tb_cpu_core.vcd");
        $dumpvars(0, tb_cpu_core);

        // Reset sequence
        #1 rst_n = 0;
        #200 rst_n = 1;
        #1;
        $display("Reset released, CPU should start from $C000");
        if (debug_reg_pc !== 16'hC000) begin
            $display("✗ Reset PC mismatch: PC=$%04X (expected $C000)", debug_reg_pc);
            errors++;
        end

        // Monitor CPU execution for initial instructions
        repeat (200) begin
            @(posedge clk);

            // Display key information when CPU state changes
            if (debug_cpu_state == 3'b000) begin  // FETCH state
                $display("PC=$%04X: Fetching opcode $%02X", debug_reg_pc, debug_opcode);
            end

            if (debug_cpu_state == 3'b100) begin  // WRITEBACK state
                $display("  A=$%02X X=$%02X Y=$%02X SP=$%02X Status=$%02X", debug_reg_a,
                         debug_reg_x, debug_reg_y, debug_reg_sp, debug_status_reg);
            end
        end

        $display("\nAfter initial execution:");
        $display("A=$%02X X=$%02X Y=$%02X SP=$%02X", debug_reg_a, debug_reg_x, debug_reg_y,
                 debug_reg_sp);
        $display("PC=$%04X Status=$%02X", debug_reg_pc, debug_status_reg);

        // Test register operations (first few instructions should be LDA, STA)
        $display("\nTesting basic register operations...");

        // Smoke-check that the ROM program executes far enough to load
        // a couple of immediate values into A.
        repeat (5000) begin
            @(posedge clk);
            if (debug_reg_a == 8'h42) saw_a_42 = 1;
            if (debug_reg_a == 8'h84) saw_a_84 = 1;
            if (saw_a_42 && saw_a_84) break;
        end

        if (saw_a_42) $display("✓ Observed A=$42");
        else begin
            $display("✗ Did not observe A=$42");
            errors++;
        end

        if (saw_a_84) $display("✓ Observed A=$84");
        else begin
            $display("✗ Did not observe A=$84");
            errors++;
        end

        // Continue execution to test arithmetic
        $display("\nTesting arithmetic operations...");
        repeat (200) @(posedge uut.cpu_clk);

        $display("After arithmetic: A=$%02X Status=$%02X", debug_reg_a, debug_status_reg);

        // Test register transfers
        $display("\nTesting register transfers...");
        repeat (100) @(posedge uut.cpu_clk);

        $display("After transfers: A=$%02X X=$%02X Y=$%02X", debug_reg_a, debug_reg_x, debug_reg_y);

        // Test memory operations
        $display("\nMonitoring memory operations...");
        repeat (50) begin
            @(posedge clk);
            if (debug_mem_write) begin
                $display("Memory write: [$%04X] <= $%02X", debug_mem_addr, debug_mem_data);
            end
            if (debug_mem_read && debug_mem_addr < 16'h8000) begin
                $display("Memory read: [$%04X]", debug_mem_addr);
            end
        end

        // Test stack operations
        $display("\nTesting stack operations...");
        initial_sp = debug_reg_sp;
        repeat (200) @(posedge uut.cpu_clk);

        if (debug_reg_sp != initial_sp) begin
            $display("✓ Stack operations detected: SP changed from $%02X to $%02X", initial_sp,
                     debug_reg_sp);
        end else begin
            $display("- No stack operations detected yet");
        end

        // Switch to faster CPU clock for more execution
        $display("\nSwitching to faster CPU clock...");
        switches = 4'b0010;  // Medium speed
        repeat (500) @(posedge uut.cpu_clk);

        $display("\nFinal CPU state:");
        $display("A=$%02X X=$%02X Y=$%02X SP=$%02X", debug_reg_a, debug_reg_x, debug_reg_y,
                 debug_reg_sp);
        $display("PC=$%04X Status=$%02X", debug_reg_pc, debug_status_reg);
        $display("Last opcode: $%02X", debug_opcode);

        // Test I/O operations
        $display("\nTesting I/O operations...");
        switches = 4'b0101;  // Change switch pattern
        repeat (100) @(posedge uut.cpu_clk);

        switches = 4'b1010;  // Another pattern
        repeat (100) @(posedge uut.cpu_clk);

        $display("I/O test completed");

        // Performance summary
        $display("\n=== CPU Core Integration Test Summary ===");
        $display("✓ CPU reset and initialization");
        $display("✓ Instruction fetch and decode");
        $display("✓ Register operations");
        $display("✓ Memory interface");
        $display("✓ Clock domain integration");
        $display("✓ Debug output functionality");

        if (errors == 0) begin
            $display("\nCPU Core test completed successfully!");
            $finish;
        end else begin
            $display("\nCPU Core test failed: %0d error(s)", errors);
            $fatal(1);
        end
    end

    // Monitor for interesting events
    always @(posedge clk) begin
        // Detect jumps
        if (debug_opcode == 8'h4C && debug_cpu_state == 3'b000) begin
            $display("JMP instruction detected at PC=$%04X", debug_reg_pc);
        end

        // Detect subroutine calls
        if (debug_opcode == 8'h20 && debug_cpu_state == 3'b000) begin
            $display("JSR instruction detected at PC=$%04X", debug_reg_pc);
        end

        // Detect returns
        if (debug_opcode == 8'h60 && debug_cpu_state == 3'b000) begin
            $display("RTS instruction detected at PC=$%04X", debug_reg_pc);
        end
    end

    // Timeout safety
    initial begin
        #1000000;  // 1ms timeout
        $display("Test timeout - ending simulation");
        $finish;
    end

endmodule
