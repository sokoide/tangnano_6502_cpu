// Independent synchronous-memory contract tests for the active CPU.
module tb_cpu_contract;
  import cpu_pkg::*;
  logic clk = 0, rst_n = 0;
  always #5 clk = ~clk;
  logic [7:0] dout, din, v_din;
  logic [14:0] ada, adb;
  logic cea, ceb, v_cea;
  logic [9:0] v_ada;
  logic [7:0] boot_program [7680];
  logic [15:0] boot_program_length;
  logic [7:0] ram [32768], vram [1024];
  int boot_writes, writes, video_writes, counts [1024], pos;
  cpu dut (.clk(clk), .rst_n(rst_n), .dout(dout), .din(din), .ada(ada), .adb(adb),
    .cea(cea), .ceb(ceb), .v_ada(v_ada), .v_cea(v_cea), .v_din(v_din), .vsync(1'b0),
    .boot_program(boot_program), .boot_program_length(boot_program_length));
  always @(posedge clk) begin
    if (rst_n && dut.cur.state == FETCH_RECV && dut.cur.fetch_stage == FETCH_OPERAND2 &&
        (dut.cur.opcode == 8'ha1 || dut.cur.opcode == 8'hb1))
      $fatal(1, "LDA indirect must not fetch a second operand");
    if (ceb) dout <= ram[adb];
    if (rst_n && cea) begin
      ram[ada] <= din;
      if (dut.cur.state == INIT_RAM) begin
        if (ada !== 15'h200 + boot_writes) $fatal(1, "boot address %h count %d", ada, boot_writes);
        boot_writes++;
      end else writes++;
    end
    if (rst_n && v_cea) begin
      if (!cea || ada != 15'h7c00 + v_ada || din != v_din)
        $fatal(1, "shadow/video mismatch");
      vram[v_ada] <= v_din;
      counts[v_ada]++;
      video_writes++;
    end
    if (rst_n && dut.cur.state == FETCH_REQ && dut.cur.fetch_stage == FETCH_OPCODE &&
        boot_writes != boot_program_length) $fatal(1, "fetch before final boot retirement");
  end
  task automatic setup;
    @(negedge clk); rst_n = 0;
    repeat (2) @(negedge clk);
    for (int i=0;i<32768;i++) ram[i]=8'h55;
    for (int i=0;i<1024;i++) begin vram[i]=8'h55; counts[i]=0; end
    for (int i=0;i<7680;i++) boot_program[i]=8'hea;
    boot_writes=0; writes=0; video_writes=0; pos=0;
  endtask
  task automatic emit(input logic [7:0] b); boot_program[pos++]=b; endtask
  task automatic absop(input logic [7:0] op, input logic [15:0] addr);
    emit(op); emit(addr[7:0]); emit(addr[15:8]);
  endtask
  task automatic start(input int length);
    boot_program_length=16'(length);
    @(negedge clk); rst_n=1;
  endtask
  task automatic stop(input cpu_fault_e expected);
    bit done;
    done=0;
    for (int i=0;i<40000;i++) begin
      @(negedge clk);
      if (dut.cur.state == HALT || dut.cur.state == FAULT) begin done=1; break; end
    end
    if (!done) $fatal(1,"timeout PC=%h state=%d",dut.cur.pc,dut.cur.state);
    if (dut.cur.fault_reason != expected) $fatal(1,"fault expected %d got %d PC %h",expected,dut.cur.fault_reason,dut.cur.pc);
    repeat(3) @(negedge clk);
    if(cea || v_cea) $fatal(1,"writes held after stop");
  endtask
  initial begin
    int lengths [5]='{0,1,7679,7680,7681};
    logic [7:0] cmpops [14]='{8'hcd,8'hdd,8'hd9,8'hec,8'hcc,
      8'hc9,8'he0,8'hc0,8'hc5,8'hd5,8'hc1,8'hd1,8'he4,8'hc4};
    for(int n=0;n<5;n++) begin
      setup(); boot_program[0]=8'hef;
      start(lengths[n]); stop((n==0 || n==4)?FAULT_BOOT_LENGTH:FAULT_NONE);
      if(boot_writes != ((n==0 || n==4)?0:lengths[n]) || writes || video_writes)
        $fatal(1,"boot length/count %d/%d",lengths[n],boot_writes);
      if(n>0 && n<4 && ram[15'h200+lengths[n]] != 8'h55) $fatal(1,"extra boot write");
    end
    $display("[PASS] boot 0/1/7679/7680/7681 exact writes and retirement");
    setup(); emit(8'ha9); emit(8'h41);
    absop(8'h8d,16'hdfff); absop(8'h8d,16'he000); absop(8'h8d,16'he3fb);
    absop(8'h8d,16'he3fc); absop(8'h8d,16'he3ff); absop(8'h8d,16'he400);
    emit(8'ha2); emit(8'h42); absop(8'h8e,16'he3fc);
    emit(8'ha0); emit(8'h43); absop(8'h8c,16'he3ff);
    absop(8'hee,16'he000); absop(8'h0e,16'he3ff);
    absop(8'had,16'he3ff); absop(8'h8d,16'h500); emit(8'hef);
    start(pos); stop(FAULT_NONE);
    if(writes != 11 || video_writes != 8 || ram[15'h5fff]!=8'h41 || ram[15'h6400]!=8'h41 ||
       ram[15'h500]!=8'h86 || vram[0]!=8'h42 || vram[1019]!=8'h41 ||
       vram[1020]!=8'h42 || vram[1023]!=8'h86) $fatal(1,"write/decode/read contract %d/%d",writes,video_writes);
    $display("[PASS] STA/STX/STY/INC/ASL VRAM boundary/read/write pulses");
    for(int n=0;n<4;n++) begin
      setup(); emit(8'ha9); emit(8'h99);
      absop(8'h8d, n==0?16'h7c00:n==1?16'h7fff:n==2?16'hfc00:16'hffff);
      emit(8'hef); start(pos); stop(FAULT_SHADOW_WRITE);
      if(writes || video_writes || ram[n%2==0?15'h7c00:15'h7fff]!=8'h55) $fatal(1,"readonly alias");
    end
    setup(); emit(8'hcf); emit(8'hef); start(pos); stop(FAULT_NONE);
    if(video_writes != 1024 || writes != 1024) $fatal(1,"clear count");
    for(int i=0;i<1024;i++) if(counts[i]!=1 || vram[i]!=8'h20 || ram[15'h7c00+i]!=8'h20)
      $fatal(1,"clear index %d",i);
    $display("[PASS] shadow readonly aliases and 1024-cell clear");
    for(int n=0;n<14;n++) for(int carry=0;carry<2;carry++) begin
      setup(); ram[15'h600]=8'h40; ram[15'h10]=8'h40;
      ram[15'h20]=(n==11)?8'hc0:8'h00; ram[15'h21]=(n==11)?8'h05:8'h06;
      emit(8'ha9); emit(8'h46); emit(8'h48); emit(8'h28); // PLP restores V/Z/I, D=0
      emit(8'ha9); emit(8'h40); emit(8'ha2); emit(8'h40); emit(8'ha0); emit(8'h40);
      emit(carry?8'h38:8'h18);
      if(n<5) absop(cmpops[n],(n==1 || n==2)?16'h5c0:16'h600);
      else begin
        emit(cmpops[n]);
        emit(n<8?8'h40:n==9?8'hd0:n==10?8'he0:n==11?8'h20:8'h10);
      end
      emit(8'hef);
      start(pos); stop(FAULT_NONE);
      if(!dut.cur.flg_c || !dut.cur.flg_z || dut.cur.flg_n || !dut.cur.flg_v ||
         !dut.cur.flg_i || dut.cur.flg_d || dut.cur.ra!=8'h40 || dut.cur.rx!=8'h40 ||
         dut.cur.ry!=8'h40 || dut.cur.sp!=8'hff) $fatal(1,"compare/PLP flags %h",cmpops[n]);
    end
    setup(); emit(8'ha9); emit(8'hc7); emit(8'h48); emit(8'h28); emit(8'h08); emit(8'hef);
    start(pos); stop(FAULT_NONE);
    if(!dut.cur.flg_n || !dut.cur.flg_v || !dut.cur.flg_i || !dut.cur.flg_z ||
       !dut.cur.flg_c || dut.cur.flg_d || dut.cur.flg_b || dut.cur.sp!=8'hfe || ram[15'h1ff]!=8'hf7)
      $fatal(1,"PLP/PHP status convention");
    setup(); emit(8'ha9); emit(8'h08); emit(8'h48); emit(8'h28); start(pos); stop(FAULT_DECIMAL);
    setup(); emit(8'hf8); start(pos); stop(FAULT_DECIMAL);
    setup(); emit(8'h00); start(pos); stop(FAULT_OPCODE);
    if(dut.cur.opcode != 0 || dut.cur.pc!=16'h200) $fatal(1,"fault diagnostic");
    setup(); emit(8'hd8); emit(8'hef); start(pos); stop(FAULT_NONE);
    $display("[PASS] 14 compare forms C=0/1 V/source preservation, PLP/SP, CLD/SED/unsupported");
    for(int n=0;n<2;n++) begin
      setup(); absop(8'h4c,n==0?16'h7fff:16'hffff);
      ram[15'h7fff]=8'hea; ram[0]=8'hef;
      start(pos); stop(FAULT_NONE);
      if(dut.cur.pc != (n==0?16'h8000:16'h0000)) $fatal(1,"PC 16-bit wrap %h",dut.cur.pc);
    end
    $display("[PASS] PC 7fff/ffff logical wrap and physical mirror");
    for(int n=0;n<2;n++) begin
      setup(); absop(8'h4c,n==0?16'h7ffe:16'h8000);
      if(n==0) begin ram[15'h7ffe]=8'h90; ram[15'h7fff]=8'h02; ram[2]=8'hef; end
      else begin ram[0]=8'h90; ram[1]=8'hfc; ram[15'h7ffe]=8'hef; end
      start(pos); stop(FAULT_NONE);
      if(dut.cur.pc != (n==0?16'h8002:16'h7ffe)) $fatal(1,"signed branch %h",dut.cur.pc);
    end
    setup(); emit(8'ha2); emit(8'h01); absop(8'hbd,16'hffff); emit(8'hef);
    ram[0]=8'h37; start(pos); stop(FAULT_NONE);
    if(dut.cur.ra!=8'h37) $fatal(1,"effective address wrap");
    $display("[PASS] signed branches and absolute indexed 16bit wrap");
    // Distinct A/X/Y values catch incorrect compare source selection, V starts at zero.
    for(int n=0;n<5;n++) for(int borrow=0;borrow<2;borrow++) begin
      logic [7:0] lhs, a_value, x_value, y_value;
      logic [15:0] addr;
      lhs=borrow?8'h10:8'h50;
      a_value=n<3?lhs:8'h70; x_value=n==3?lhs:8'h08; y_value=n==4?lhs:8'h0c;
      setup(); ram[15'h600]=8'h40;
      emit(8'ha9); emit(a_value); emit(8'ha2); emit(x_value); emit(8'ha0); emit(y_value);
      emit(borrow?8'h38:8'h18);
      addr=n==1?16'h600-x_value:n==2?16'h600-y_value:16'h600;
      absop(cmpops[n],addr); emit(8'hef); start(pos); stop(FAULT_NONE);
      if(dut.cur.flg_c != !borrow || dut.cur.flg_z || dut.cur.flg_n != borrow || dut.cur.flg_v ||
         dut.cur.ra!=a_value || dut.cur.rx!=x_value || dut.cur.ry!=y_value)
        $fatal(1,"unequal absolute compare/source/V0 %h borrow=%d",cmpops[n],borrow);
    end
    // Pointer high-byte must wrap within zero page (FF -> 00), not into stack.
    for(int n=0;n<4;n++) begin
      setup(); ram[15'hff]=n%2?8'hf0:8'h00; ram[0]=n%2?8'h05:8'h06;
      ram[15'h100]=8'h71; ram[15'h600]=8'h44;
      emit(8'ha2); emit(8'h01); emit(8'ha0); emit(8'h10); emit(8'ha9); emit(n<2?8'h33:8'h44);
      emit(n==0?8'ha1:n==1?8'hb1:n==2?8'hc1:8'hd1); emit(n%2?8'hff:8'hfe);
      emit(8'hef); start(pos); stop(FAULT_NONE);
      if(dut.cur.pc!=16'h208 || dut.cur.ra!=8'h44 ||
         (n>=2 && (!dut.cur.flg_c || !dut.cur.flg_z || dut.cur.flg_n)))
        $fatal(1,"zero-page pointer FF/00 and operand length case=%d pc=%h",n,dut.cur.pc);
    end
    $display("[PASS] absolute compares unequal/borrow/distinct sources/V0 and indirect FF->00");
    $display("[PASS] tb_cpu_contract"); $finish;
  end
endmodule
