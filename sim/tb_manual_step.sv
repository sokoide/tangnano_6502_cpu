// A pulse arriving on a synchronous read settle edge is queued exactly once.
`timescale 1ns / 1ps
module tb_manual_step;
    logic clk = 0, rst_n = 0, pc_enable = 0;
    logic [15:0] address_bus, debug_pc;
    logic [7:0] data_in, data_out, debug_a, debug_x, debug_y, debug_p, debug_s;
    logic write_en;
`ifdef DAY18_CPU
    logic vram_clear, show_info;
`endif
    cpu dut (
        .clk(clk),
        .rst_n(rst_n),
        .pc_enable(pc_enable),
        .address_bus(address_bus),
        .data_in(data_in),
        .data_out(data_out),
        .write_en(write_en),
        .debug_pc(debug_pc),
        .debug_a(debug_a),
        .debug_x(debug_x),
        .debug_y(debug_y),
        .debug_p(debug_p),
        .debug_s(debug_s)
`ifdef DAY18_CPU,
        .memory_hold(1'b0),
        .vsync(1'b0),
        .vram_clear(vram_clear),
        .show_info(show_info)
`endif
    );
    ram u_ram (
        .clk(clk),
        .addr(address_bus[14:0]),
        .write_en(write_en),
        .din(data_out),
        .dout(data_in)
    );
    always #5 clk = ~clk;
    initial begin
        u_ram.mem['h200] = 'ha9;
        u_ram.mem['h201] = 'h42;
        u_ram.mem['h202] = 'hef;
        @(negedge clk);
        rst_n = 1;
        pc_enable = 1;
        @(posedge clk);
        #1;
        assert (debug_pc == 16'h200)
        else $fatal(1, "Initial read was not primed");
        @(negedge clk);
        pc_enable = 0;
        @(posedge clk);
        #1;
        assert (debug_pc == 16'h201)
        else $fatal(1, "Initial queued pulse lost");
        @(negedge clk);
        pc_enable = 1;
        @(posedge clk);
        #1;
        assert (debug_pc == 16'h201)
        else $fatal(1, "Operand consumed before RAM response");
        @(negedge clk);
        pc_enable = 0;
        @(posedge clk);
        #1;
        assert (debug_pc == 16'h202 && debug_a == 8'h42)
        else $fatal(1, "Second queued pulse lost");
        repeat (16) begin
            @(posedge clk);
            #1;
            assert (debug_pc == 16'h202 && !write_en)
            else $fatal(1, "Step replayed without enable");
        end
        $display("PASS: settle-cycle manual pulses queued once");
        $finish;
    end
    initial begin
        #1000;
        $fatal(1, "Manual step watchdog");
    end
endmodule
