; Isolate the first simple5 ADC without WVS. The 'S' marker proves that
; execution reached the instruction after CVR even if later work stalls.
    .org $0200

    .byte $CF          ; CVR: clear VRAM
    LDA #'S'
    STA $E03B         ; progress marker at the top-right cell
    LDA #$20
    STA $01            ; initial A
    CLC
    ADC #$01
    STA $02            ; ADC result: $21
    STA $E03B         ; final top-right character: '!'
    .byte $DF,$00,$00  ; IFO $0000: display RAM $0000-$007F
    .byte $EF          ; HLT: retain the result
