// rom.sv
module rom (
    input  logic [15:0] addr,
    output logic [ 7:0] data
);

    always_comb begin
        case (addr)
            16'h8000: data = 8'hA9;  // LDA #$00 -> A=0
            16'h8001: data = 8'h00;
            16'h8002: data = 8'hF0;  // BEQ $02 (Jump to 8006)
            16'h8003: data = 8'h02;
            16'h8004: data = 8'hA9;  // LDA #$FF -> A=0xFF (Should be skipped)
            16'h8005: data = 8'hFF;
            16'h8006: data = 8'hE8;  // INX -> X=1
            default:  data = 8'hEA;  // NOP
        endcase
    end

endmodule
