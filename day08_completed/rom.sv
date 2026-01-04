// rom.sv
module rom (
    input  logic [15:0] addr,
    output logic [ 7:0] data
);

    always_comb begin
        case (addr)
            16'h0200: data = 8'h38;  // SEC
            16'h0201: data = 8'hA9;  // LDA #$0A -> A=0xA
            16'h0202: data = 8'h0A;
            16'h0203: data = 8'hE9;  // SBC #$05 -> A=0x5
            16'h0204: data = 8'h05;
            16'h0205: data = 8'h18;  // CLC
            16'h0206: data = 8'hA9;  // LDA #$FF -> A=0xFF
            16'h0207: data = 8'hFF;
            16'h0208: data = 8'h69;  // ADC #$01 -> A=0x00
            16'h0209: data = 8'h01;
            default:  data = 8'hEA;  // NOP
        endcase
    end

endmodule
