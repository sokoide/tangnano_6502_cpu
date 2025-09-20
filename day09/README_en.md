# Day 09: LCD Control and System Integration

---

🌐 Available languages:
[English](./README.md) | [日本語](./README_ja.md)

## 🎯 Learning Objectives

-   Principle and implementation of LCD timing control
-   RGB signal generation and VGA/LCD output
-   Design and implementation of a character display system
-   Building a VRAM (Video RAM) system

## 📚 Theory

### LCD Timing Control

**Basic Specifications of a 480x272 LCD:**

-   Resolution: 480x272 pixels
-   Refresh Rate: 60Hz
-   Pixel Clock: Approx. 9MHz
-   Sync Signals: HSYNC, VSYNC, DE (Data Enable)

**Timing Parameters:**

```
Horizontal Timing:
- Active Period: 480 pixels
- Front Porch: 5 pixels
- HSYNC Width: 41 pixels
- Back Porch: 2 pixels
- Total: 528 pixels

Vertical Timing:
- Active Period: 272 lines
- Front Porch: 8 lines
- VSYNC Width: 10 lines
- Back Porch: 2 lines
- Total: 292 lines
```

### Character Display System

**Character Mode Specifications:**

-   Character Size: 8x16 pixels
-   Display Area: 60x17 characters
-   Font ROM: 4KB (256 characters x 16 bytes)
-   VRAM: 1KB (60x17 = 1020 bytes)

## 🛠️ Practice 1: LCD Timing Controller

```systemverilog
module lcd_timing_controller (
    input  logic clk_pixel,    // 9MHz pixel clock
    input  logic rst_n,

    // Timing outputs
    output logic hsync,
    output logic vsync,
    output logic de,           // Data Enable

    // Coordinate outputs
    output logic [9:0] pixel_x,
    output logic [8:0] pixel_y,

    // Frame sync
    output logic frame_start,
    output logic line_start
);

    // Horizontal timing parameters
    localparam H_ACTIVE = 480;
    localparam H_FRONT  = 5;
    localparam H_SYNC   = 41;
    localparam H_BACK   = 2;
    localparam H_TOTAL  = H_ACTIVE + H_FRONT + H_SYNC + H_BACK; // 528

    // Vertical timing parameters
    localparam V_ACTIVE = 272;
    localparam V_FRONT  = 8;
    localparam V_SYNC   = 10;
    localparam V_BACK   = 2;
    localparam V_TOTAL  = V_ACTIVE + V_FRONT + V_SYNC + V_BACK; // 292

    logic [9:0] h_counter;
    logic [8:0] v_counter;

    // Horizontal counter
    always_ff @(posedge clk_pixel or negedge rst_n) begin
        if (!rst_n) begin
            h_counter <= 10'b0;
        end else begin
            if (h_counter == H_TOTAL - 1) begin
                h_counter <= 10'b0;
            end else begin
                h_counter <= h_counter + 1;
            end
        end
    end

    // Vertical counter
    always_ff @(posedge clk_pixel or negedge rst_n) begin
        if (!rst_n) begin
            v_counter <= 9'b0;
        end else begin
            if (h_counter == H_TOTAL - 1) begin
                if (v_counter == V_TOTAL - 1) begin
                    v_counter <= 9'b0;
                end else begin
                    v_counter <= v_counter + 1;
                end
            end
        end
    end

    // Sync signal generation
    always_comb begin
        // HSYNC (negative polarity)
        hsync = ~((h_counter >= H_ACTIVE + H_FRONT) &&
                  (h_counter < H_ACTIVE + H_FRONT + H_SYNC));

        // VSYNC (negative polarity)
        vsync = ~((v_counter >= V_ACTIVE + V_FRONT) &&
                  (v_counter < V_ACTIVE + V_FRONT + V_SYNC));

        // Data Enable
        de = (h_counter < H_ACTIVE) && (v_counter < V_ACTIVE);

        // Pixel coordinates
        pixel_x = h_counter;
        pixel_y = v_counter;

        // Frame/line start signals
        frame_start = (h_counter == 0) && (v_counter == 0);
        line_start = (h_counter == 0);
    end

endmodule
```

## 🛠️ Practice 2: Character Display Controller

```systemverilog
module character_display (
    input  logic clk_pixel,
    input  logic rst_n,

    // LCD timing inputs
    input  logic [9:0] pixel_x,
    input  logic [8:0] pixel_y,
    input  logic de,

    // VRAM interface
    output logic [9:0]  vram_addr,
    input  logic [7:0]  vram_data,

    // Font ROM interface
    output logic [11:0] font_addr,
    input  logic [7:0]  font_data,

    // RGB output
    output logic [7:0] rgb_red,
    output logic [7:0] rgb_green,
    output logic [7:0] rgb_blue
);

    // Character display area check
    logic in_char_area;
    logic [5:0] char_x;  // 0-59 (character coordinate)
    logic [4:0] char_y;  // 0-16 (character coordinate)
    logic [2:0] pixel_x_in_char;  // 0-7 (pixel coordinate within character)
    logic [3:0] pixel_y_in_char;  // 0-15 (pixel coordinate within character)

    always_comb begin
        // Character display area check (480x272 -> 60x17 characters)
        in_char_area = (pixel_x < 480) && (pixel_y < 272);

        // Character coordinate calculation
        char_x = pixel_x[8:3];  // pixel_x / 8
        char_y = pixel_y[7:4];  // pixel_y / 16

        // Pixel coordinate within character
        pixel_x_in_char = pixel_x[2:0];  // pixel_x % 8
        pixel_y_in_char = pixel_y[3:0];  // pixel_y % 16

        // VRAM address calculation (linear addressing)
        vram_addr = {4'b0, char_y} * 60 + {4'b0, char_x};
    end

    // Font ROM address calculation
    always_comb begin
        // Font address = character code * 16 + line number
        font_addr = {vram_data, 4'b0} + {8'b0, pixel_y_in_char};
    end

    // Pixel drawing
    logic pixel_on;
    always_comb begin
        // Get the corresponding bit of the font data
        pixel_on = font_data[7 - pixel_x_in_char];
    end

    // RGB output generation
    always_ff @(posedge clk_pixel) begin
        if (de && in_char_area && pixel_on) begin
            // Character color (white)
            rgb_red   <= 8'hFF;
            rgb_green <= 8'hFF;
            rgb_blue  <= 8'hFF;
        end else begin
            // Background color (black)
            rgb_red   <= 8'h00;
            rgb_green <= 8'h00;
            rgb_blue  <= 8'h00;
        end
    end

endmodule
```

## 🛠️ Practice 3: VRAM System

```systemverilog
module vram_system (
    input  logic clk,
    input  logic rst_n,

    // CPU-side access
    input  logic [15:0] cpu_addr,
    input  logic [7:0]  cpu_data_in,
    output logic [7:0]  cpu_data_out,
    input  logic        cpu_write,
    input  logic        cpu_read,

    // LCD-side access
    input  logic [9:0]  lcd_addr,
    output logic [7:0]  lcd_data,

    // Special control (for custom instructions)
    input  logic        clear_vram  // CVR instruction
);

    // VRAM memory (1KB)
    logic [7:0] vram_memory [0:1023];

    // CPU-side access processing
    logic vram_access;
    logic [9:0] cpu_vram_addr;

    always_comb begin
        // VRAM access check (0xE000-0xE3FF)
        vram_access = (cpu_addr >= 16'hE000) && (cpu_addr <= 16'hE3FF);
        cpu_vram_addr = cpu_addr[9:0];
    end

    // CPU write processing
    always_ff @(posedge clk) begin
        if (cpu_write && vram_access) begin
            vram_memory[cpu_vram_addr] <= cpu_data_in;
        end else if (clear_vram) begin
            // CVR instruction: Clear all VRAM
            for (int i = 0; i < 1024; i++) begin
                vram_memory[i] <= 8'h20;  // Space character
            end
        end
    end

    // CPU read processing (shadow RAM: 0x7C00-0x7FFF)
    always_comb begin
        if (cpu_read && ((cpu_addr >= 16'h7C00 && cpu_addr <= 16'h7FFF) ||
                         (cpu_addr >= 16'hE000 && cpu_addr <= 16'hE3FF))) begin
            cpu_data_out = vram_memory[cpu_vram_addr];
        end else begin
            cpu_data_out = 8'h00;
        end
    end

    // LCD-side read (always accessible)
    assign lcd_data = vram_memory[lcd_addr];

endmodule
```

## 🛠️ Practice 4: Font ROM

```systemverilog
module font_rom (
    input  logic clk,
    input  logic [11:0] addr,  // 4KB address
    output logic [7:0]  data
);

    // Font data (based on Sweet16Font)
    logic [7:0] font_memory [0:4095];

    // Initialize font data
    initial begin
        $readmemh("font_data.hex", font_memory);
    end

    // Read
    always_ff @(posedge clk) begin
        data <= font_memory[addr];
    end

endmodule
```

## 🛠️ Practice 5: System Integration

```systemverilog
module lcd_cpu_system (
    input  logic clk_27mhz,    // 27MHz input clock
    input  logic rst_n,

    // LCD output
    output logic lcd_clk,
    output logic lcd_hsync,
    output logic lcd_vsync,
    output logic lcd_de,
    output logic [7:0] lcd_red,
    output logic [7:0] lcd_green,
    output logic [7:0] lcd_blue,

    // Memory interface
    output logic [15:0] mem_addr,
    output logic [7:0]  mem_data_out,
    input  logic [7:0]  mem_data_in,
    output logic        mem_read,
    output logic        mem_write
);

    // PLL: 27MHz -> 9MHz pixel clock
    logic clk_pixel;
    logic pll_locked;

    pll_27_to_9 pll_inst (
        .clk_in(clk_27mhz),
        .clk_out(clk_pixel),
        .locked(pll_locked)
    );

    // LCD timing control
    logic hsync, vsync, de;
    logic [9:0] pixel_x;
    logic [8:0] pixel_y;

    lcd_timing_controller timing_inst (
        .clk_pixel(clk_pixel),
        .rst_n(rst_n & pll_locked),
        .hsync(hsync),
        .vsync(vsync),
        .de(de),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y)
    );

    // VRAM system
    logic [9:0] vram_addr;
    logic [7:0] vram_data;

    vram_system vram_inst (
        .clk(clk_27mhz),
        .rst_n(rst_n),
        .cpu_addr(mem_addr),
        .cpu_data_in(mem_data_out),
        .cpu_write(mem_write),
        .lcd_addr(vram_addr),
        .lcd_data(vram_data)
    );

    // Font ROM
    logic [11:0] font_addr;
    logic [7:0] font_data;

    font_rom font_inst (
        .clk(clk_pixel),
        .addr(font_addr),
        .data(font_data)
    );

    // Character display control
    character_display display_inst (
        .clk_pixel(clk_pixel),
        .rst_n(rst_n & pll_locked),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .de(de),
        .vram_addr(vram_addr),
        .vram_data(vram_data),
        .font_addr(font_addr),
        .font_data(font_data),
        .rgb_red(lcd_red),
        .rgb_green(lcd_green),
        .rgb_blue(lcd_blue)
    );

    // LCD output
    assign lcd_clk = clk_pixel;
    assign lcd_hsync = hsync;
    assign lcd_vsync = vsync;
    assign lcd_de = de;

endmodule
```

## 📝 Assignments

### Basic Assignments

1.  Implement a scroll display function
2.  Support for color display (character color/background color)
3.  Cursor display function

### Advanced Assignments

1.  Implement a graphics mode
2.  Sprite function
3.  Hardware scrolling

## 📚 What I Learned Today

-   [ ] Implementation of LCD timing control
-   [ ] Design of a character display system
-   [ ] Dual-access control of VRAM
-   [ ] How to use a font ROM
-   [ ] Integration of the entire system

## 🎯 Preview for Tomorrow

As the final day, in Day 10 we will learn about assembly programming and applications:

-   How to use the cc65 assembler
-   Utilizing custom instructions
-   Creating practical programs
