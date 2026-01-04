// rom.sv
module rom (
    input  logic [15:0] addr,
    output logic [ 7:0] data
);

    always_comb begin
        case (addr)
            16'h0200: data = 8'hA9;  // LDA #$AA
            16'h0201: data = 8'hAA;
            16'h0202: data = 8'h8D;  // STA $0200
            16'h0203: data = 8'h00;
            16'h0204: data = 8'h02;
            16'h0205: data = 8'hA9;  // LDA #$00
            16'h0206: data = 8'h00;
            16'h0207: data = 8'hAD;  // LDA $0200
            16'h0208: data = 8'h00;
            16'h0209: data = 8'h02;
            16'h020A: data = 8'h4C;  // JMP $8000
            16'h020B: data = 8'h00;
            16'h020C: data = 8'h02;
            default:  data = 8'hEA;  // NOP
        endcase
    end

endmodule
