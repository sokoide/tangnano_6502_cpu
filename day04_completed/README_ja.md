# Day 04 Completed: 6502 CPU Architecture Overview

6502 CPUの基本アーキテクチャとレジスタセットの完成版実装です。

## ファイル構成

- `cpu_registers.sv` - 6502レジスタセット
- `simple_decoder.sv` - 基本命令デコーダ
- `flag_calculator.sv` - フラグ計算ユニット
- `top.sv` - 統合テストモジュール
- `tb_cpu_registers.sv` - レジスタテストベンチ
- `Makefile` - ビルド・テスト自動化

## 実装モジュール

### 1. CPU レジスタセット
**8bitレジスタ:**
- A (Accumulator): 演算の主役
- X, Y (Index): インデックス用
- SP (Stack Pointer): スタック位置管理
- P (Processor Status): フラグレジスタ

**16bitレジスタ:**
- PC (Program Counter): 次の命令アドレス

**初期化値:**
- A, X, Y: 0x00
- SP: 0xFF (スタック最上位)
- PC: 0x0200 (プログラム開始)
- P: 0x20 (割り込み禁止)

### 2. 命令デコーダ
主要な命令分類:
- Load/Store命令 (LDA, STA等)
- Transfer命令 (TAX, TAY等)
- 演算命令 (ADC, SBC)
- 論理演算 (AND, ORA, EOR)
- シフト命令 (ASL, LSR, ROL, ROR)
- 分岐命令 (BEQ, BNE等)
- ジャンプ/サブルーチン (JMP, JSR, RTS)

### 3. フラグ計算ユニット
- N (Negative): 結果が負数
- Z (Zero): 結果がゼロ
- C (Carry): キャリー/ボロー
- V (Overflow): 符号付きオーバーフロー

## ビルド・テスト方法

### シミュレーションテスト
```bash
make test
```

### FPGAビルド
```bash
# Tang Nano 9K
make BOARD=9k download

# Tang Nano 20K
make BOARD=20k download
```

## テスト内容

レジスタテストベンチで以下をテスト:
1. リセット時の初期値確認
2. 各レジスタの個別書き込み
3. 同時書き込み動作
4. データ保持機能

## ハードウェア動作確認

### 入力
- `rst_n`: リセットボタン
- `switches[3:0]`: 命令選択とテスト制御

### 出力
- `debug_reg_a[7:0]`: Aレジスタ値
- `led_load`: ロード命令LED
- `led_store`: ストア命令LED
- `led_arithmetic`: 演算命令LED
- `led_branch`: 分岐命令LED

### 動作モード
1. **自動テストモード**: スイッチ[3]=0
   - 順次レジスタに値を書き込み
   - 命令デコードのデモ

2. **手動テストモード**: スイッチ[3]=1
   - スイッチ[2:0]で命令を選択
   - 対応するLEDが点灯

## 学習ポイント

### 6502アーキテクチャ
- シンプルなレジスタ構成
- メモリマップドI/O
- スタック固定領域
- フラグ駆動の条件分岐

### 実装技術
- マルチポートレジスタ設計
- 命令分類とデコード
- フラグ生成ロジック
- テストベンチ設計

### デバッグ手法
- レジスタ状態の可視化
- 命令分類の確認
- シミュレーションによる検証

## 発展課題

1. **アドレッシングモード判定**: 命令のアドレッシング方式識別
2. **命令長計算**: 各命令のバイト数計算
3. **不正命令処理**: 未定義オペコードの扱い

この基盤を使って、次のDayでより詳細な命令デコードとアドレッシングを学習します。