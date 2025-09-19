# Day 10: アセンブリプログラミングと応用

## 🎯 学習目標

- cc65アセンブラツールチェーンの使用方法習得
- 6502アセンブリプログラミングの実践
- カスタム命令 (CVR, IFO, HLT, WVS) の活用
- 実用的なデモプログラムの作成

## 📚 理論学習

### cc65 ツールチェーン

**構成要素:**
- **ca65**: アセンブラ (6502アセンブリ → オブジェクトファイル)
- **ld65**: リンカ (オブジェクトファイル → 実行ファイル)
- **cc65**: Cコンパイラ (C言語 → アセンブリ)

**ファイル形式:**
- `.s`: アセンブリソースファイル
- `.o`: オブジェクトファイル
- `.bin`: バイナリファイル
- `.hex`: Intel HEXファイル

### 6502アセンブリ記法

**基本構文:**
```assembly
; コメント
LABEL:              ; ラベル定義
    INSTRUCTION     ; 命令 (インプライド)
    INSTRUCTION #$nn ; 即値
    INSTRUCTION $nn  ; ゼロページ
    INSTRUCTION $nnnn ; 絶対アドレス
```

**擬似命令:**
```assembly
.org $0200          ; アドレス設定
.byte $01, $02      ; バイトデータ
.word $1234         ; ワードデータ (リトルエンディアン)
.include "file.inc" ; ファイル読み込み
```

## 🛠️ 実習1: 基本的なプログラム

### Hello World プログラム

```assembly
; hello_world.s
; Tang Nano 6502 Hello World

.org $0200

START:
    ; カスタム命令でVRAMクリア
    .byte $CF           ; CVR - Clear VRAM

    ; "HELLO WORLD" を VRAM に書き込み
    LDX #$00            ; インデックス初期化

WRITE_LOOP:
    LDA MESSAGE,X       ; メッセージ読み込み
    BEQ DONE            ; 0なら終了
    STA $E000,X         ; VRAM に書き込み
    INX                 ; インデックス増加
    JMP WRITE_LOOP      ; ループ継続

DONE:
    .byte $EF           ; HLT - プログラム終了

MESSAGE:
    .byte "HELLO WORLD FROM TANG NANO!", $00

; ベクタテーブル (必要に応じて)
.org $FFFC
.word START             ; リセットベクタ
```

### ビルド設定ファイル (build.cfg)

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

## 🛠️ 実習2: カウンタとアニメーション

```assembly
; counter_display.s
; 数値カウンタとアニメーション表示

.org $0200

; 定数定義
VRAM_BASE = $E000
COUNTER_ADDR = $80

START:
    .byte $CF           ; CVR - VRAM クリア

    ; カウンタ初期化
    LDA #$00
    STA COUNTER_ADDR

MAIN_LOOP:
    ; カウンタ表示位置設定 (画面中央)
    LDX #30             ; X座標 (30文字目)
    LDY #8              ; Y座標 (8行目)

    ; VRAM アドレス計算: Y×60 + X
    ; Y×60 を計算 (Y×64 - Y×4 = Y×60)
    TYA                 ; A = Y
    ASL                 ; A = Y×2
    ASL                 ; A = Y×4
    STA $81             ; Y×4 を保存

    TYA                 ; A = Y
    ASL                 ; A = Y×2
    ASL                 ; A = Y×4
    ASL                 ; A = Y×8
    ASL                 ; A = Y×16
    ASL                 ; A = Y×32
    ASL                 ; A = Y×64
    SEC
    SBC $81             ; A = Y×64 - Y×4 = Y×60

    CLC
    ADC #30             ; A = Y×60 + X
    TAY                 ; Y = VRAM オフセット

    ; カウンタ値を表示
    LDA COUNTER_ADDR
    JSR DISPLAY_HEX

    ; ディレイ
    JSR DELAY

    ; カウンタ増加
    INC COUNTER_ADDR

    ; 255でリセット
    LDA COUNTER_ADDR
    CMP #$FF
    BNE MAIN_LOOP

    LDA #$00
    STA COUNTER_ADDR
    JMP MAIN_LOOP

; 16進数表示サブルーチン
; A: 表示する値, Y: VRAM オフセット
DISPLAY_HEX:
    PHA                 ; A を保存

    ; 上位4ビット
    LSR
    LSR
    LSR
    LSR
    JSR HEX_TO_ASCII
    STA VRAM_BASE,Y
    INY

    ; 下位4ビット
    PLA                 ; A を復元
    AND #$0F
    JSR HEX_TO_ASCII
    STA VRAM_BASE,Y

    RTS

; 4bit値をASCII文字に変換
; A: 0-15, 戻り値: ASCII文字
HEX_TO_ASCII:
    CMP #$0A
    BCC IS_DIGIT        ; < 10 なら数字
    ; A-F の場合
    SEC
    SBC #$0A
    CLC
    ADC #'A'
    RTS
IS_DIGIT:
    CLC
    ADC #'0'
    RTS

; ディレイルーチン
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

## 🛠️ 実習3: スクロールテキスト

```assembly
; scroll_text.s
; スクロールするテキスト表示

.org $0200

; 定数
VRAM_BASE = $E000
SCROLL_LINE = 8         ; スクロール行
SCROLL_SPEED = 10       ; スクロール速度

START:
    .byte $CF           ; VRAM クリア

    ; スクロール位置初期化
    LDA #$00
    STA SCROLL_POS

SCROLL_LOOP:
    ; 画面の指定行をクリア
    LDX #SCROLL_LINE
    JSR CLEAR_LINE

    ; スクロールテキスト表示
    JSR DISPLAY_SCROLL_TEXT

    ; スクロール待機
    LDX #SCROLL_SPEED
WAIT_LOOP:
    JSR DELAY
    DEX
    BNE WAIT_LOOP

    ; スクロール位置更新
    INC SCROLL_POS
    LDA SCROLL_POS
    CMP #MESSAGE_LENGTH
    BNE SCROLL_LOOP

    ; メッセージ終了、リセット
    LDA #$00
    STA SCROLL_POS
    JMP SCROLL_LOOP

; 指定行をクリア
; X: 行番号
CLEAR_LINE:
    ; VRAM行アドレス計算
    TXA
    JSR CALC_LINE_ADDR
    TAY

    ; 60文字分スペースで埋める
    LDX #60
    LDA #' '
CLEAR_LOOP:
    STA VRAM_BASE,Y
    INY
    DEX
    BNE CLEAR_LOOP
    RTS

; スクロールテキスト表示
DISPLAY_SCROLL_TEXT:
    ; 表示開始位置計算
    LDA #SCROLL_LINE
    JSR CALC_LINE_ADDR
    TAY

    ; メッセージ表示
    LDX SCROLL_POS
    LDA #0              ; 表示文字数カウンタ

DISPLAY_LOOP:
    LDA MESSAGE,X       ; メッセージ読み込み
    BEQ DISPLAY_DONE    ; 0なら終了
    STA VRAM_BASE,Y     ; VRAM に書き込み
    INY
    INX

    ; 画面幅チェック
    TYA
    AND #$3F            ; Y % 64 (実際は60だが簡略化)
    CMP #60
    BCC DISPLAY_LOOP

DISPLAY_DONE:
    RTS

; 行番号からVRAMオフセット計算
; A: 行番号, 戻り値: A = オフセット
CALC_LINE_ADDR:
    ; A×60 を計算
    STA $82             ; 行番号保存
    ASL                 ; A×2
    ASL                 ; A×4
    STA $83             ; A×4 保存

    LDA $82             ; 元の値
    ASL                 ; A×2
    ASL                 ; A×4
    ASL                 ; A×8
    ASL                 ; A×16
    ASL                 ; A×32
    ASL                 ; A×64
    SEC
    SBC $83             ; A×64 - A×4 = A×60
    RTS

DELAY:
    ; 簡易ディレイ
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

MESSAGE_LENGTH = * - MESSAGE - 1  ; メッセージ長計算

; カスタム命令デモ
CUSTOM_DEMO:
    .byte $DF           ; IFO - デバッグ情報表示
    .byte $FF           ; WVS - VSync 待機
    RTS
```

## 🛠️ 実習4: Makefile とビルドシステム

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

## 🛠️ 実習5: Python 変換スクリプト

```python
#!/usr/bin/env python3
# hex_to_sv.py
# Intel HEX to SystemVerilog memory initialization

import sys

def hex_to_sv(hex_file):
    """Intel HEX ファイルを SystemVerilog 形式に変換"""

    memory = [0] * 32768  # 32KB メモリ

    with open(hex_file, 'r') as f:
        for line in f:
            line = line.strip()
            if not line.startswith(':'):
                continue

            # Intel HEX パース
            byte_count = int(line[1:3], 16)
            address = int(line[3:7], 16)
            record_type = int(line[7:9], 16)

            if record_type == 0:  # データレコード
                for i in range(byte_count):
                    data_byte = int(line[9 + i*2:11 + i*2], 16)
                    if address + i < len(memory):
                        memory[address + i] = data_byte

    # SystemVerilog 出力生成
    print("// Auto-generated boot program")
    print("// Generated from:", hex_file)
    print()
    print("initial begin")

    # 非ゼロデータのみ出力
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

## 📝 課題

### 基礎課題
1. 電卓プログラム (簡単な演算)
2. デジタル時計表示
3. パターン生成器

### 発展課題
1. テトリス風パズルゲーム
2. UART通信プログラム
3. 音楽演奏プログラム

## 🔧 開発ワークフロー

### 1. プログラム作成
```bash
# アセンブリファイル編集
vim hello_world.s
```

### 2. ビルド
```bash
# ビルド実行
make hello

# SystemVerilog include ファイル生成
make include
```

### 3. FPGA書き込み
```bash
# プロジェクトディレクトリに戻る
cd ..

# FPGA ビルド & 書き込み
make download
```

## 📚 トラブルシューティング

### よくあるエラー
1. **アセンブルエラー**: 構文チェック、ラベル重複確認
2. **リンクエラー**: アドレス重複、サイズ超過確認
3. **実行エラー**: メモリマップ確認、無限ループチェック

### デバッグ技法
1. **IFO命令**: レジスタとメモリの状態確認
2. **段階的実行**: 小さな部分から段階的にテスト
3. **シミュレーション**: 実機前にテストベンチで確認

## 📚 今日学んだこと

- [ ] cc65ツールチェーンの使用方法
- [ ] 実用的なアセンブリプログラミング
- [ ] カスタム命令の効果的な活用
- [ ] ビルドシステムの構築
- [ ] デバッグとトラブルシューティング

## 🎓 コース完了！

おめでとうございます！10日間の学習を通じて以下を習得しました:

### 習得スキル
✅ **FPGA開発**: GoWin EDAによる基本的な開発フロー
✅ **SystemVerilog**: 中級レベルのHDL設計能力
✅ **CPU設計**: 6502アーキテクチャの完全な理解と実装
✅ **システム統合**: CPU、メモリ、I/Oの協調設計
✅ **実機開発**: 理論と実践を結ぶ実装能力

### 次のステップ
- より複雑なCPUアーキテクチャへの挑戦
- 独自のカスタム命令追加
- パフォーマンス最適化
- 他のFPGAプロジェクトへの応用

**素晴らしいFPGA開発の旅をお楽しみください！**