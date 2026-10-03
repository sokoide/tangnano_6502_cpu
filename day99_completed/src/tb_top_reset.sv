`timescale 1ns/1ps
module tb_top_reset;
  logic xtal=0, button_n=0;
  always #18.518519 xtal=~xtal;
  wire p,m,de;
  wire [4:0] r,b;
  wire [5:0] g;
  top_core dut(.rst_n(button_n),.XTAL_IN(xtal),.LCD_CLK(p),.MEMORY_CLK(m),
    .LCD_DEN(de),.LCD_R(r),.LCD_G(g),.LCD_B(b));
  // Actual RAM input enables must stay inactive throughout either reset.
  always @(posedge m) begin
    if(!dut.memory_rst_n && (dut.ram_inst.cea || dut.ram_inst.v_cea))
      $fatal(1,"Writes while memory reset asserted");
  end
  initial begin
    #100; if(de) $fatal(1,"DE before lock"); button_n=1;
    wait(dut.memory_rst_n && dut.pixel_rst_n);
    repeat(100) @(posedge m);
    dut.clocks.memory_pll.lock_available=0;
    @(posedge xtal); #1;
    if(dut.memory_rst_n || dut.pixel_rst_n || de) $fatal(1,"Lock loss integration reset");
    repeat(10) @(posedge m);
    dut.clocks.memory_pll.lock_available=1;
    wait(dut.memory_rst_n && dut.pixel_rst_n);
    wait(de);
    #1; button_n=0; #1;
    if(de || dut.ram_inst.cea || dut.ram_inst.v_cea) $fatal(1,"Button reset gating");
    $display("PASS top lock loss/relock/reset CPU write gating/DE"); $finish;
  end
  initial begin #2000000; $fatal(1,"Top reset timeout"); end
endmodule
