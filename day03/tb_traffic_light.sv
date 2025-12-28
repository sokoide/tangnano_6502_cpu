// Testbench for Traffic Light Controller
// Tests state machine transitions and timing

module tb_traffic_light;

    logic clk;
    logic rst_n;
    logic red, yellow, green;

    // Test target instantiation with fast timing for simulation
    traffic_light #(
        .TIMER_LIMIT_RED(26'd10),
        .TIMER_LIMIT_GREEN(26'd10),
        .TIMER_LIMIT_YELLOW(26'd5)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .red(red),
        .yellow(yellow),
        .green(green)
    );

    // Clock generation (fast for simulation)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 100MHz for simulation
    end

    initial begin
        $display("Starting Traffic Light Controller tests...");

        // Waveform dump
        $dumpfile("tb_traffic_light.vcd");
        $dumpvars(0, tb_traffic_light);

        // Reset
        rst_n = 0;
        #20 rst_n = 1;

        // Check initial state (should be RED)
        #10;
        assert (red == 1'b1 && yellow == 1'b0 && green == 1'b0)
        else $error("Initial state should be RED");
        $display("Initial state is RED: OK");

        // Wait for RED -> GREEN
        #100;
        assert (red == 1'b0 && yellow == 1'b0 && green == 1'b1)
        else $error("State should have changed to GREEN");
        $display("Transition to GREEN: OK");

        // Wait for GREEN -> YELLOW
        #110;
        assert (red == 1'b0 && yellow == 1'b1 && green == 1'b0)
        else $error("State should have changed to YELLOW");
        $display("Transition to YELLOW: OK");

        // Wait for YELLOW -> RED
        #60;
        assert (red == 1'b1 && yellow == 1'b0 && green == 1'b0)
        else $error("State should have returned to RED");
        $display("Transition back to RED: OK");

        $display("All state machine transitions verified successfully!");
        $finish;
    end

    // Monitor state changes
    /* verilator lint_off SYNCASYNCNET */
    always @(posedge clk) begin
        if (rst_n) begin
            $display("Time %t: RED=%b, YELLOW=%b, GREEN=%b", $time, red, yellow, green);
        end
    end
    /* verilator lint_on SYNCASYNCNET */

endmodule
