// rom.sv
module rom (
    input  logic [15:0] addr,
    output logic [ 7:0] data
);

    always_comb begin
        case (addr)
            16'h8000: data = 8'hA9;  // LDA #$01
            16'h8001: data = 8'h01;
            16'h8002: data = 8'h85;  // STA $00
            16'h8003: data = 8'h00;
            16'h8004: data = 8'hA9;  // LDA #$02
            16'h8005: data = 8'h02;
            16'h8006: data = 8'h85;  // STA $01
            16'h8007: data = 8'h01;
            16'h8008: data = 8'hA9;  // LDA #$03
            16'h8009: data = 8'h03;
            16'h800A: data = 8'h85;  // STA $02
            16'h800B: data = 8'h02;

            // Loop Start
            16'h800C: data = 8'h18;  // CLC
            16'h800D: data = 8'h69;  // ADC #$01
            16'h800E: data = 8'h01;
            16'h800F: data = 8'hE8;  // INX
            16'h8010: data = 8'hC8;  // INY
            16'h8011: data = 8'hDF;  // IFO (Info)
            16'h8012: data = 8'hFF;  // WVS #58
            16'h8013: data = 8'h3A;  // 58 in hex (~1 sec)
            16'h8014: data = 8'h4C;  // JMP $800C
            16'h8015: data = 8'h0C;
            16'h8016: data = 8'h80;

            default: data = 8'hEA;  // NOP
        endcase
    end

endmodule
