// rom.sv
module rom (
    input  logic [15:0] addr,
    output logic [7:0]  data
);

    always_comb begin
        case (addr)
            16'h8000: data = 8'hA9; // LDA #$10
            16'h8001: data = 8'h10;
            16'h8002: data = 8'hC9; // CMP #$10 -> Z=1, C=1
            16'h8003: data = 8'h10;
            16'h8004: data = 8'hD0; // BNE FAIL (+07 -> 800D)
            16'h8005: data = 8'h07;
            16'h8006: data = 8'hA9; // Success path: LDA #$00
            16'h8007: data = 8'h00;
            16'h8008: data = 8'h85; // STA $10 -> [$10]=0
            16'h8009: data = 8'h10;
            16'h800A: data = 8'hE6; // INC $10 -> [$10]=1
            16'h800B: data = 8'h10;
            16'h800C: data = 8'hFF; // HLT (Success)
            16'h800D: data = 8'hFF; // HLT (Fail target)
            default:  data = 8'hEA; // NOP
        endcase
    end

endmodule
