// rom.sv
module rom (
    input  logic [15:0] addr,
    output logic [ 7:0] data
);

    always_comb begin
        case (addr)
            16'h0200: data = 8'hA9;  // LDA #$10
            16'h0201: data = 8'h10;
            16'h0202: data = 8'hC9;  // CMP #$10 -> Z=1, C=1
            16'h0203: data = 8'h10;
            16'h0204: data = 8'hD0;  // BNE FAIL (+0D -> $0213)
            16'h0205: data = 8'h0D;
            16'h0206: data = 8'hA9;  // Success path: LDA #$00
            16'h0207: data = 8'h00;
            16'h0208: data = 8'h85;  // STA $10 -> [$10]=0
            16'h0209: data = 8'h10;
            16'h020A: data = 8'hE6;  // INC $10 -> [$10]=1
            16'h020B: data = 8'h10;
            16'h020C: data = 8'hA2;  // LDX #1
            16'h020D: data = 8'h01;
            16'h020E: data = 8'hA0;  // LDY #0
            16'h020F: data = 8'h00;
            16'h0210: data = 8'hCA;  // DEX: X=0, Z=1
            16'h0211: data = 8'h88;  // DEY: Y=$FF, N=1
            16'h0212: data = 8'hEF;  // HLT (Success)
            16'h0213: data = 8'hEF;  // HLT (Fail target)
            default:  data = 8'hEA;  // NOP
        endcase
    end

endmodule
