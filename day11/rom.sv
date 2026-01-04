// rom.sv
module rom (
    input  logic [15:0] addr,
    output logic [ 7:0] data
);

    always_comb begin
        case (addr)
            16'h0200: data = 8'hA9;  // LDA #$42
            16'h0201: data = 8'h42;
            16'h0202: data = 8'h85;  // STA $10
            16'h0203: data = 8'h10;
            16'h0204: data = 8'hA9;  // LDA #$00
            16'h0205: data = 8'h00;
            16'h0206: data = 8'hA5;  // LDA $10
            16'h0207: data = 8'h10;
            16'h0208: data = 8'hEF;  // HLT (End of program)
            16'h0209: data = 8'hEF;  // Padding (HLT)
            default:  data = 8'hEA;  // NOP
        endcase
    end

endmodule
