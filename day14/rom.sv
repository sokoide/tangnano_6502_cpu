// rom.sv
module rom (
    input  logic [15:0] addr,
    output logic [ 7:0] data
);

    always_comb begin
        case (addr)
            16'h8000: data = 8'hA9;  // LDA #$01
            16'h8001: data = 8'h01;
            16'h8002: data = 8'h0A;  // ASL A -> A=$02, C=0
            16'h8003: data = 8'h0A;  // ASL A -> A=$04, C=0
            16'h8004: data = 8'hA9;  // LDA #$80
            16'h8005: data = 8'h80;
            16'h8006: data = 8'h0A;  // ASL A -> A=$00, C=1, Z=1
            16'h8007: data = 8'h2A;  // ROL A -> A=$01, C=0 (Carry was 1)
            16'h8008: data = 8'h38;  // SEC (Set Carry)
            16'h8009: data = 8'h2A;  // ROL A -> A=$03, C=0
            16'h800A: data = 8'h4A;  // LSR A -> A=$01, C=1
            16'h800B: data = 8'h6A;  // ROR A -> A=$80, C=1 (Carry was 1)
            16'h800C: data = 8'hEF;  // HLT
            default:  data = 8'hEA;  // NOP
        endcase
    end

endmodule
