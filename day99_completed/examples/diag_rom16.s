; Diagnostic: dump the boot program bytes at index 16+ (RAM $0210-$021F).
; Suspected Gowin synthesis bug: byte index >= 16 loses bit 7 on real silicon.
; Expected correct IFO memory row at $0210:  C9 A5 D0 EE A9 4C 8D FF
; If the bug is present it will read:       49 25 50 6E 29 4C 0D 7F
; (HLT at index 6 stops execution; later bytes are load-only data.)
    .org $0200
    .byte $CF          ; CVR: clear VRAM
    .byte $DF,$00,$02  ; IFO $0200: show registers + memory $0200-$027F
    .byte $FF,$3A      ; WVS: wait ~1s so the dump stays visible
    .byte $EF          ; HLT: stop CPU, keep LCD running
; index 7-15: padding (never executed)
    .byte $EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA,$EA
; index 16-23: markers with bit 7 set
    .byte $C9,$A5,$D0,$EE,$A9,$4C,$8D,$FF
