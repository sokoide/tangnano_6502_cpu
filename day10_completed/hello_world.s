; hello_world.s
; Displays a banner on the Tang Nano LCD

.org $0200

START:
    ; Clear the VRAM using the custom CVR command
    .byte $CF

    ; Load message from ROM -> VRAM
    LDX #$00
WRITE_LOOP:
    LDA MESSAGE,X
    BEQ DONE
    STA $E000,X
    INX
    JMP WRITE_LOOP

DONE:
    ; Halt when the banner is fully written
    .byte $EF

MESSAGE:
    .byte "HELLO WORLD FROM TANG NANO!", $00

.org $FFFC
.word START
