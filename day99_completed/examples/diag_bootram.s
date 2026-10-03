; Diagnostic: verify the boot program bytes actually loaded into RAM.
; IFO shows registers and memory $0200-$027F, i.e. the program itself.
; Expected memory dump at $0200: CF DF 00 02 FF 3A EF
    .org $0200
    .byte $CF          ; CVR: clear VRAM
    .byte $DF,$00,$02  ; IFO $0200: show registers + memory $0200-$027F
    .byte $FF,$3A      ; WVS: wait ~1s
    .byte $EF          ; HLT: stop CPU, keep LCD running
