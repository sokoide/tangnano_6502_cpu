# Day 04: Visual Foundation (LCD Display & Memory Map)

---

🌐 Languages:
[English](./README.md) | [日本語](./README_ja.md)

## 📜 Overview

Until now, we have verified operations using only LEDs—providing just "one bit" of information. However, as we build a complex CPU, LEDs are no longer sufficient.

In Day 04, we will build an **"LCD Debug Dashboard"** to support our CPU development. The goal today is to create the environment that will let us see CPU internals (like instructions and registers) in real-time once the CPU is brought up.

## 🧠 Memory Model Note

Day 04–10 use a simple program ROM (`rom.sv`) to supply instructions. RAM is still used for data; the RAM-backed program flow starts in Day 11.

## 🎯 Learning Objectives

- **LCD Pipeline**: Complete the flow from VRAM through Font ROM to the LCD panel.
- **Memory Map**: Understand the layout of the 6502 address space.
- **VRAM Operation**: Learn how writing character codes to specific memory locations corresponds to screen positions.

## 💡 Memory Map and VRAM

The **Memory Map** defines how the CPU's address space is connected to various memory blocks and peripherals. The memory map for our 6502 system is as follows:

### 6502 System Memory Map (used in this Training)

| Address Range | Purpose | Description |
| :--- | :--- | :--- |
| `0x0000 - 0x00FF` | Zero Page | Fast-access 256-byte memory area |
| `0x0100 - 0x01FF` | Stack | Area used by the Stack Pointer (SP) |
| `0x0200 - 0x7BFF` | Program RAM | Main memory for programs/data (30.5KB) |
| `0x7C00 - 0x7FFF` | Shadow VRAM | CPU-readable VRAM copy (1KB) |
| `0x8000 - 0xDFFF` | (Unmapped) | Reserved for future expansion |
| `0xE000 - 0xE3FF` | Text VRAM | Character codes (ASCII) for LCD display (1KB) |
| `0xE400 - 0xFFFF` | (Unmapped) | Reserved for I/O or expansion |

### VRAM to LCD Mapping

The LCD screen (480x272 pixels) is divided into 8x16 pixel character units, allowing for a display of **60 columns × 17 rows**. Each ASCII code in VRAM maps to a specific coordinate.

**Display Address Formula:**
`VRAM Address = 0xE000 + (Row * 60) + Column`

For example, writing `8'h41` ('A') to `0xE000` displays 'A' in the top-left corner.

### Character Rendering Pipeline

```mermaid
graph TD
    CPU[CPU/Logic] -->|1. Write ASCII Code| VRAM[Text VRAM<br/>0xE000 - 0xE3FF]

    subgraph "LCD Controller (lcd.sv)"
        VRAM -->|2. Read| Code[ASCII Code]
        Coord[Pixel X, Y Counter] -->|3. Calc address from coords| VRAM
        Code -->|4. Index Font and Row| FontROM[Font ROM<br/>Bitmap Data]
        Coord -->|"5. Current scanline row (0-15)"| FontROM
        FontROM -->|6. 8px dot pattern| Serial[Serializer]
        Serial -->|7. Output RGB pixel-by-pixel| Panel[LCD Panel]
    end
```

## 🛠️ Implementation Steps

1. **Integrate `lcd_demo.sv`**:
    - Instantiate `lcd_demo` in `top_core.sv` to enable video output on the actual LCD.
2. **Display Demo Text**:
    - VRAM is pre-filled with text like "VRAM TEXT" on boot. Verify that this appears correctly on the screen.

## 💡 Design Tip: The Importance of Visualization

In hardware development, it is notoriously difficult to see what's happening inside the chip. By building this dashboard today, you will be able to visually confirm things like the Program Counter moving starting tomorrow.

## 📝 Exercises

- [ ] Correctly instantiate `lcd_demo` in `top_core.sv` and ensure the simulation results in `PASS`.
- [ ] Program the hardware and confirm that the demo text appears on the LCD.
- [ ] (Advanced) Modify the initialization code in `lcd_demo.sv` to display your own name.

## 📚 What I Learned Today

- [ ] Concepts of Memory Mapping.
- [ ] Relationship between VRAM and screen coordinates.
- [ ] Mechanics of character display (Font ROM).

## 🎯 Preview for Tomorrow

From Day 05, we finally start building the CPU itself. We will begin by implementing the **Register Set** for memory and the **Program Counter** to track execution flow.
