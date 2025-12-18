// rom.sv
module rom (
    input  logic [15:0] addr,
    output logic [7:0]  data
);

    always_comb begin
        case (addr)
            16'h8000: data = 8'hA2; // LDX #$00
            16'h8001: data = 8'h00;
            16'h8002: data = 8'hBD; // LDA $800B,X (DATA,X)
            16'h8003: data = 8'h0B;
            16'h8004: data = 8'h80;
            16'h8005: data = 8'hE8; // INX
            16'h8006: data = 8'hE0; // CPX #$03
            16'h8007: data = 8'h03;
            16'h8008: data = 8'hD0; // BNE LOOP (-8 -> 8002)
            16'h8009: data = 8'hF8;
            16'h800A: data = 8'hFF; // HLT
            16'h800B: data = 8'h11; // DATA[0]
            16'h800C: data = 8'h22; // DATA[1]
            16'h800D: data = 8'h33; // DATA[2]
            default:  data = 8'hEA; // NOP
        endcase
    end

endmodule
