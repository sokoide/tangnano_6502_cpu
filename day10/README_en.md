# Day 10: Assembly Programming and Applications

---

🌐 Available languages:
[English](./README.md) | [日本語](./README_ja.md)

## 🎯 Learning Objectives

-   Master how to use the cc65 assembler toolchain
-   Practice 6502 assembly programming
-   Utilize custom instructions (CVR, IFO, HLT, WVS)
-   Create practical demo programs

## 📚 Theory

### cc65 Toolchain

**Components:**

-   **ca65**: Assembler (6502 assembly -> object file)
-   **ld65**: Linker (object file -> executable file)
-   **cc65**: C compiler (C language -> assembly)

**File Formats:**

-   `.s`: Assembly source file
-   `.o`: Object file
-   `.bin`: Binary file
-   `.hex`: Intel HEX file

### 6502 Assembly Notation

**Basic Syntax:**

```assembly
; Comment
LABEL:              ; Label definition
    INSTRUCTION     ; Instruction (implied)
    INSTRUCTION #$nn ; Immediate
    INSTRUCTION $nn  ; Zero page
    INSTRUCTION $nnnn ; Absolute address
```

**Pseudo-instructions:**

```assembly
.org $0200          ; Set address
.byte $01, $02      ; Byte data
.word $1234         ; Word data (little-endian)
.include "file.inc" ; Include file
```

## 🛠️ Practice 1: Basic Program

### Hello World Program

```assembly
; hello_world.s
; Tang Nano 6502 Hello World

.org $0200

START:
    ; Clear VRAM with a custom instruction
    .byte $CF           ; CVR - Clear VRAM

    ; Write "HELLO WORLD" to VRAM
    LDX #$00            ; Initialize index

WRITE_LOOP:
    LDA MESSAGE,X       ; Read message
    BEQ DONE            ; If 0, then done
    STA $E000,X         ; Write to VRAM
    INX                 ; Increment index
    JMP WRITE_LOOP      ; Continue loop

DONE:
    .byte $EF           ; HLT - Halt program

MESSAGE:
    .byte "HELLO WORLD FROM TANG NANO!", $00

; Vector table (if needed)
.org $FFFC
.word START             ; Reset vector
```

### Build Configuration File (build.cfg)

```
# cc65 configuration for Tang Nano 6502

FEATURES {
    STARTADDRESS: default = $0200;
}

SYMBOLS {
    __STACK_START__: type = weak, value = $01FF;
    __STACK_SIZE__:  type = weak, value = $0100;
}

MEMORY {
    ZP:   file = "", start = $0000, size = $0100, type = rw;
    RAM:  file = %O, start = $0200, size = $7E00, type = rw;
    VRAM: file = "", start = $E000, size = $0400, type = rw;
}

SEGMENTS {
    ZEROPAGE: load = ZP,  type = zp;
    CODE:     load = RAM, type = ro;
    DATA:     load = RAM, type = rw;
    BSS:      load = RAM, type = bss;
}
```

## 🛠️ Practice 2: Counter and Animation

```assembly
; counter_display.s
; Numeric counter and animation display

.org $0200

; Constant definitions
VRAM_BASE = $E000
COUNTER_ADDR = $80

START:
    .byte $CF           ; CVR - Clear VRAM

    ; Initialize counter
    LDA #$00
    STA COUNTER_ADDR

MAIN_LOOP:
    ; Set counter display position (center of screen)
    LDX #30             ; X coordinate (30th character)
    LDY #8              ; Y coordinate (8th line)

    ; Calculate VRAM address: Y*60 + X
    ; Calculate Y*60 (Y*64 - Y*4 = Y*60)
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
    SBC $81             ; A = Y*64 - Y*4 = Y*60

    CLC
    ADC #30             ; A = Y*60 + X
    TAY                 ; Y = VRAM offset

    ; Display counter value
    LDA COUNTER_ADDR
    JSR DISPLAY_HEX

    ; Delay
    JSR DELAY

    ; Increment counter
    INC COUNTER_ADDR

    ; Reset at 255
    LDA COUNTER_ADDR
    CMP #$FF
    BNE MAIN_LOOP

    LDA #$00
    STA COUNTER_ADDR
    JMP MAIN_LOOP

; Hex display subroutine
; A: value to display, Y: VRAM offset
DISPLAY_HEX:
    PHA                 ; Save A

    ; Upper 4 bits
    LSR
    LSR
    LSR
    LSR
    JSR HEX_TO_ASCII
    STA VRAM_BASE,Y
    INY

    ; Lower 4 bits
    PLA                 ; Restore A
    AND #$0F
    JSR HEX_TO_ASCII
    STA VRAM_BASE,Y

    RTS

; Convert 4-bit value to ASCII character
; A: 0-15, Return value: ASCII character
HEX_TO_ASCII:
    CMP #$0A
    BCC IS_DIGIT        ; If < 10, then it's a digit
    ; If A-F
    SEC
    SBC #$0A
    CLC
    ADC #'A'
    RTS
IS_DIGIT:
    CLC
    ADC #'0'
    RTS

; Delay routine
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
```

## 🛠️ Practice 3: Scrolling Text

```assembly
; scroll_text.s
; Scrolling text display

.org $0200

; Constants
VRAM_BASE = $E000
SCROLL_LINE = 8         ; Scroll line
SCROLL_SPEED = 10       ; Scroll speed

START:
    .byte $CF           ; Clear VRAM

    ; Initialize scroll position
    LDA #$00
    STA SCROLL_POS

SCROLL_LOOP:
    ; Clear the specified line of the screen
    LDX #SCROLL_LINE
    JSR CLEAR_LINE

    ; Display scrolling text
    JSR DISPLAY_SCROLL_TEXT

    ; Wait for scroll
    LDX #SCROLL_SPEED
WAIT_LOOP:
    JSR DELAY
    DEX
    BNE WAIT_LOOP

    ; Update scroll position
    INC SCROLL_POS
    LDA SCROLL_POS
    CMP #MESSAGE_LENGTH
    BNE SCROLL_LOOP

    ; End of message, reset
    LDA #$00
    STA SCROLL_POS
    JMP SCROLL_LOOP

; Clear specified line
; X: line number
CLEAR_LINE:
    ; Calculate VRAM line address
    TXA
    JSR CALC_LINE_ADDR
    TAY

    ; Fill 60 characters with spaces
    LDX #60
    LDA #' '
CLEAR_LOOP:
    STA VRAM_BASE,Y
    INY
    DEX
    BNE CLEAR_LOOP
    RTS

; Display scrolling text
DISPLAY_SCROLL_TEXT:
    ; Calculate display start position
    LDA #SCROLL_LINE
    JSR CALC_LINE_ADDR
    TAY

    ; Display message
    LDX SCROLL_POS
    LDA #0              ; Display character count

DISPLAY_LOOP:
    LDA MESSAGE,X       ; Read message
    BEQ DISPLAY_DONE    ; If 0, then done
    STA VRAM_BASE,Y     ; Write to VRAM
    INY
    INX

    ; Check screen width
    TYA
    AND #$3F            ; Y % 64 (simplified, should be 60)
    CMP #60
    BCC DISPLAY_LOOP

DISPLAY_DONE:
    RTS

; Calculate VRAM offset from line number
; A: line number, Return value: A = offset
CALC_LINE_ADDR:
    ; Calculate A*60
    STA $82             ; Save line number
    ASL                 ; A*2
    ASL                 ; A*4
    STA $83             ; Save A*4

    LDA $82             ; Original value
    ASL                 ; A*2
    ASL                 ; A*4
    ASL                 ; A*8
    ASL                 ; A*16
    ASL                 ; A*32
    ASL                 ; A*64
    SEC
    SBC $83             ; A*64 - A*4 = A*60
    RTS

DELAY:
    ; Simple delay
    LDY #$FF
DELAY_LOOP:
    DEY
    BNE DELAY_LOOP
    RTS

SCROLL_POS:
    .byte $00

MESSAGE:
    .byte "*** TANG NANO 6502 CPU PROJECT *** "
    .byte "WELCOME TO FPGA WORLD! "
    .byte "THIS IS A COMPLETE 6502 IMPLEMENTATION "
    .byte "WITH LCD CONTROLLER ON TANG NANO FPGA BOARD. "
    .byte "ENJOY RETRO COMPUTING! *** ", $00

MESSAGE_LENGTH = * - MESSAGE - 1  ; Calculate message length

; Custom instruction demo
CUSTOM_DEMO:
    .byte $DF           ; IFO - Display debug info
    .byte $FF           ; WVS - Wait for VSync
    RTS
```

## 🛠️ Practice 4: Makefile and Build System

```makefile
# Makefile for Tang Nano 6502 Assembly Programs

# Tools
CA65 = ca65
LD65 = ld65
SREC = srec_cat

# Default target
PROGRAM = hello_world

# Source files
SOURCES = $(PROGRAM).s
OBJECTS = $(PROGRAM).o
BINARY = $(PROGRAM).bin
HEXFILE = $(PROGRAM).hex

# Build configuration
CONFIG = build.cfg

# Default target
all: $(HEXFILE)

# Assembly to object
%.o: %.s
	$(CA65) -t none -o $@ $<

# Link to binary
$(BINARY): $(OBJECTS)
	$(LD65) -C $(CONFIG) -o $@ $^

# Convert to Intel HEX
$(HEXFILE): $(BINARY)
	$(SREC) $< -binary -offset 0x0200 -o $@ -intel

# Generate SystemVerilog include file
include: $(HEXFILE)
	python3 ../utils/hex_to_sv.py $(HEXFILE) > ../include/boot_program.sv

# Clean
clean:
	rm -f *.o *.bin *.hex

# Program targets
hello: PROGRAM = hello_world
hello: all

counter: PROGRAM = counter_display
counter: all

scroll: PROGRAM = scroll_text
scroll: all

.PHONY: all clean include hello counter scroll
```

## 🛠️ Practice 5: Python Conversion Script

```python
#!/usr/bin/env python3
# hex_to_sv.py
# Intel HEX to SystemVerilog memory initialization

import sys

def hex_to_sv(hex_file):
    """Converts an Intel HEX file to SystemVerilog format"""

    memory = [0] * 32768  # 32KB memory

    with open(hex_file, 'r') as f:
        for line in f:
            line = line.strip()
            if not line.startswith(':'):
                continue

            # Parse Intel HEX
            byte_count = int(line[1:3], 16)
            address = int(line[3:7], 16)
            record_type = int(line[7:9], 16)

            if record_type == 0:  # Data record
                for i in range(byte_count):
                    data_byte = int(line[9 + i*2:11 + i*2], 16)
                    if address + i < len(memory):
                        memory[address + i] = data_byte

    # Generate SystemVerilog output
    print("// Auto-generated boot program")
    print("// Generated from:", hex_file)
    print()
    print("initial begin")

    # Output only non-zero data
    for addr in range(len(memory)):
        if memory[addr] != 0:
            print(f"    boot_memory[16'h{addr:04X}] = 8'h{memory[addr]:02X};")

    print("end")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 hex_to_sv.py <hex_file>")
        sys.exit(1)

    hex_to_sv(sys.argv[1])
```

## 📝 Assignments

### Basic Assignments

1.  Calculator program (simple arithmetic)
2.  Digital clock display
3.  Pattern generator

### Advanced Assignments

1.  Tetris-style puzzle game
2.  UART communication program
3.  Music player program

## 🔧 Development Workflow

### 1. Create Program

```bash
# Edit assembly file
vim hello_world.s
```

### 2. Build

```bash
# Run build
make hello

# Generate SystemVerilog include file
make include
```

### 3. Write to FPGA

```bash
# Return to project directory
cd ..

# Build & write to FPGA
make download
```

## 📚 Troubleshooting

### Common Errors

1.  **Assembly error**: Check syntax, check for duplicate labels
2.  **Linker error**: Check for duplicate addresses, check for size overflow
3.  **Execution error**: Check memory map, check for infinite loops

### Debugging Techniques

1.  **IFO instruction**: Check the state of registers and memory
2.  **Step-by-step execution**: Test step-by-step from small parts
3.  **Simulation**: Verify with a testbench before running on hardware

## 📚 What I Learned Today

-   [ ] How to use the cc65 toolchain
-   [ ] Practical assembly programming
-   [ ] Effective use of custom instructions
-   [ ] Building a build system
-   [ ] Debugging and troubleshooting

## 🎓 Course Complete!

Congratulations! Through 10 days of learning, you have acquired the following:

### Acquired Skills

✅ **FPGA Development**: Basic development flow with GoWin EDA
✅ **SystemVerilog**: Intermediate HDL design skills
✅ **CPU Design**: Complete understanding and implementation of the 6502 architecture
✅ **System Integration**: Coordinated design of CPU, memory, and I/O
✅ **On-Device Development**: Implementation skills that connect theory and practice

### Next Steps

-   Challenge a more complex CPU architecture
-   Add your own custom instructions
-   Performance optimization
-   Application to other FPGA projects

**Enjoy your wonderful journey of FPGA development!**
