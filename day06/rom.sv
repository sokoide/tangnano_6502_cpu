// rom.sv
module rom (
    input  logic [15:0] addr,
    output logic [ 7:0] data
);

    always_comb begin
        case (addr)
            16'h8000: data = 8'hA9;  // LDA #imm
            16'h8001: data = 8'h42;  // literal $42
            default:  data = 8'hEA;  // NOP
        endcase
    end

endmodule
