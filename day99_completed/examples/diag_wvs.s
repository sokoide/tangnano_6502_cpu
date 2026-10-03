; Isolate VSync waiting from arithmetic and IFO.
    .org $0200

    .byte $CF          ; CVR: clear VRAM
    LDA #'A'
    STA $E03B         ; top-right marker before WVS
    .byte $FF,$F0      ; WVS: wait about 4.1 seconds at 58 frames/s
    LDA #'B'
    STA $E03B         ; top-right marker after WVS
    .byte $EF          ; HLT: retain 'B'
