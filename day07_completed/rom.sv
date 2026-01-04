// rom.sv
module rom (
    input  logic [15:0] addr,
    output logic [ 7:0] data
);

    always_comb begin
        case (addr)
            16'h0200: data = 8'hA9;  // LDA #$40
            16'h0201: data = 8'h40;
            16'h0202: data = 8'hAA;  // TAX
            16'h0203: data = 8'hA8;  // TAY
            16'h0204: data = 8'hE8;  // INX
            16'h0205: data = 8'hC8;  // INY
            16'h0206: data = 8'h8A;  // TXA
            16'h0207: data = 8'h98;  // TYA
            default:  data = 8'hEA;  // NOP
        endcase
    end

endmodule
