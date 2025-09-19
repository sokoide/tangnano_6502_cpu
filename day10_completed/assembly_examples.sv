// Assembly Programming Examples ROM
// Contains various 6502 assembly programs for educational purposes

module assembly_examples #(
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

    // Initialize ROM with assembly programming examples
    initial begin
        // Initialize all ROM to NOP (0xEA)
        for (int i = 0; i < (1<<ADDR_WIDTH); i++) begin
            rom_array[i] = 8'hEA;  // NOP
        end

        // ===================================================
        // EXAMPLE 1: Basic Arithmetic ($C000)
        // Demonstrates: LDA, ADC, STA, basic math
        // ===================================================
        rom_array[16'h0000] = 8'h18;  // CLC            ; Clear carry
        rom_array[16'h0001] = 8'hA9;  // LDA #10        ; Load 10 into A
        rom_array[16'h0002] = 8'h0A;
        rom_array[16'h0003] = 8'h69;  // ADC #5         ; Add 5 to A
        rom_array[16'h0004] = 8'h05;
        rom_array[16'h0005] = 8'h85;  // STA $80        ; Store result (15) at $80
        rom_array[16'h0006] = 8'h80;
        rom_array[16'h0007] = 8'h69;  // ADC #20        ; Add 20 to A
        rom_array[16'h0008] = 8'h14;
        rom_array[16'h0009] = 8'h85;  // STA $81        ; Store result (35) at $81
        rom_array[16'h000A] = 8'h81;
        rom_array[16'h000B] = 8'h4C;  // JMP $C020      ; Jump to next example
        rom_array[16'h000C] = 8'h20;
        rom_array[16'h000D] = 8'hC0;

        // ===================================================
        // EXAMPLE 2: Loop with Counter ($C020)
        // Demonstrates: Loop control, comparison, branching
        // ===================================================
        rom_array[16'h0020] = 8'hA9;  // LDA #0         ; Initialize counter
        rom_array[16'h0021] = 8'h00;
        rom_array[16'h0022] = 8'h85;  // STA $90        ; Store counter at $90
        rom_array[16'h0023] = 8'h90;
        // Loop start
        rom_array[16'h0024] = 8'hA5;  // LDA $90        ; Load counter
        rom_array[16'h0025] = 8'h90;
        rom_array[16'h0026] = 8'h18;  // CLC            ; Clear carry
        rom_array[16'h0027] = 8'h69;  // ADC #1         ; Increment counter
        rom_array[16'h0028] = 8'h01;
        rom_array[16'h0029] = 8'h85;  // STA $90        ; Store new counter
        rom_array[16'h002A] = 8'h90;
        rom_array[16'h002B] = 8'hC9;  // CMP #10        ; Compare with 10
        rom_array[16'h002C] = 8'h0A;
        rom_array[16'h002D] = 8'h30;  // BMI $C024      ; Branch if less than 10
        rom_array[16'h002E] = 8'hF5;  // (relative: -11)
        rom_array[16'h002F] = 8'h4C;  // JMP $C040      ; Jump to next example
        rom_array[16'h0030] = 8'h40;
        rom_array[16'h0031] = 8'hC0;

        // ===================================================
        // EXAMPLE 3: Data Manipulation ($C040)
        // Demonstrates: Bit operations, shifts, logical ops
        // ===================================================
        rom_array[16'h0040] = 8'hA9;  // LDA #$AA       ; Load bit pattern
        rom_array[16'h0041] = 8'hAA;
        rom_array[16'h0042] = 8'h29;  // AND #$F0       ; Mask upper nibble
        rom_array[16'h0043] = 8'hF0;
        rom_array[16'h0044] = 8'h85;  // STA $A0        ; Store masked value
        rom_array[16'h0045] = 8'hA0;
        rom_array[16'h0046] = 8'hA9;  // LDA #$55       ; Load different pattern
        rom_array[16'h0047] = 8'h55;
        rom_array[16'h0048] = 8'h29;  // AND #$0F       ; Mask lower nibble
        rom_array[16'h0049] = 8'h0F;
        rom_array[16'h004A] = 8'h05;  // ORA $A0        ; Combine with stored value
        rom_array[16'h004B] = 8'hA0;
        rom_array[16'h004C] = 8'h85;  // STA $A1        ; Store combined result
        rom_array[16'h004D] = 8'hA1;
        rom_array[16'h004E] = 8'h0A;  // ASL A          ; Shift left
        rom_array[16'h004F] = 8'h85;  // STA $A2        ; Store shifted result
        rom_array[16'h0050] = 8'hA2;
        rom_array[16'h0051] = 8'h4C;  // JMP $C060      ; Jump to next example
        rom_array[16'h0052] = 8'h60;
        rom_array[16'h0053] = 8'hC0;

        // ===================================================
        // EXAMPLE 4: Subroutine with Stack ($C060)
        // Demonstrates: JSR, RTS, stack operations
        // ===================================================
        rom_array[16'h0060] = 8'hA9;  // LDA #$42       ; Load test value
        rom_array[16'h0061] = 8'h42;
        rom_array[16'h0062] = 8'h20;  // JSR $C0A0      ; Call subroutine
        rom_array[16'h0063] = 8'hA0;
        rom_array[16'h0064] = 8'hC0;
        rom_array[16'h0065] = 8'h85;  // STA $B0        ; Store returned value
        rom_array[16'h0066] = 8'hB0;
        rom_array[16'h0067] = 8'hA9;  // LDA #$84       ; Load another value
        rom_array[16'h0068] = 8'h84;
        rom_array[16'h0069] = 8'h20;  // JSR $C0A0      ; Call subroutine again
        rom_array[16'h006A] = 8'hA0;
        rom_array[16'h006B] = 8'hC0;
        rom_array[16'h006C] = 8'h85;  // STA $B1        ; Store returned value
        rom_array[16'h006D] = 8'hB1;
        rom_array[16'h006E] = 8'h4C;  // JMP $C080      ; Jump to next example
        rom_array[16'h006F] = 8'h80;
        rom_array[16'h0070] = 8'hC0;

        // ===================================================
        // EXAMPLE 5: Array Processing ($C080)
        // Demonstrates: Indexed addressing, array operations
        // ===================================================
        rom_array[16'h0080] = 8'hA0;  // LDY #0         ; Initialize index
        rom_array[16'h0081] = 8'h00;
        rom_array[16'h0082] = 8'hA9;  // LDA #$10       ; Load base value
        rom_array[16'h0083] = 8'h10;
        // Array fill loop
        rom_array[16'h0084] = 8'h99;  // STA $0300,Y    ; Store A at array[Y]
        rom_array[16'h0085] = 8'h00;
        rom_array[16'h0086] = 8'h03;
        rom_array[16'h0087] = 8'h18;  // CLC            ; Clear carry
        rom_array[16'h0088] = 8'h69;  // ADC #1         ; Increment value
        rom_array[16'h0089] = 8'h01;
        rom_array[16'h008A] = 8'hC8;  // INY            ; Increment index
        rom_array[16'h008B] = 8'hC0;  // CPY #8         ; Compare index with 8
        rom_array[16'h008C] = 8'h08;
        rom_array[16'h008D] = 8'h30;  // BMI $C084      ; Branch if Y < 8
        rom_array[16'h008E] = 8'hF5;  // (relative: -11)
        rom_array[16'h008F] = 8'h4C;  // JMP $C0C0      ; Jump to next example
        rom_array[16'h0090] = 8'hC0;
        rom_array[16'h0091] = 8'hC0;

        // ===================================================
        // SUBROUTINE: Double Value ($C0A0)
        // Input: A register
        // Output: A register (doubled)
        // ===================================================
        rom_array[16'h00A0] = 8'h48;  // PHA            ; Save A on stack
        rom_array[16'h00A1] = 8'h0A;  // ASL A          ; Shift left (double)
        rom_array[16'h00A2] = 8'h68;  // PLA            ; Restore original A
        rom_array[16'h00A3] = 8'h69;  // ADC $0000      ; Add original to doubled
        rom_array[16'h00A4] = 8'h00;  // (This creates A*2 + A = A*3)
        rom_array[16'h00A5] = 8'h60;  // RTS            ; Return

        // ===================================================
        // EXAMPLE 6: String Operations ($C0C0)
        // Demonstrates: String processing, character handling
        // ===================================================
        rom_array[16'h00C0] = 8'hA0;  // LDY #0         ; String index
        rom_array[16'h00C1] = 8'h00;
        // String copy loop
        rom_array[16'h00C2] = 8'hB9;  // LDA $C200,Y    ; Load char from source
        rom_array[16'h00C3] = 8'h00;
        rom_array[16'h00C4] = 8'hC2;
        rom_array[16'h00C5] = 8'hF0;  // BEQ $C0CE      ; Branch if null terminator
        rom_array[16'h00C6] = 8'h07;
        rom_array[16'h00C7] = 8'h99;  // STA $0400,Y    ; Store char to destination
        rom_array[16'h00C8] = 8'h00;
        rom_array[16'h00C9] = 8'h04;
        rom_array[16'h00CA] = 8'hC8;  // INY            ; Increment index
        rom_array[16'h00CB] = 8'h4C;  // JMP $C0C2      ; Continue loop
        rom_array[16'h00CC] = 8'hC2;
        rom_array[16'h00CD] = 8'hC0;
        rom_array[16'h00CE] = 8'h99;  // STA $0400,Y    ; Store null terminator
        rom_array[16'h00CF] = 8'h00;
        rom_array[16'h00D0] = 8'h04;
        rom_array[16'h00D1] = 8'h4C;  // JMP $C0E0      ; Jump to next example
        rom_array[16'h00D2] = 8'hE0;
        rom_array[16'h00D3] = 8'hC0;

        // ===================================================
        // EXAMPLE 7: Math Functions ($C0E0)
        // Demonstrates: Multiplication by repeated addition
        // ===================================================
        rom_array[16'h00E0] = 8'hA9;  // LDA #5         ; First operand
        rom_array[16'h00E1] = 8'h05;
        rom_array[16'h00E2] = 8'h85;  // STA $C0        ; Store multiplicand
        rom_array[16'h00E3] = 8'hC0;
        rom_array[16'h00E4] = 8'hA9;  // LDA #7         ; Second operand
        rom_array[16'h00E5] = 8'h07;
        rom_array[16'h00E6] = 8'h85;  // STA $C1        ; Store multiplier
        rom_array[16'h00E7] = 8'hC1;
        rom_array[16'h00E8] = 8'hA9;  // LDA #0         ; Initialize result
        rom_array[16'h00E9] = 8'h00;
        rom_array[16'h00EA] = 8'h85;  // STA $C2        ; Store result
        rom_array[16'h00EB] = 8'hC2;
        // Multiplication loop
        rom_array[16'h00EC] = 8'hA5;  // LDA $C1        ; Load multiplier
        rom_array[16'h00ED] = 8'hC1;
        rom_array[16'h00EE] = 8'hF0;  // BEQ $C0F8      ; Exit if multiplier is 0
        rom_array[16'h00EF] = 8'h08;
        rom_array[16'h00F0] = 8'hA5;  // LDA $C2        ; Load current result
        rom_array[16'h00F1] = 8'hC2;
        rom_array[16'h00F2] = 8'h18;  // CLC            ; Clear carry
        rom_array[16'h00F3] = 8'h65;  // ADC $C0        ; Add multiplicand
        rom_array[16'h00F4] = 8'hC0;
        rom_array[16'h00F5] = 8'h85;  // STA $C2        ; Store new result
        rom_array[16'h00F6] = 8'hC2;
        rom_array[16'h00F7] = 8'hC6;  // DEC $C1        ; Decrement multiplier
        rom_array[16'h00F8] = 8'hC1;
        rom_array[16'h00F9] = 8'h4C;  // JMP $C0EC      ; Continue loop
        rom_array[16'h00FA] = 8'hEC;
        rom_array[16'h00FB] = 8'hC0;
        // Result in $C2 (should be 35 = 5*7)
        rom_array[16'h00FC] = 8'h4C;  // JMP $C100      ; Jump to I/O example
        rom_array[16'h00FD] = 8'h00;
        rom_array[16'h00FE] = 8'hC1;

        // ===================================================
        // EXAMPLE 8: I/O Operations ($C100)
        // Demonstrates: Reading switches, simple I/O
        // ===================================================
        rom_array[16'h0100] = 8'hAD;  // LDA $8000      ; Read I/O port (switches)
        rom_array[16'h0101] = 8'h00;
        rom_array[16'h0102] = 8'h80;
        rom_array[16'h0103] = 8'h85;  // STA $D0        ; Store switch value
        rom_array[16'h0104] = 8'hD0;
        rom_array[16'h0105] = 8'h29;  // AND #$0F       ; Mask lower 4 bits
        rom_array[16'h0106] = 8'h0F;
        rom_array[16'h0107] = 8'hC9;  // CMP #$0A       ; Compare with 10
        rom_array[16'h0108] = 8'h0A;
        rom_array[16'h0109] = 8'h30;  // BMI $C10E      ; Branch if less than 10
        rom_array[16'h010A] = 8'h03;
        rom_array[16'h010B] = 8'h18;  // CLC            ; Clear carry
        rom_array[16'h010C] = 8'h69;  // ADC #$37       ; Convert to ASCII A-F
        rom_array[16'h010D] = 8'h37;
        rom_array[16'h010E] = 8'h18;  // CLC            ; Clear carry
        rom_array[16'h010F] = 8'h69;  // ADC #$30       ; Convert to ASCII 0-9
        rom_array[16'h0110] = 8'h30;
        rom_array[16'h0111] = 8'h85;  // STA $D1        ; Store ASCII character
        rom_array[16'h0112] = 8'hD1;
        rom_array[16'h0113] = 8'h4C;  // JMP $C100      ; Loop back (infinite)
        rom_array[16'h0114] = 8'h00;
        rom_array[16'h0115] = 8'hC1;

        // ===================================================
        // STRING DATA ($C200)
        // Test string for string operations example
        // ===================================================
        rom_array[16'h0200] = 8'h48;  // 'H'
        rom_array[16'h0201] = 8'h65;  // 'e'
        rom_array[16'h0202] = 8'h6C;  // 'l'
        rom_array[16'h0203] = 8'h6C;  // 'l'
        rom_array[16'h0204] = 8'h6F;  // 'o'
        rom_array[16'h0205] = 8'h20;  // ' '
        rom_array[16'h0206] = 8'h36;  // '6'
        rom_array[16'h0207] = 8'h35;  // '5'
        rom_array[16'h0208] = 8'h30;  // '0'
        rom_array[16'h0209] = 8'h32;  // '2'
        rom_array[16'h020A] = 8'h00;  // null terminator

        // ===================================================
        // LOOKUP TABLE ($C300)
        // Square values for numbers 0-15
        // ===================================================
        rom_array[16'h0300] = 8'h00;  // 0^2 = 0
        rom_array[16'h0301] = 8'h01;  // 1^2 = 1
        rom_array[16'h0302] = 8'h04;  // 2^2 = 4
        rom_array[16'h0303] = 8'h09;  // 3^2 = 9
        rom_array[16'h0304] = 8'h10;  // 4^2 = 16
        rom_array[16'h0305] = 8'h19;  // 5^2 = 25
        rom_array[16'h0306] = 8'h24;  // 6^2 = 36
        rom_array[16'h0307] = 8'h31;  // 7^2 = 49
        rom_array[16'h0308] = 8'h40;  // 8^2 = 64
        rom_array[16'h0309] = 8'h51;  // 9^2 = 81
        rom_array[16'h030A] = 8'h64;  // 10^2 = 100
        rom_array[16'h030B] = 8'h79;  // 11^2 = 121
        rom_array[16'h030C] = 8'h90;  // 12^2 = 144
        rom_array[16'h030D] = 8'hA9;  // 13^2 = 169
        rom_array[16'h030E] = 8'hC4;  // 14^2 = 196
        rom_array[16'h030F] = 8'hE1;  // 15^2 = 225

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