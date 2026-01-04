// rom.sv
module rom (
    input  logic [15:0] addr,
    output logic [ 7:0] data
);

    always_comb begin
        case (addr)
            16'h0200: data = 8'hA9;  // LDA #$AA
            16'h0201: data = 8'hAA;
            16'h0202: data = 8'h48;  // PHA
            16'h0203: data = 8'h69;  // ADC #$01 -> A=$AB (Testing status logic)
            16'h0204: data = 8'h01;
            16'h0205: data = 8'h68;  // PLA -> A=$AA (Restored)
            16'h0206: data = 8'h20;  // JSR 800A
            16'h0207: data = 8'h0A;
            16'h0208: data = 8'h02;
            16'h0209: data = 8'hEF;  // HLT (End of program)
            16'h020A: data = 8'hE8;  // INX
            16'h020B: data = 8'h60;  // RTS
            default:  data = 8'hEA;  // NOP
        endcase
    end

endmodule
