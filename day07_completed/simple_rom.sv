// Simple ROM Module for 6502 System
// Contains boot code and interrupt vectors

module simple_rom #(
    parameter ADDR_WIDTH = 14,  // 16KB ROM
    parameter DATA_WIDTH = 8
) (
    input  logic                    clk,
    input  logic                    rst_n,

    // Memory interface
    input  logic [ADDR_WIDTH-1:0]  addr,
    output logic [DATA_WIDTH-1:0]  data_out,
    input  logic                    oe,      // Output enable
    input  logic                    cs       // Chip select
);

    // ROM array
    logic [DATA_WIDTH-1:0] rom_array [0:(1<<ADDR_WIDTH)-1];

    // Initialize ROM with basic 6502 program
    initial begin
        // Initialize all ROM to NOP (0xEA)
        for (int i = 0; i < (1<<ADDR_WIDTH); i++) begin
            rom_array[i] = 8'hEA;  // NOP
        end

        // Simple test program starting at $C000
        rom_array[16'h0000] = 8'hA9;  // LDA #$55
        rom_array[16'h0001] = 8'h55;
        rom_array[16'h0002] = 8'h85;  // STA $80
        rom_array[16'h0003] = 8'h80;
        rom_array[16'h0004] = 8'hA9;  // LDA #$AA
        rom_array[16'h0005] = 8'hAA;
        rom_array[16'h0006] = 8'h85;  // STA $81
        rom_array[16'h0007] = 8'h81;
        rom_array[16'h0008] = 8'hA5;  // LDA $80
        rom_array[16'h0009] = 8'h80;
        rom_array[16'h000A] = 8'h65;  // ADC $81
        rom_array[16'h000B] = 8'h81;
        rom_array[16'h000C] = 8'h85;  // STA $82
        rom_array[16'h000D] = 8'h82;
        rom_array[16'h000E] = 8'h4C;  // JMP $C000 (infinite loop)
        rom_array[16'h000F] = 8'h00;
        rom_array[16'h0010] = 8'hC0;

        // Stack manipulation example at $C020
        rom_array[16'h0020] = 8'hA9;  // LDA #$42
        rom_array[16'h0021] = 8'h42;
        rom_array[16'h0022] = 8'h48;  // PHA
        rom_array[16'h0023] = 8'hA9;  // LDA #$84
        rom_array[16'h0024] = 8'h84;
        rom_array[16'h0025] = 8'h48;  // PHA
        rom_array[16'h0026] = 8'h68;  // PLA
        rom_array[16'h0027] = 8'h85;  // STA $90
        rom_array[16'h0028] = 8'h90;
        rom_array[16'h0029] = 8'h68;  // PLA
        rom_array[16'h002A] = 8'h85;  // STA $91
        rom_array[16'h002B] = 8'h91;

        // Interrupt vectors at top of ROM ($3FFA-$3FFF maps to $FFFA-$FFFF)
        rom_array[16'h3FFA] = 8'h00;  // NMI vector low
        rom_array[16'h3FFB] = 8'hF0;  // NMI vector high ($F000)
        rom_array[16'h3FFC] = 8'h00;  // RESET vector low
        rom_array[16'h3FFD] = 8'hC0;  // RESET vector high ($C000)
        rom_array[16'h3FFE] = 8'h00;  // IRQ vector low
        rom_array[16'h3FFF] = 8'hF8;  // IRQ vector high ($F800)
    end

    // Read operation
    always_comb begin
        if (cs && oe) begin
            data_out = rom_array[addr];
        end else begin
            data_out = 8'hZZ;  // High impedance when not selected
        end
    end

endmodule