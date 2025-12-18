// rom.sv
module rom (
    input  logic [15:0] addr,
    output logic [7:0]  data
);

    always_comb begin
        case (addr)
            16'h8000: data = 8'hA9; // LDA #$42
            16'h8001: data = 8'h42;
            16'h8002: data = 8'h85; // STA $10
            16'h8003: data = 8'h10;
            16'h8004: data = 8'hA9; // LDA #$00
            16'h8005: data = 8'h00;
            16'h8006: data = 8'hA5; // LDA $10
            16'h8007: data = 8'h10;
            16'h8008: data = 8'hEF; // HLT (End of program)
            16'h8009: data = 8'hEF; // Padding (HLT)
            default:  data = 8'hEA; // NOP
        endcase
    end

endmodule
