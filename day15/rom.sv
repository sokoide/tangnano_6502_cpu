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
            16'h0204: data = 8'hD0;  // BNE FAIL (+07 -> 800D)
            16'h0205: data = 8'h07;
            16'h0206: data = 8'hA9;  // Success path: LDA #$00
            16'h0207: data = 8'h00;
            16'h0208: data = 8'h85;  // STA $10 -> [$10]=0
            16'h0209: data = 8'h10;
            16'h020A: data = 8'hE6;  // INC $10 -> [$10]=1
            16'h020B: data = 8'h10;
            16'h020C: data = 8'hEF;  // HLT (Success)
            16'h020D: data = 8'hEF;  // HLT (Fail target)
            default:  data = 8'hEA;  // NOP
        endcase
    end

endmodule
