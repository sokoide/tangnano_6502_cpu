`timescale 1ns/1ps
module tb_font_contract;
  GSR GSR(.GSRI(1'b1));
  logic clk=0;
  always #55.555556 clk=~clk;
  logic [11:0] ad=0;
  wire [7:0] dout;
  logic ce=1, reset=0;
  Gowin_pROM_font font(.dout(dout),.clk(clk),.oce(1'b0),.ce(ce),.reset(reset),.ad(ad));
  logic [7:0] expected[4096];
  int file, value, n=0;
  string line;
  initial begin
    for(int i=0;i<4096;i++) expected[i]=0;
    file=$fopen("data/font.mi","r");
    if(!file) $fatal(1,"Missing font");
    while($fgets(line,file)) if(line.getc(0)!=8'h23) begin
      if($sscanf(line,"%h",value)!=1 || n>=4096) $fatal(1,"Font parse");
      expected[n++]=8'(value);
    end
    $fclose(file);
    if(n!=2048) $fatal(1,"Font length");
    for(int i=0;i<4096;i++) begin
      @(negedge clk); ad=12'(i);
      @(posedge clk); #1;
      if(dout!==expected[i]) $fatal(1,"Font vendor mismatch addr=%0d actual=%h expected=%h",i,dout,expected[i]);
    end
    @(negedge clk); reset=1;
    @(posedge clk); #1; if(dout!==0) $fatal(1,"Font reset");
    @(negedge clk); reset=0; ce=0; ad=12'd1042;
    @(posedge clk); #1; if(dout!==0) $fatal(1,"Font CE hold");
    @(negedge clk); ce=1;
    @(posedge clk); #1; if(dout!==expected[1042]) $fatal(1,"Font preserved");
    $display("PASS all 4096 font MI bytes equal vendor INIT, CE/OCE/reset"); $finish;
  end
  initial begin #1000000; $fatal(1,"Font timeout"); end
endmodule
