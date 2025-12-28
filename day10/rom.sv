// rom.sv
module rom (
    input  logic [15:0] addr,
    output logic [ 7:0] data
);

    always_comb begin
        case (addr)
            16'h8000: data = 8'hA9;  // LDA #$AA
            16'h8001: data = 8'hAA;
            16'h8002: data = 8'h48;  // PHA
            16'h8003: data = 8'h69;  // ADC #$01 -> A=$AB (Testing status logic)
            16'h8004: data = 8'h01;
            16'h8005: data = 8'h68;  // PLA -> A=$AA (Restored)
            16'h8006: data = 8'h20;  // JSR 800A
            16'h8007: data = 8'h0A;
            16'h8008: data = 8'h80;
            16'h8009: data = 8'hEF;  // HLT (End of program)
            16'h800A: data = 8'hE8;  // INX
            16'h800B: data = 8'h60;  // RTS
            default:  data = 8'hEA;  // NOP
        endcase
    end

endmodule
