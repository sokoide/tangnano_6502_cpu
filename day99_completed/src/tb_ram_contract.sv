`timescale 1ns / 1ps
module tb_ram_contract;
    GSR GSR (.GSRI(1'b1));
    logic mclk = 0, pclk = 0;
    always #12.345679 mclk = ~mclk;
    always #55.555556 pclk = ~pclk;
    logic cea = 0, ceb = 0, oce = 0, reseta = 0, resetb = 0;
    logic vc = 0, vr = 0, vo = 0, vreset = 0;
    logic [14:0] wa = 0, ra = 0;
    logic [9:0] vwa = 0, vra = 0;
    logic [7:0] din = 0, vdin = 0;
    wire [7:0] d[2], vd[2];
    for (genvar i = 0; i < 2; i++) begin : models
        ram #(
            .USE_VENDOR(i != 0)
        ) dut (
            .MEMORY_CLK(mclk),
            .PIXEL_CLK(pclk),
            .dout(d[i]),
            .cea(cea),
            .ceb(ceb),
            .oce(oce),
            .reseta(reseta),
            .resetb(resetb),
            .ada(wa),
            .adb(ra),
            .din(din),
            .v_dout(vd[i]),
            .v_cea(vc),
            .v_ceb(vr),
            .v_oce(vo),
            .v_reseta(reseta),
            .v_resetb(vreset),
            .v_ada(vwa),
            .v_adb(vra),
            .v_din(vdin)
        );
    end
    task check(input bit video, input logic [7:0] expected);
        #1;
        for (int j = 0; j < 2; j++)
            if ((video ? vd[j] : d[j]) !== expected)
                $fatal(
                    1,
                    "RAM model %0d video=%0d got=%h expected=%h",
                    j,
                    video,
                    video ? vd[j] : d[j],
                    expected
                );
    endtask
    initial begin
        @(negedge mclk);
        cea = 1;
        wa = 15'h7fff;
        din = 8'ha5;
        reseta = 1;
        vc = 1;
        vwa = 1023;
        vdin = 8'h69;
        @(negedge mclk);
        cea = 0;
        vc = 0;
        reseta = 0;
        ceb = 1;
        ra = 15'h7fff;
        @(posedge mclk);
        check(0, 8'ha5);
        @(negedge pclk);
        vr  = 1;
        vra = 1023;
        @(posedge pclk);
        check(1, 8'h69);
        @(negedge mclk);
        ceb = 0;
        ra  = 0;
        oce = 1;
        @(posedge mclk);
        check(0, 8'ha5);
        @(negedge pclk);
        vr  = 0;
        vra = 0;
        vo  = 1;
        @(posedge pclk);
        check(1, 8'h69);
        @(negedge mclk);
        resetb = 1;
        @(posedge mclk);
        check(0, 0);
        @(negedge pclk);
        vreset = 1;
        @(posedge pclk);
        check(1, 0);
        @(negedge mclk);
        resetb = 0;
        ceb = 1;
        oce = 0;
        ra = 15'h7fff;
        @(posedge mclk);
        check(0, 8'ha5);
        @(negedge pclk);
        vreset = 0;
        vr = 1;
        vo = 0;
        vra = 1023;
        @(posedge pclk);
        check(1, 8'h69);
        $display("PASS RAM behavioral/vendor CE/OCE/reset/contents/dual-clock contract");
        $finish;
    end
    initial begin
        #10000;
        $fatal(1, "RAM timeout");
    end
endmodule
