// rom.sv
module rom (
    input  logic [15:0] addr,
    output logic [ 7:0] data
);

    always_comb begin
        case (addr)
            16'h0200: data = 8'hA9;  // LDA #$FF
            16'h0201: data = 8'hEF;
            16'h0202: data = 8'h29;  // AND #$0F -> A=$0F
            16'h0203: data = 8'h0F;
            16'h0204: data = 8'h09;  // ORA #$80 -> A=$8F
            16'h0205: data = 8'h02;
            16'h0206: data = 8'h49;  // EOR #$8F -> A=$00
            16'h0207: data = 8'h8F;
            16'h0208: data = 8'h85;  // STA $10
            16'h0209: data = 8'h10;
            16'h020A: data = 8'hA9;  // LDA #$A5
            16'h020B: data = 8'hA5;
            16'h020C: data = 8'h85;  // STA $11
            16'h020D: data = 8'h11;
            16'h020E: data = 8'hA9;  // LDA #$0F
            16'h020F: data = 8'h0F;
            16'h0210: data = 8'h24;  // BIT $11
            16'h0211: data = 8'h11;
            16'h0212: data = 8'hEF;  // HLT
            default:  data = 8'hEA;  // NOP
        endcase
    end

endmodule
