// rom.sv
module rom (
    input  logic [15:0] addr,
    output logic [7:0]  data
);

    always_comb begin
        case (addr)
            16'h8000: data = 8'hA9; // LDA #$AA
            16'h8001: data = 8'hAA;
            16'h8002: data = 8'h8D; // STA $0200
            16'h8003: data = 8'h00;
            16'h8004: data = 8'h02;
            16'h8005: data = 8'hA9; // LDA #$00
            16'h8006: data = 8'h00;
            16'h8007: data = 8'hAD; // LDA $0200
            16'h8008: data = 8'h00;
            16'h8009: data = 8'h02;
            16'h800A: data = 8'h4C; // JMP $8000
            16'h800B: data = 8'h00;
            16'h800C: data = 8'h80;
            default:  data = 8'hEA; // NOP
        endcase
    end

endmodule
