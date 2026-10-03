`timescale 1ns/1ps
module tb_simple5_sweep;
  GSR GSR(.GSRI(1'b1));
  logic clk=0, rst_n=0, vsync=0;
  always #18.518519 clk=~clk;
  always #1851.8519 vsync=~vsync;
  wire [7:0] dout,din,vdin,vdout;
  wire [7:0] memory_dout;
  bit poison_live_read;
  initial poison_live_read = $test$plusargs("poison_live_read");
  // A fetch must consume the WAIT-edge sample, even if the live RAM bus
  // changes during RECV. This fails when decode still uses the direct bus.
  assign dout = poison_live_read && dut.cur.state == cpu_pkg::FETCH_RECV ?
                ~memory_dout : memory_dout;
  wire [14:0] ada,adb;
  wire cea,ceb,vc;
  wire [9:0] va;
  // Exact bytes from examples/simple5.s; accelerated VSync preserves all
  // CPU instructions, including CVR/IFO/WVS, and checks a complete wrap.
  localparam logic [7:0] boot_program[7680] = '{
    0:8'hA9, 1:8'h20, 2:8'hCF, 3:8'h85, 4:8'h01,
    5:8'h8D, 6:8'h3B, 7:8'hE0, 8:8'hDF, 9:8'h00,
    10:8'h00, 11:8'hFF, 12:8'h12, 13:8'h18, 14:8'h69,
    15:8'h01, 16:8'hC9, 17:8'h7F, 18:8'hD0, 19:8'hEE,
    20:8'hA9, 21:8'h20, 22:8'h4C, 23:8'h02, 24:8'h02,
    default:8'hEA
  };
  localparam logic [15:0] boot_program_length=25;
  cpu dut(.clk(clk),.rst_n(rst_n),.dout(dout),.din(din),.ada(ada),.adb(adb),
    .cea(cea),.ceb(ceb),.v_ada(va),.v_cea(vc),.v_din(vdin),.vsync(vsync),
    .boot_program(boot_program),.boot_program_length(boot_program_length));
  ram #(.USE_VENDOR(1)) mem(.MEMORY_CLK(clk),.PIXEL_CLK(clk),.dout(memory_dout),
    .cea(cea && rst_n),.ceb(ceb),.oce(1'b1),.reseta(!rst_n),.resetb(!rst_n),
    .ada(ada),.adb(adb),.din(din),.v_dout(vdout),.v_cea(vc && rst_n),
    .v_ceb(1'b0),.v_oce(1'b1),.v_reseta(!rst_n),.v_resetb(!rst_n),
    .v_ada(va),.v_adb(10'b0),.v_din(vdin));
  integer samples=0;
  logic [7:0] expected=8'h20;
  always @(posedge clk) if (rst_n && vc && va==59 && dut.cur.pc==16'h0208) begin

    if (vdin !== expected) $fatal(1,"got %02x expected %02x",vdin,expected);
    samples=samples+1;
    expected=expected==8'h7e ? 8'h20 : expected+1;
    if(samples==100) begin $display("PASS simple5 vendor RAM full sweep and wrap"); $finish; end
  end
  initial begin #200; rst_n=1; #50000000; $fatal(1,"timeout pc=%04x",dut.cur.pc); end
endmodule
