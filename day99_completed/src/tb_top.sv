module tb_top;
    // for TB
    GSR GSR (.GSRI(1'b1));

    logic clk;
    logic rst_n;

    // 20ns clock (#10 means 10ns) == 50MHz
    always #10 clk = ~clk;

    logic rst = !rst_n;

    // BSRAM 8KB, address 8192, data width 8
    logic cea, ceb, oce;
    logic [14:0] ada, adb;
    logic [7:0] din;
    logic [7:0] dout;


    Gowin_SDPB dut (
        .dout(dout),  //output [7:0] dout, read data
        .clka(clk),  //input clka
        .cea(cea),  //input cea, write enable
        .reseta(rst),  //input reseta
        .clkb(clk),  //input clkb
        .ceb(ceb),  //input ceb, read enable
        .resetb(rst),  //input resetb
        .oce(oce),  //input oce, if 1, dout is udated at the next clock
        .ada(ada),  //input [12:0] ada, for write
        .din(din),  //input [7:0] din, written data
        .adb(adb)  //input [12:0] adb, for read
    );

    logic [7:0] boot_data[4];
    localparam int unsigned BootDataLength = $bits(boot_data) / $bits(boot_data[0]);

    initial begin
        boot_data[0] = 8'h06;
        boot_data[1] = 8'h07;
        boot_data[2] = 8'h08;
        boot_data[3] = 8'h09;
    end

    initial begin
        int i;
        $display("=== Test Started ===");
        clk = 0;
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_top);

        cea   = 0;
        ceb   = 0;
        oce   = 0;
        ada   = '0;
        adb   = '0;
        din   = '0;

        rst_n = 0;  // active
        @(posedge clk);  // wait for 1 clock cycle
        rst_n = 1;  // release

        // Write boot_data to 0x0200..0x0203.
        for (i = 0; i < BootDataLength; i++) begin
            ada = 15'h0200 + i[14:0];
            din = boot_data[i];
            cea = 1;
            @(posedge clk);
            cea = 0;
            @(posedge clk);
        end

        // 0x06, 7, 8, 9 must be written at 0x0200-0x203
        adb = 15'h0200;
        ceb = 1;  // enable read
        oce = 1;  // enable output

        repeat (1'b1) @(posedge clk);
        repeat (1'b1) @(posedge clk);
        if (dout !== 8'h06) begin
            $display("❌ ERROR: Expected 0x06 at 0x%04x, got %02x", adb, dout);
        end else begin
            $display("✅ PASS: 0x%04x contains %02x", adb, dout);
        end

        check_dout(15'h0200, 8'h06);
        check_dout(15'h0201, 8'h07);
        check_dout(15'h0202, 8'h08);
        check_dout(15'h0203, 8'h09);

        $display("=== Test End ===");
        $finish;
    end

    task check_dout(input [14:0] addr, input [7:0] expected);
        begin
            adb = addr;
            ceb = 1;
            oce = 1;

            @(posedge clk);  // reserve
            @(posedge clk);  // update dout

            if (dout !== expected) begin
                $display("❌ ERROR: Addr 0x%04x expected %02x, got %02x", addr, expected, dout);
            end else begin
                $display("✅ PASS:  Addr 0x%04x = %02x", addr, dout);
            end
        end
    endtask
endmodule
