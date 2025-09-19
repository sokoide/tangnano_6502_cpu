// Test ROM with comprehensive 6502 test program
// Contains various instruction tests and demonstrations

module test_rom #(
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

    // Initialize ROM with comprehensive 6502 test program
    initial begin
        // Initialize all ROM to NOP (0xEA)
        for (int i = 0; i < (1<<ADDR_WIDTH); i++) begin
            rom_array[i] = 8'hEA;  // NOP
        end

        // Main test program starting at $C000
        // Test 1: Basic load and store operations
        rom_array[16'h0000] = 8'hA9;  // LDA #$42
        rom_array[16'h0001] = 8'h42;
        rom_array[16'h0002] = 8'h85;  // STA $80
        rom_array[16'h0003] = 8'h80;
        rom_array[16'h0004] = 8'hA9;  // LDA #$84
        rom_array[16'h0005] = 8'h84;
        rom_array[16'h0006] = 8'h85;  // STA $81
        rom_array[16'h0007] = 8'h81;

        // Test 2: Arithmetic operations
        rom_array[16'h0008] = 8'hA5;  // LDA $80    ($42)
        rom_array[16'h0009] = 8'h80;
        rom_array[16'h000A] = 8'h18;  // CLC
        rom_array[16'h000B] = 8'h65;  // ADC $81    ($42 + $84 = $C6)
        rom_array[16'h000C] = 8'h81;
        rom_array[16'h000D] = 8'h85;  // STA $82
        rom_array[16'h000E] = 8'h82;

        // Test 3: Register transfers
        rom_array[16'h000F] = 8'hAA;  // TAX
        rom_array[16'h0010] = 8'hA8;  // TAY
        rom_array[16'h0011] = 8'h8A;  // TXA
        rom_array[16'h0012] = 8'h98;  // TYA

        // Test 4: Logical operations
        rom_array[16'h0013] = 8'hA9;  // LDA #$F0
        rom_array[16'h0014] = 8'hF0;
        rom_array[16'h0015] = 8'h29;  // AND #$0F
        rom_array[16'h0016] = 8'h0F;
        rom_array[16'h0017] = 8'h09;  // ORA #$55
        rom_array[16'h0018] = 8'h55;
        rom_array[16'h0019] = 8'h49;  // EOR #$AA
        rom_array[16'h001A] = 8'hAA;

        // Test 5: Shift operations
        rom_array[16'h001B] = 8'hA9;  // LDA #$81
        rom_array[16'h001C] = 8'h81;
        rom_array[16'h001D] = 8'h0A;  // ASL A
        rom_array[16'h001E] = 8'h4A;  // LSR A

        // Test 6: Compare operations
        rom_array[16'h001F] = 8'hA9;  // LDA #$42
        rom_array[16'h0020] = 8'h42;
        rom_array[16'h0021] = 8'hC9;  // CMP #$42 (should set zero flag)
        rom_array[16'h0022] = 8'h42;
        rom_array[16'h0023] = 8'hC9;  // CMP #$41 (should set carry flag)
        rom_array[16'h0024] = 8'h41;

        // Test 7: Load X and Y registers
        rom_array[16'h0025] = 8'hA2;  // LDX #$33
        rom_array[16'h0026] = 8'h33;
        rom_array[16'h0027] = 8'hA0;  // LDY #$44
        rom_array[16'h0028] = 8'h44;

        // Test 8: Stack operations
        rom_array[16'h0029] = 8'hA9;  // LDA #$55
        rom_array[16'h002A] = 8'h55;
        rom_array[16'h002B] = 8'h48;  // PHA
        rom_array[16'h002C] = 8'hA9;  // LDA #$66
        rom_array[16'h002D] = 8'h66;
        rom_array[16'h002E] = 8'h48;  // PHA
        rom_array[16'h002F] = 8'h68;  // PLA (should get $66)
        rom_array[16'h0030] = 8'h85;  // STA $90
        rom_array[16'h0031] = 8'h90;
        rom_array[16'h0032] = 8'h68;  // PLA (should get $55)
        rom_array[16'h0033] = 8'h85;  // STA $91
        rom_array[16'h0034] = 8'h91;

        // Test 9: Flag operations
        rom_array[16'h0035] = 8'h38;  // SEC (set carry)
        rom_array[16'h0036] = 8'h18;  // CLC (clear carry)

        // Test 10: Subtraction with borrow
        rom_array[16'h0037] = 8'hA9;  // LDA #$50
        rom_array[16'h0038] = 8'h50;
        rom_array[16'h0039] = 8'h38;  // SEC (no borrow)
        rom_array[16'h003A] = 8'hE9;  // SBC #$30
        rom_array[16'h003B] = 8'h30;
        rom_array[16'h003C] = 8'h85;  // STA $92 (should be $20)
        rom_array[16'h003D] = 8'h92;

        // Test 11: Absolute addressing
        rom_array[16'h003E] = 8'hAD;  // LDA $0280 (absolute)
        rom_array[16'h003F] = 8'h80;
        rom_array[16'h0040] = 8'h02;
        rom_array[16'h0041] = 8'h8D;  // STA $0290 (absolute)
        rom_array[16'h0042] = 8'h90;
        rom_array[16'h0043] = 8'h02;

        // Test 12: Simple loop with increment
        rom_array[16'h0044] = 8'hA9;  // LDA #$00
        rom_array[16'h0045] = 8'h00;
        rom_array[16'h0046] = 8'h85;  // STA $A0 (loop counter)
        rom_array[16'h0047] = 8'hA0;
        // Loop start at $C048
        rom_array[16'h0048] = 8'hA5;  // LDA $A0
        rom_array[16'h0049] = 8'hA0;
        rom_array[16'h004A] = 8'h18;  // CLC
        rom_array[16'h004B] = 8'h69;  // ADC #$01
        rom_array[16'h004C] = 8'h01;
        rom_array[16'h004D] = 8'h85;  // STA $A0
        rom_array[16'h004E] = 8'hA0;
        rom_array[16'h004F] = 8'hC9;  // CMP #$10 (compare with 16)
        rom_array[16'h0050] = 8'h10;
        rom_array[16'h0051] = 8'h30;  // BMI $C048 (branch if less)
        rom_array[16'h0052] = 8'hF5;  // Relative: $C048 - $C053 = -11 = $F5

        // Test 13: Jump to subroutine
        rom_array[16'h0053] = 8'h20;  // JSR $C080
        rom_array[16'h0054] = 8'h80;
        rom_array[16'h0055] = 8'hC0;

        // Test 14: Final infinite loop
        rom_array[16'h0056] = 8'h4C;  // JMP $C056 (infinite loop)
        rom_array[16'h0057] = 8'h56;
        rom_array[16'h0058] = 8'hC0;

        // Subroutine at $C080
        rom_array[16'h0080] = 8'hA9;  // LDA #$AA
        rom_array[16'h0081] = 8'hAA;
        rom_array[16'h0082] = 8'h85;  // STA $B0
        rom_array[16'h0083] = 8'hB0;
        rom_array[16'h0084] = 8'h60;  // RTS

        // I/O test routine at $C100
        rom_array[16'h0100] = 8'hAD;  // LDA $8000 (read switches)
        rom_array[16'h0101] = 8'h00;
        rom_array[16'h0102] = 8'h80;
        rom_array[16'h0103] = 8'h85;  // STA $C0 (store switch value)
        rom_array[16'h0104] = 8'hC0;
        rom_array[16'h0105] = 8'h4C;  // JMP $C100 (loop)
        rom_array[16'h0106] = 8'h00;
        rom_array[16'h0107] = 8'hC1;

        // Memory test routine at $C200
        rom_array[16'h0200] = 8'hA0;  // LDY #$00 (index)
        rom_array[16'h0201] = 8'h00;
        rom_array[16'h0202] = 8'hA9;  // LDA #$AA (test pattern)
        rom_array[16'h0203] = 8'hAA;
        // Memory fill loop
        rom_array[16'h0204] = 8'h99;  // STA $0300,Y (absolute indexed)
        rom_array[16'h0205] = 8'h00;
        rom_array[16'h0206] = 8'h03;
        rom_array[16'h0207] = 8'hC8;  // INY
        rom_array[16'h0208] = 8'hD0;  // BNE $C204 (loop until Y=0)
        rom_array[16'h0209] = 8'hFA;  // Relative: $C204 - $C20A = -6 = $FA
        rom_array[16'h020A] = 8'h60;  // RTS

        // Reset and interrupt vectors at top of ROM
        // $FFFA-$FFFF maps to $3FFA-$3FFF in ROM
        rom_array[16'h3FFA] = 8'h00;  // NMI vector low
        rom_array[16'h3FFB] = 8'hF0;  // NMI vector high ($F000)
        rom_array[16'h3FFC] = 8'h00;  // RESET vector low
        rom_array[16'h3FFD] = 8'hC0;  // RESET vector high ($C000)
        rom_array[16'h3FFE] = 8'h00;  // IRQ vector low
        rom_array[16'h3FFF] = 8'hF8;  // IRQ vector high ($F800)

        // Interrupt handlers
        // NMI handler at $F000
        rom_array[16'h3000] = 8'h40;  // RTI

        // IRQ handler at $F800
        rom_array[16'h3800] = 8'h40;  // RTI
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