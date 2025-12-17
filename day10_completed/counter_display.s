; counter_display.s
; Hex counter and animation on the LCD

VRAM_BASE = $E000
COUNTER_ADDR = $0080

.org $0200

START:
    .byte $CF           ; CVR - clear VRAM

    LDA #$00
    STA COUNTER_ADDR

MAIN_LOOP:
    ; Position at center of the screen
    LDX #30
    LDY #8

    ; Compute VRAM offset = Y * 60 + X
    TYA                 ; A = Y
    ASL                 ; A = Y*2
    ASL                 ; A = Y*4
    STA $81             ; Save Y*4

    TYA                 ; A = Y
    ASL                 ; A = Y*2
    ASL                 ; A = Y*4
    ASL                 ; A = Y*8
    ASL                 ; A = Y*16
    ASL                 ; A = Y*32
    ASL                 ; A = Y*64
    SEC
    SBC $81             ; A = Y*60

    CLC
    ADC #30             ; Add X
    TAY                 ; Y = offset

    ; Display the counter value
    LDA COUNTER_ADDR
    JSR DISPLAY_HEX

    ; Delay for visibility
    JSR DELAY

    ; Increment counter and wrap
    INC COUNTER_ADDR
    LDA COUNTER_ADDR
    CMP #$FF
    BNE MAIN_LOOP

    LDA #$00
    STA COUNTER_ADDR
    JMP MAIN_LOOP

; Print two hex digits at VRAM_BASE + Y
DISPLAY_HEX:
    PHA

    LSR
    LSR
    LSR
    LSR
    JSR HEX_TO_ASCII
    STA VRAM_BASE,Y
    INY

    PLA
    AND #$0F
    JSR HEX_TO_ASCII
    STA VRAM_BASE,Y

    RTS

HEX_TO_ASCII:
    CMP #$0A
    BCC IS_DIGIT
    SEC
    SBC #$0A
    CLC
    ADC #'A'
    RTS
IS_DIGIT:
    CLC
    ADC #'0'
    RTS

DELAY:
    LDX #$FF
DELAY_OUTER:
    LDY #$FF
DELAY_INNER:
    DEY
    BNE DELAY_INNER
    DEX
    BNE DELAY_OUTER
    RTS

.org $FFFC
.word START

.org $FFFC
.word START
