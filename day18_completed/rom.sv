// rom.sv
module rom (
    input  logic [15:0] addr,
    output logic [ 7:0] data
);

    always_comb begin
        case (addr)
            16'h0200: data = 8'hA9;  // LDA #$01
            16'h0201: data = 8'h01;
            16'h0202: data = 8'h85;  // STA $00
            16'h0203: data = 8'h00;
            16'h0204: data = 8'hA9;  // LDA #$02
            16'h0205: data = 8'h02;
            16'h0206: data = 8'h85;  // STA $01
            16'h0207: data = 8'h01;
            16'h0208: data = 8'hA9;  // LDA #$03
            16'h0209: data = 8'h03;
            16'h020A: data = 8'h85;  // STA $02
            16'h020B: data = 8'h02;

            // Loop Start
            16'h020C: data = 8'h18;  // CLC
            16'h020D: data = 8'h69;  // ADC #$01
            16'h020E: data = 8'h01;
            16'h020F: data = 8'hE8;  // INX
            16'h0210: data = 8'hC8;  // INY
            16'h0211: data = 8'hDF;  // IFO (Info)
            16'h0212: data = 8'hFF;  // WVS #58
            16'h0213: data = 8'h3A;  // 58 in hex (~1 sec)
            16'h0214: data = 8'h4C;  // JMP $020C
            16'h0215: data = 8'h0C;
            16'h0216: data = 8'h02;

            default: data = 8'hEA;  // NOP
        endcase
    end

endmodule
