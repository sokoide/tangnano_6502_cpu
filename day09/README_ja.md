# Day 09: LCD制御とシステム統合

## 🎯 学習目標

- LCD タイミング制御の原理と実装
- RGB信号生成とVGA/LCD出力
- 文字表示システムの設計と実装
- VRAM (Video RAM) システムの構築

## 📚 理論学習

### LCDタイミング制御

**480×272 LCD の基本仕様:**
- 解像度: 480×272 ピクセル
- リフレッシュレート: 60Hz
- ピクセルクロック: 約9MHz
- 同期信号: HSYNC, VSYNC, DE (Data Enable)

**タイミングパラメータ:**
```
水平タイミング:
- アクティブ期間: 480 ピクセル
- フロントポーチ: 5 ピクセル
- HSYNC幅: 41 ピクセル
- バックポーチ: 2 ピクセル
- 合計: 528 ピクセル

垂直タイミング:
- アクティブ期間: 272 ライン
- フロントポーチ: 8 ライン
- VSYNC幅: 10 ライン
- バックポーチ: 2 ライン
- 合計: 292 ライン
```

### 文字表示システム

**文字モード仕様:**
- 文字サイズ: 8×16 ピクセル
- 表示領域: 60×17 文字
- フォントROM: 4KB (256文字 × 16バイト)
- VRAM: 1KB (60×17 = 1020バイト)

## 🛠️ 実習1: LCD タイミング制御器

```systemverilog
module lcd_timing_controller (
    input  logic clk_pixel,    // 9MHz ピクセルクロック
    input  logic rst_n,

    // タイミング出力
    output logic hsync,
    output logic vsync,
    output logic de,           // Data Enable

    // 座標出力
    output logic [9:0] pixel_x,
    output logic [8:0] pixel_y,

    // フレーム同期
    output logic frame_start,
    output logic line_start
);

    // 水平タイミングパラメータ
    localparam H_ACTIVE = 480;
    localparam H_FRONT  = 5;
    localparam H_SYNC   = 41;
    localparam H_BACK   = 2;
    localparam H_TOTAL  = H_ACTIVE + H_FRONT + H_SYNC + H_BACK; // 528

    // 垂直タイミングパラメータ
    localparam V_ACTIVE = 272;
    localparam V_FRONT  = 8;
    localparam V_SYNC   = 10;
    localparam V_BACK   = 2;
    localparam V_TOTAL  = V_ACTIVE + V_FRONT + V_SYNC + V_BACK; // 292

    logic [9:0] h_counter;
    logic [8:0] v_counter;

    // 水平カウンタ
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

    // 垂直カウンタ
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

    // 同期信号生成
    always_comb begin
        // HSYNC (負極性)
        hsync = ~((h_counter >= H_ACTIVE + H_FRONT) &&
                  (h_counter < H_ACTIVE + H_FRONT + H_SYNC));

        // VSYNC (負極性)
        vsync = ~((v_counter >= V_ACTIVE + V_FRONT) &&
                  (v_counter < V_ACTIVE + V_FRONT + V_SYNC));

        // Data Enable
        de = (h_counter < H_ACTIVE) && (v_counter < V_ACTIVE);

        // ピクセル座標
        pixel_x = h_counter;
        pixel_y = v_counter;

        // フレーム/ライン開始信号
        frame_start = (h_counter == 0) && (v_counter == 0);
        line_start = (h_counter == 0);
    end

endmodule
```

## 🛠️ 実習2: 文字表示制御器

```systemverilog
module character_display (
    input  logic clk_pixel,
    input  logic rst_n,

    // LCD タイミング入力
    input  logic [9:0] pixel_x,
    input  logic [8:0] pixel_y,
    input  logic de,

    // VRAM インターフェース
    output logic [9:0]  vram_addr,
    input  logic [7:0]  vram_data,

    // フォントROM インターフェース
    output logic [11:0] font_addr,
    input  logic [7:0]  font_data,

    // RGB出力
    output logic [7:0] rgb_red,
    output logic [7:0] rgb_green,
    output logic [7:0] rgb_blue
);

    // 文字表示領域判定
    logic in_char_area;
    logic [5:0] char_x;  // 0-59 (文字座標)
    logic [4:0] char_y;  // 0-16 (文字座標)
    logic [2:0] pixel_x_in_char;  // 0-7 (文字内ピクセル座標)
    logic [3:0] pixel_y_in_char;  // 0-15 (文字内ピクセル座標)

    always_comb begin
        // 文字表示領域判定 (480×272 → 60×17文字)
        in_char_area = (pixel_x < 480) && (pixel_y < 272);

        // 文字座標計算
        char_x = pixel_x[8:3];  // pixel_x / 8
        char_y = pixel_y[7:4];  // pixel_y / 16

        // 文字内ピクセル座標
        pixel_x_in_char = pixel_x[2:0];  // pixel_x % 8
        pixel_y_in_char = pixel_y[3:0];  // pixel_y % 16

        // VRAM アドレス計算 (リニアアドレッシング)
        vram_addr = {4'b0, char_y} * 60 + {4'b0, char_x};
    end

    // フォントROM アドレス計算
    always_comb begin
        // フォントアドレス = 文字コード × 16 + 行番号
        font_addr = {vram_data, 4'b0} + {8'b0, pixel_y_in_char};
    end

    // ピクセル描画
    logic pixel_on;
    always_comb begin
        // フォントデータの該当ビットを取得
        pixel_on = font_data[7 - pixel_x_in_char];
    end

    // RGB出力生成
    always_ff @(posedge clk_pixel) begin
        if (de && in_char_area && pixel_on) begin
            // 文字色 (白)
            rgb_red   <= 8'hFF;
            rgb_green <= 8'hFF;
            rgb_blue  <= 8'hFF;
        end else begin
            // 背景色 (黒)
            rgb_red   <= 8'h00;
            rgb_green <= 8'h00;
            rgb_blue  <= 8'h00;
        end
    end

endmodule
```

## 🛠️ 実習3: VRAM システム

```systemverilog
module vram_system (
    input  logic clk,
    input  logic rst_n,

    // CPU側アクセス
    input  logic [15:0] cpu_addr,
    input  logic [7:0]  cpu_data_in,
    output logic [7:0]  cpu_data_out,
    input  logic        cpu_write,
    input  logic        cpu_read,

    // LCD側アクセス
    input  logic [9:0]  lcd_addr,
    output logic [7:0]  lcd_data,

    // 特殊制御 (カスタム命令用)
    input  logic        clear_vram  // CVR命令
);

    // VRAM メモリ (1KB)
    logic [7:0] vram_memory [0:1023];

    // CPU側アクセス処理
    logic vram_access;
    logic [9:0] cpu_vram_addr;

    always_comb begin
        // VRAM アクセス判定 (0xE000-0xE3FF)
        vram_access = (cpu_addr >= 16'hE000) && (cpu_addr <= 16'hE3FF);
        cpu_vram_addr = cpu_addr[9:0];
    end

    // CPU書き込み処理
    always_ff @(posedge clk) begin
        if (cpu_write && vram_access) begin
            vram_memory[cpu_vram_addr] <= cpu_data_in;
        end else if (clear_vram) begin
            // CVR命令: 全VRAM クリア
            for (int i = 0; i < 1024; i++) begin
                vram_memory[i] <= 8'h20;  // スペース文字
            end
        end
    end

    // CPU読み出し処理 (シャドウRAM: 0x7C00-0x7FFF)
    always_comb begin
        if (cpu_read && ((cpu_addr >= 16'h7C00 && cpu_addr <= 16'h7FFF) ||
                         (cpu_addr >= 16'hE000 && cpu_addr <= 16'hE3FF))) begin
            cpu_data_out = vram_memory[cpu_vram_addr];
        end else begin
            cpu_data_out = 8'h00;
        end
    end

    // LCD側読み出し (常時アクセス可能)
    assign lcd_data = vram_memory[lcd_addr];

endmodule
```

## 🛠️ 実習4: フォントROM

```systemverilog
module font_rom (
    input  logic clk,
    input  logic [11:0] addr,  // 4KB アドレス
    output logic [7:0]  data
);

    // フォントデータ (Sweet16Font ベース)
    logic [7:0] font_memory [0:4095];

    // フォントデータの初期化
    initial begin
        $readmemh("font_data.hex", font_memory);
    end

    // 読み出し
    always_ff @(posedge clk) begin
        data <= font_memory[addr];
    end

endmodule
```

## 🛠️ 実習5: システム統合

```systemverilog
module lcd_cpu_system (
    input  logic clk_27mhz,    // 27MHz入力クロック
    input  logic rst_n,

    // LCD出力
    output logic lcd_clk,
    output logic lcd_hsync,
    output logic lcd_vsync,
    output logic lcd_de,
    output logic [7:0] lcd_red,
    output logic [7:0] lcd_green,
    output logic [7:0] lcd_blue,

    // メモリインターフェース
    output logic [15:0] mem_addr,
    output logic [7:0]  mem_data_out,
    input  logic [7:0]  mem_data_in,
    output logic        mem_read,
    output logic        mem_write
);

    // PLL: 27MHz → 9MHz ピクセルクロック
    logic clk_pixel;
    logic pll_locked;

    pll_27_to_9 pll_inst (
        .clk_in(clk_27mhz),
        .clk_out(clk_pixel),
        .locked(pll_locked)
    );

    // LCD タイミング制御
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

    // VRAM システム
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

    // フォントROM
    logic [11:0] font_addr;
    logic [7:0] font_data;

    font_rom font_inst (
        .clk(clk_pixel),
        .addr(font_addr),
        .data(font_data)
    );

    // 文字表示制御
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

    // LCD出力
    assign lcd_clk = clk_pixel;
    assign lcd_hsync = hsync;
    assign lcd_vsync = vsync;
    assign lcd_de = de;

endmodule
```

## 📝 課題

### 基礎課題
1. スクロール表示機能の実装
2. カラー表示対応 (文字色/背景色)
3. カーソル表示機能

### 発展課題
1. グラフィックモードの実装
2. スプライト機能
3. ハードウェアスクロール

## 📚 今日学んだこと

- [ ] LCD タイミング制御の実装
- [ ] 文字表示システムの設計
- [ ] VRAM の二重アクセス制御
- [ ] フォントROM の使用方法
- [ ] システム全体の統合

## 🎯 明日の予習

Day 10では最終日として、アセンブリプログラミングと応用を学習します:
- cc65 アセンブラの使用方法
- カスタム命令の活用
- 実用的なプログラム作成