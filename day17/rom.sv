// rom.sv
module rom (
    input  logic [15:0] addr,
    output logic [ 7:0] data
);

    always_comb begin
        case (addr)
            16'h0200: data = 8'hA9;  // LDA #$20
            16'h0201: data = 8'h20;
            16'h0202: data = 8'h85;  // STA $10
            16'h0203: data = 8'h10;
            16'h0204: data = 8'hA9;  // LDA #$80
            16'h0205: data = 8'h02;
            16'h0206: data = 8'h85;  // STA $11 -> Pointer at $10/$11 is now $8020
            16'h0207: data = 8'h11;
            16'h0208: data = 8'hA0;  // LDY #$01
            16'h0209: data = 8'h01;
            16'h020A: data = 8'hB1;  // LDA ($10),Y -> Load from [$10,$11] + Y = $8020 + 1 = $8021
            16'h020B: data = 8'h10;
            16'h020C: data = 8'hEF;  // HLT
            16'h8020: data = 8'h00;  // Unused
            16'h8021: data = 8'h42;  // Target data
            default:  data = 8'hEA;  // NOP
        endcase
    end

endmodule
