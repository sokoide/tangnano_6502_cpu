// Short vsync pulses on settle cycles must survive until WVS consumes them.
`timescale 1ns/1ps
module tb_day18_vsync;
    logic clk=0,rst_n=0,pc_enable=1,memory_hold=0,vsync=0;
    logic [15:0] address_bus,debug_pc;
    logic [7:0] data_in,data_out,debug_a,debug_x,debug_y,debug_p,debug_s;
    logic write_en,vram_clear,show_info;
    cpu dut(.*);
    ram u_ram(.clk(clk),.addr(address_bus[14:0]),.write_en(write_en),.din(data_out),.dout(data_in));
    always #5 clk=~clk;
    task automatic pulse_on_settle;
        // At a negedge with ready=0, the next edge is a memory settle edge.
        @(negedge clk);
        while(dut.memory_ready) @(negedge clk);
        vsync=1;
        @(negedge clk);vsync=0;
    endtask
    task automatic wait_pc(input logic [15:0] target);
        for(int i=0;i<40;i++) begin
            @(posedge clk);#1;if(debug_pc==target)return;
        end
        $fatal(1,"WVS did not reach PC=%h got=%h",target,debug_pc);
    endtask
    initial begin
        for(int i=0;i<32768;i++)u_ram.mem[i]='hea;
        // WVS #2 / WVS #0 / HLT. Count zero retains existing one-edge contract.
        u_ram.mem['h200]='hff;u_ram.mem['h201]=2;
        u_ram.mem['h202]='hff;u_ram.mem['h203]=0;u_ram.mem['h204]='hef;
        repeat(3)@(negedge clk);rst_n=1;
        wait(dut.state==dut.STATE_WAIT_VSYNC);
        pc_enable=0;
        pulse_on_settle();
        repeat(4)@(negedge clk);
        assert(debug_pc==16'h0201 && dut.vsync_wait_count==1)
        else $fatal(1,"WVS #2 first edge count failed");
        pulse_on_settle();wait_pc(16'h0202);
        @(negedge clk);pc_enable=1;
        wait(dut.state==dut.STATE_WAIT_VSYNC && debug_pc==16'h0203);
        repeat(4)@(negedge clk);
        assert(debug_pc==16'h0203)else $fatal(1,"WVS #0 prematurely advanced");
        pulse_on_settle();wait_pc(16'h0204);
        repeat(8)@(negedge clk);
        assert(debug_pc==16'h0204 && !write_en)
        else $fatal(1,"HLT after WVS failed");
        $display("PASS: WVS #2/#0 short settle-cycle edges");$finish;
    end
    initial begin #5000;$fatal(1,"WVS test watchdog");end
endmodule
