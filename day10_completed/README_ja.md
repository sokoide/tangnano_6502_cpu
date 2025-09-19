# Day 10: アセンブリプログラミング例

## 学習目標

Day 10では、完全な6502開発環境を構築し、実際のアセンブリプログラミング例を通して6502 CPUの能力を実証します。

### 今日学ぶこと

1. **実用的なアセンブリプログラミング**
   - 8つの異なるプログラム例
   - 6502命令セットの実践的使用
   - プログラミングパターンの理解

2. **プログラム選択システム**
   - 動的プログラム選択
   - 実行時間制御
   - システム状態管理

3. **高度なLCD表示**
   - 複数表示モード
   - リアルタイム情報更新
   - ユーザーインターフェース

4. **完全な開発環境**
   - 包括的なデバッグ機能
   - パフォーマンス監視
   - 教育的フィードバック

## 実装内容

### 1. Assembly Examples ROM (`assembly_examples.sv`)

8つのプログラム例を含むROM：

#### プログラム一覧

| No | アドレス | プログラム名 | 学習内容 |
|----|----------|--------------|----------|
| 0 | $C000 | Basic Arithmetic | 基本算術演算（加算・減算） |
| 1 | $C020 | Loop with Counter | ループ制御とカウンタ |
| 2 | $C040 | Data Manipulation | ビット操作とシフト演算 |
| 3 | $C060 | Subroutine with Stack | サブルーチンとスタック |
| 4 | $C080 | Array Processing | 配列処理とインデックス |
| 5 | $C0C0 | String Operations | 文字列処理 |
| 6 | $C0E0 | Math Functions | 数学関数（乗算） |
| 7 | $C100 | I/O Operations | I/O操作 |

#### プログラム詳細

**Program 0: Basic Arithmetic**
```assembly
    CLC          ; キャリークリア
    LDA #10      ; Aに10をロード
    ADC #5       ; 5を加算（A=15）
    STA $80      ; 結果を$80に保存
    ADC #20      ; 20を加算（A=35）
    STA $81      ; 結果を$81に保存
```

**Program 1: Loop with Counter**
```assembly
    LDA #0       ; カウンタ初期化
    STA $90      ; カウンタを$90に保存
loop:
    LDA $90      ; カウンタロード
    CLC
    ADC #1       ; インクリメント
    STA $90      ; 保存
    CMP #10      ; 10と比較
    BMI loop     ; 10未満なら継続
```

**Program 2: Data Manipulation**
```assembly
    LDA #$AA     ; ビットパターンロード
    AND #$F0     ; 上位ニブルマスク
    STA $A0      ; 保存
    LDA #$55     ; 別パターン
    AND #$0F     ; 下位ニブルマスク
    ORA $A0      ; 結合
    ASL A        ; 左シフト
```

### 2. Program Selector (`program_selector.sv`)

プログラム選択制御：

```systemverilog
// 機能
// - スイッチによるプログラム選択
// - スタートボタン制御
// - CPUリセット管理
// - 実行状態監視
```

特徴：
- 16種類のプログラムアドレス対応
- 自動リセットシーケンス
- 実行状態フィードバック

### 3. Enhanced LCD Display (`enhanced_lcd_display.sv`)

4つの表示モード：

#### モード0: CPUレジスタ表示
```
A:42 X:00 Y:AA
PC:C008 RUN
```

#### モード1: プログラム情報
```
PROG 0: ARITHMETIC
NV-BDIZC
```

#### モード2: システム状態
```
STATUS: 24
MODE: CPU REG
```

#### モード3: メモリビュー
```
MEMORY VIEW
[C008]=3F
```

### 4. Complete System (`top.sv`)

統合システム：
- CPU + メモリ + LCD + プログラム選択
- 可変CPUクロック制御
- 包括的デバッグ出力

## ハードウェア制御

### スイッチ機能

| スイッチ | 機能 | 説明 |
|----------|------|------|
| switches[3:0] | プログラム選択 | 0-7のプログラム選択 |
| switches[3:2] | 表示モード | LCD表示内容切り替え |
| switches[1:0] | CPU速度 | クロック分周比制御 |

### ボタン制御

- `program_start_btn`: プログラム開始/リセット

### CPU速度制御

| switches[1:0] | 速度 | 周波数 | 用途 |
|---------------|------|--------|------|
| 00 | 最低速 | 0.84MHz | ステップ実行観察 |
| 01 | 低速 | 1.69MHz | 詳細動作確認 |
| 10 | 中速 | 3.375MHz | 通常デバッグ |
| 11 | 高速 | 6.75MHz | 性能確認 |

### デバッグLED

| LED | 機能 | 説明 |
|-----|------|------|
| 0 | Heartbeat | システム動作確認（0.6Hz点滅） |
| 1 | Program Running | プログラム実行中表示 |
| 2 | LCD Ready | LCD操作準備完了 |
| 3 | Start Button | スタートボタン状態 |
| 7:4 | Current Program | 現在選択中のプログラム番号 |

## ビルドと実行

### 必要なファイル

```
day10_completed/
├── assembly_examples.sv     # アセンブリプログラムROM
├── program_selector.sv      # プログラム選択制御
├── enhanced_lcd_display.sv  # 高機能LCD制御
├── top.sv                   # 統合システム
├── tb_assembly_system.sv    # システムテストベンチ
├── Makefile                 # 完全ビルドシステム
└── README_ja.md             # この文書

依存関係:
├── day09_completed/ (LCD controller)
├── day08_completed/ (CPU core)
├── day07_completed/ (memory system)
├── day06_completed/ (ALU, decoder)
├── day05_completed/ (addressing modes)
└── day01-04_completed/ (基礎コンポーネント)
```

### ビルドコマンド

```bash
# Tang Nano 9K用完全ビルド
make tang_nano_9k

# Tang Nano 20K用完全ビルド
make tang_nano_20k

# 包括的シミュレーション
make run_sim

# FPGAプログラミング
make program_9k    # Tang Nano 9K
make program_20k   # Tang Nano 20K

# ドキュメント生成
make docs

# 制約ファイル生成
make constraints
```

### 動作確認手順

1. **システム初期化**
   ```
   - 電源投入
   - リセットボタン解除
   - LCD初期化完了確認（LED2点灯）
   ```

2. **プログラム選択**
   ```
   - switches[3:0]でプログラム選択（0-7）
   - LED7:4で選択プログラム確認
   ```

3. **プログラム実行**
   ```
   - program_start_btnを押下
   - LED1でプログラム実行確認
   - LCDでCPU状態監視
   ```

4. **表示モード切り替え**
   ```
   - switches[3:2]でモード選択
   - LCDで表示内容変化確認
   ```

## プログラミング学習

### 基本パターン

#### 1. 算術演算
```assembly
CLC          ; キャリフラグクリア
LDA #operand1
ADC #operand2  ; 加算
STA result    ; 結果保存
```

#### 2. ループ制御
```assembly
    LDA #init_value
loop:
    ; ループ本体
    CLC
    ADC #increment
    CMP #limit
    BCC loop      ; 継続条件
```

#### 3. ビット操作
```assembly
LDA data
AND #mask     ; ビットマスク
ORA #pattern  ; ビット設定
EOR #toggle   ; ビット反転
```

#### 4. サブルーチン
```assembly
    JSR subroutine  ; 呼び出し
    ; 復帰後の処理

subroutine:
    PHA            ; レジスタ保存
    ; サブルーチン本体
    PLA            ; レジスタ復帰
    RTS            ; 復帰
```

#### 5. 配列処理
```assembly
    LDY #0         ; インデックス初期化
loop:
    LDA data,Y     ; 配列要素ロード
    STA result,Y   ; 配列要素保存
    INY            ; インデックス増加
    CPY #size      ; サイズ比較
    BNE loop       ; 継続
```

### 高度なテクニック

#### 1. 条件分岐
```assembly
    LDA value
    CMP #threshold
    BCS greater_equal  ; value >= threshold
    ; value < threshold の処理
    JMP end
greater_equal:
    ; value >= threshold の処理
end:
```

#### 2. データテーブル
```assembly
    LDX index
    LDA table,X    ; テーブル参照

table:
    .byte $00, $01, $04, $09, $10  ; 平方数テーブル
```

#### 3. 文字列処理
```assembly
    LDY #0
string_loop:
    LDA source,Y
    BEQ string_end    ; null終端チェック
    STA dest,Y
    INY
    JMP string_loop
string_end:
    STA dest,Y        ; null終端もコピー
```

## デバッグとトラブルシューティング

### 一般的な問題

#### 1. プログラムが動かない
- **確認点**:
  - リセット信号（rst_n）
  - クロック供給
  - プログラム選択
  - スタートボタン操作

#### 2. 期待した結果にならない
- **デバッグ方法**:
  - LCD表示でレジスタ値確認
  - CPU速度を最低にして観察
  - ステップ実行での追跡

#### 3. LCD表示異常
- **対処法**:
  - 配線確認
  - 電源電圧確認
  - 初期化シーケンス確認

### シミュレーション活用

```bash
# 詳細シミュレーション実行
make run_sim

# 特定プログラムのテスト
# testbench内でprogram番号指定
```

## 応用とカスタマイズ

### プログラム追加

1. **assembly_examples.sv編集**:
   - 新しいプログラムアドレス追加
   - 機械語コード記述

2. **program_selector.sv更新**:
   - PROGRAM_ADDRESSES配列拡張

3. **enhanced_lcd_display.sv修正**:
   - PROGRAM_NAMES配列追加

### 表示カスタマイズ

```systemverilog
// カスタム表示例
// Line 1: "CUSTOM MODE"
// Line 2: "DATA: XXXX"
```

### 新機能追加

- **ブレークポイント**: 特定PC値で停止
- **メモリダンプ**: メモリ内容表示
- **実行統計**: 命令カウント表示
- **エラー検出**: 不正命令検出

## 学習成果

### 習得スキル

1. **6502アセンブリプログラミング**
   - 基本命令セット理解
   - プログラミングパターン習得
   - デバッグ技術向上

2. **システム設計**
   - ハードウェア/ソフトウェア統合
   - ユーザーインターフェース設計
   - リアルタイムシステム構築

3. **FPGA開発**
   - 大規模システム実装
   - 制約設計
   - 検証手法

### 実践的応用

- **組み込みシステム開発**
- **レトロコンピューティング**
- **教育用CPU設計**
- **プロトタイピング環境**

## 次のステップ

### 発展課題

1. **命令セット拡張**
   - 新しい命令追加
   - 拡張アドレッシングモード

2. **ペリフェラル追加**
   - タイマー/カウンタ
   - UART通信
   - SPI/I2Cインターフェース

3. **オペレーティングシステム**
   - シンプルなカーネル実装
   - タスクスケジューラ
   - デバイスドライバ

### 関連プロジェクト

- **8ビットコンピュータ完全再現**
- **Apple II / Commodore 64エミュレータ**
- **カスタムCPUアーキテクチャ設計**

## 参考資料

- 6502 Instruction Set Reference
- Assembly Language Programming Techniques
- Retro Computing Resources
- FPGA Design Best Practices
- SystemVerilog Advanced Topics

---

**完了！** 10日間の学習カリキュラムで、基本的なLED点滅から完全な6502 CPU開発環境まで構築できました。このシステムは、実際の6502プログラミング学習とFPGA開発の両方に活用できる実用的な教育ツールです。