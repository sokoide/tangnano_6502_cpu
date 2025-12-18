// rom.sv
module rom (
    input  logic [15:0] addr,
    output logic [7:0]  data
);

    always_comb begin
        case (addr)
            16'h8000: data = 8'h18; // CLC
            16'h8001: data = 8'h69; // ADC #$01
            16'h8002: data = 8'h01;
            16'h8003: data = 8'hE8; // INX
            16'h8004: data = 8'hC8; // INY
            16'h8005: data = 8'h32; // IFO (Show Info)
            16'h8006: data = 8'h12; // WVS (Wait for V-Sync)
            16'h8007: data = 8'h4C; // JMP $8000
            16'h8008: data = 8'h00;
            16'h8009: data = 8'h80;

            default:  data = 8'hEA; // NOP
        endcase
    end

endmodule
