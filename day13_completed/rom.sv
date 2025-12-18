// rom.sv
module rom (
    input  logic [15:0] addr,
    output logic [7:0]  data
);

    always_comb begin
        case (addr)
            16'h8000: data = 8'hA9; // LDA #$FF
            16'h8001: data = 8'hFF;
            16'h8002: data = 8'h29; // AND #$0F -> A=$0F
            16'h8003: data = 8'h0F;
            16'h8004: data = 8'h09; // ORA #$80 -> A=$8F
            16'h8005: data = 8'h80;
            16'h8006: data = 8'h49; // EOR #$8F -> A=$00
            16'h8007: data = 8'h8F;
            16'h8008: data = 8'h85; // STA $10
            16'h8009: data = 8'h10;
            16'h800A: data = 8'hA9; // LDA #$A5
            16'h800B: data = 8'hA5;
            16'h800C: data = 8'h85; // STA $11
            16'h800D: data = 8'h11;
            16'h800E: data = 8'hA9; // LDA #$0F
            16'h800F: data = 8'h0F;
            16'h8010: data = 8'h24; // BIT $11
            16'h8011: data = 8'h11;
            16'h8012: data = 8'hFF; // HLT
            default:  data = 8'hEA; // NOP
        endcase
    end

endmodule
