// rom.sv
module rom (
    input  logic [15:0] addr,
    output logic [ 7:0] data
);

    always_comb begin
        case (addr)
            16'h0200: data = 8'hA2;  // LDX #$00
            16'h0201: data = 8'h00;
            16'h0202: data = 8'hBD;  // LDA $800B,X (DATA,X)
            16'h0203: data = 8'h0B;
            16'h0204: data = 8'h02;
            16'h0205: data = 8'hE8;  // INX
            16'h0206: data = 8'hE0;  // CPX #$03
            16'h0207: data = 8'h03;
            16'h0208: data = 8'hD0;  // BNE LOOP (-8 -> 8002)
            16'h0209: data = 8'hF8;
            16'h020A: data = 8'hEF;  // HLT
            16'h020B: data = 8'h11;  // DATA[0]
            16'h020C: data = 8'h22;  // DATA[1]
            16'h020D: data = 8'h33;  // DATA[2]
            default:  data = 8'hEA;  // NOP
        endcase
    end

endmodule
