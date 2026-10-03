// Real synchronous RAM, manual stepping, and write retirement regression.
`timescale 1ns/1ps
module tb_curriculum_sync #(parameter int STEP_PERIOD=1);
    logic clk=0, rst_n=0, pc_enable=0;
    logic [15:0] address_bus, debug_pc;
    logic [7:0] data_in,data_out,debug_a,debug_x,debug_y,debug_p,debug_s;
    logic write_en;
`ifdef DAY18_CPU
    logic vram_clear,show_info;
`endif
    cpu dut(.clk(clk),.rst_n(rst_n),.pc_enable(pc_enable),
        .address_bus(address_bus),.data_in(data_in),.data_out(data_out),.write_en(write_en),
        .debug_pc(debug_pc),.debug_a(debug_a),.debug_x(debug_x),.debug_y(debug_y),
        .debug_p(debug_p),.debug_s(debug_s)
`ifdef DAY18_CPU
        ,.memory_hold(1'b0),.vsync(1'b0),.vram_clear(vram_clear),.show_info(show_info)
`endif
    );
    logic [7:0] ram_dout;
    ram u_ram(.clk(clk),.addr(address_bus[14:0]),.write_en(write_en),.din(data_out),.dout(ram_dout));
`ifdef DAY18_CPU
    // The CPU must decode from its settle-edge sample (dut.data_r), never the
    // live RAM bus. With +poison_live_read the bus is inverted on decode edges
    // (day99 tb_simple5_sweep technique); designs that decode data_in directly
    // fail this run.
    bit poison_live_read;
    initial poison_live_read = $test$plusargs("poison_live_read");
    wire decode_edge = rst_n && dut.memory_ready && (dut.pc_enable || dut.step_pending);
    assign data_in = poison_live_read && decode_edge ? ~ram_dout : ram_dout;
`else
    assign data_in = ram_dout;
`endif
    always #5 clk=~clk;
    int ticks=0,writes=0,pause_left=0;
    bit paused=0;
    logic [15:0] paused_pc;
    always @(negedge clk) if(rst_n) begin
        ticks++;
        if(write_en && !paused) begin
            pause_left=12; paused=1; paused_pc=debug_pc;
        end
        if(pause_left>0) begin pc_enable=0;pause_left--;end
        else pc_enable=(ticks%STEP_PERIOD==0);
    end
    always @(posedge clk) begin
        if(rst_n && write_en) begin
            case(writes)
                0: assert(address_bus==16'h01ff && data_out==8'h42)
                   else $fatal(1,"PHA write mismatch");
                1: assert(address_bus==16'h01ff && data_out==8'h02)
                   else $fatal(1,"JSR high mismatch");
                2: assert(address_bus==16'h01fe && data_out==8'h08)
                   else $fatal(1,"JSR low mismatch");
                default: $fatal(1,"Repeated/unexpected write %0d",writes);
            endcase
            writes++;
        end
        #1;
        if(paused && pause_left>0) begin
            assert(!write_en && debug_pc==paused_pc)
            else $fatal(1,"CPU or write progressed while paused");
        end
    end
    bit completed=0;
    initial begin : test_main
        for(int i=0;i<32768;i++) u_ram.mem[i]=8'hea;
        // LDA #42 / PHA / LDA #00 / PLA / JSR 0210 / HLT.
        u_ram.mem['h200]='ha9;u_ram.mem['h201]='h42;u_ram.mem['h202]='h48;
        u_ram.mem['h203]='ha9;u_ram.mem['h204]=0;u_ram.mem['h205]='h68;
        u_ram.mem['h206]='h20;u_ram.mem['h207]='h10;u_ram.mem['h208]='h02;
        u_ram.mem['h209]='hef;u_ram.mem['h210]='ha9;u_ram.mem['h211]='h7f;
        u_ram.mem['h212]='h60;
        repeat(3) @(negedge clk);rst_n=1;
        for(int i=0;i<2000;i++) begin
            @(posedge clk);#2;
            if(debug_pc==16'h0209 && debug_s==8'hff && debug_a==8'h7f) begin
                repeat(4) begin @(posedge clk);#2;end
                assert(debug_pc==16'h0209 && writes==3 && paused)
                else $fatal(1,"HLT or write count failed");
                $display("PASS: sync RAM STEP_PERIOD=%0d writes=%0d",STEP_PERIOD,writes);completed=1;break;
            end
        end
        if(!completed) $fatal(1,"Sync CPU timeout PC=%h A=%h S=%h",debug_pc,debug_a,debug_s);
        $finish;
    end
    initial begin #25000;$fatal(1,"Global sync CPU timeout");end
endmodule
