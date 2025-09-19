// Testbench for 6502 CPU Registers
// Test register read/write operations

module tb_cpu_registers;

    logic clk;
    logic rst_n;
    logic a_write, x_write, y_write, sp_write, pc_write, p_write;
    logic [7:0] data_in;
    logic [15:0] addr_in;
    logic [7:0] reg_a, reg_x, reg_y, reg_sp, reg_p;
    logic [15:0] reg_pc;

    // Test target instantiation
    cpu_registers uut (
        .clk(clk),
        .rst_n(rst_n),
        .a_write(a_write),
        .x_write(x_write),
        .y_write(y_write),
        .sp_write(sp_write),
        .pc_write(pc_write),
        .p_write(p_write),
        .data_in(data_in),
        .addr_in(addr_in),
        .reg_a(reg_a),
        .reg_x(reg_x),
        .reg_y(reg_y),
        .reg_sp(reg_sp),
        .reg_pc(reg_pc),
        .reg_p(reg_p)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $display("Starting 6502 CPU Register tests...");

        // Initialize signals
        rst_n = 0;
        {a_write, x_write, y_write, sp_write, pc_write, p_write} = 6'b000000;
        data_in = 8'h00;
        addr_in = 16'h0000;

        // Reset test
        #20 rst_n = 1;
        #10;

        // Check reset values
        assert (reg_a == 8'h00) else $error("Reset: A should be 0x00");
        assert (reg_x == 8'h00) else $error("Reset: X should be 0x00");
        assert (reg_y == 8'h00) else $error("Reset: Y should be 0x00");
        assert (reg_sp == 8'hFF) else $error("Reset: SP should be 0xFF");
        assert (reg_pc == 16'h0200) else $error("Reset: PC should be 0x0200");
        assert (reg_p == 8'h20) else $error("Reset: P should be 0x20");
        $display("Test 1 passed: Reset values correct");

        // Test A register write
        data_in = 8'h55;
        a_write = 1'b1;
        #10;
        a_write = 1'b0;
        #10;
        assert (reg_a == 8'h55) else $error("A register write failed");
        $display("Test 2 passed: A register write = 0x%02X", reg_a);

        // Test X register write
        data_in = 8'hAA;
        x_write = 1'b1;
        #10;
        x_write = 1'b0;
        #10;
        assert (reg_x == 8'hAA) else $error("X register write failed");
        $display("Test 3 passed: X register write = 0x%02X", reg_x);

        // Test Y register write
        data_in = 8'h33;
        y_write = 1'b1;
        #10;
        y_write = 1'b0;
        #10;
        assert (reg_y == 8'h33) else $error("Y register write failed");
        $display("Test 4 passed: Y register write = 0x%02X", reg_y);

        // Test SP register write
        data_in = 8'hF0;
        sp_write = 1'b1;
        #10;
        sp_write = 1'b0;
        #10;
        assert (reg_sp == 8'hF0) else $error("SP register write failed");
        $display("Test 5 passed: SP register write = 0x%02X", reg_sp);

        // Test PC register write
        addr_in = 16'h1234;
        pc_write = 1'b1;
        #10;
        pc_write = 1'b0;
        #10;
        assert (reg_pc == 16'h1234) else $error("PC register write failed");
        $display("Test 6 passed: PC register write = 0x%04X", reg_pc);

        // Test P register write
        data_in = 8'hC3;
        p_write = 1'b1;
        #10;
        p_write = 1'b0;
        #10;
        assert (reg_p == 8'hC3) else $error("P register write failed");
        $display("Test 7 passed: P register write = 0x%02X", reg_p);

        // Test simultaneous writes (should all work)
        data_in = 8'h77;
        addr_in = 16'h5678;
        {a_write, x_write, y_write, sp_write, pc_write, p_write} = 6'b111111;
        #10;
        {a_write, x_write, y_write, sp_write, pc_write, p_write} = 6'b000000;
        #10;
        assert (reg_a == 8'h77) else $error("Simultaneous write A failed");
        assert (reg_x == 8'h77) else $error("Simultaneous write X failed");
        assert (reg_y == 8'h77) else $error("Simultaneous write Y failed");
        assert (reg_sp == 8'h77) else $error("Simultaneous write SP failed");
        assert (reg_pc == 16'h5678) else $error("Simultaneous write PC failed");
        assert (reg_p == 8'h77) else $error("Simultaneous write P failed");
        $display("Test 8 passed: Simultaneous writes successful");

        $display("All CPU register tests completed successfully!");
        $finish;
    end

endmodule