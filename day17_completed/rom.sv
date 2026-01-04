// rom.sv
module rom (
    input  logic [15:0] addr,
    output logic [ 7:0] data
);

    always_comb begin
        case (addr)
            16'h8000: data = 8'hA9;  // LDA #$20
            16'h8001: data = 8'h20;
            16'h8002: data = 8'h85;  // STA $10
            16'h8003: data = 8'h10;
            16'h8004: data = 8'hA9;  // LDA #$80
            16'h8005: data = 8'h80;
            16'h8006: data = 8'h85;  // STA $11 -> Pointer at $10/$11 is now $8020
            16'h8007: data = 8'h11;
            16'h8008: data = 8'hA0;  // LDY #$01
            16'h8009: data = 8'h01;
            16'h800A:
            data = 8'hB1;  // LDA ($10),Y -> Load from [$10,$11] + Y = $8020 + 1'b1 = $8021
            16'h800B: data = 8'h10;
            16'h800C: data = 8'hEF;  // HLT
            16'h8020: data = 8'h00;  // Unused
            16'h8021: data = 8'h42;  // Target data
            default: data = 8'hEA;  // NOP
        endcase
    end

endmodule
