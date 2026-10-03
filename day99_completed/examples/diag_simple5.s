; Check simple5's arithmetic before IFO or WVS can affect execution.
; Show the boot bytes first, then leave the zero-page result on screen.
    .org $0200

    .byte $CF          ; CVR: clear VRAM
    LDA #$20
    STA $01            ; initial A
    CLC
    ADC #$01
    STA $02            ; ADC result: $21
    CMP #$7F
    PHP
    PLA
    STA $03            ; CMP status: $B0 (N=1, B=1, bit 5=1)
    LDA $02            ; restore A=$21 for the register display
    .byte $DF,$00,$02  ; IFO $0200: show registers and program bytes
    .byte $FF,$F0      ; WVS: leave the program dump up for ~4 seconds
    .byte $DF,$00,$00  ; IFO $0000: show $01=$20, $02=$21, $03=$B0
    .byte $EF          ; HLT: retain the zero-page display
