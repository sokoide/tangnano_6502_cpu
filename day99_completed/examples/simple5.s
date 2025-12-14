; ADC, CMP, BNE
; Program loaded and starts at 0x0200
    .org $0200

start:
; load ' ' (#$20) into A register
    LDA #$20
loop:
; CVR: clear VRAM
    .byte $CF
; store a value of A register at $01
    STA $01
; display register A's value at (59, 0)
    STA $E03B
; IFO: show registers and memory at $0000-$007F
    .byte $DF,$00,$00
; WVS: wait for 0.3 seconds ($12 == 18 frames)
; $3A == 58 frames per second
    .byte $FF, $12
; inclement A register
    CLC
    ADC #1
; if A != #$7F (next char of ~), goto loop
    CMP #$7F
    BNE loop
; else A=' ' (#$20)
    LDA #$20
; loop
    JMP loop
