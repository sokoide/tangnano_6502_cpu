# Day 04: 視覚化基盤 (LCD 表示とメモリマップ)

---

🌐 対応言語:
[English](./README.md) | [日本語](./README_ja.md)

## 📜 概要

Day 04 では、CPU 開発を強力にサポートする **「デバッグ・ダッシュボード」** として LCD 表示機能を構築しました。CPU が内部でどのような状態にあるかをリアルタイムで確認できる環境を整えることがこの日のゴールでした。

## 🧠 メモリ構成の注意

Day 04〜09 はプログラム命令を `rom.sv` から供給します（簡易 ROM）。Zero Page/Stack/Program RAM を含む RAM は Day 10 まで使用しません。

## 🎯 学習目標

- **LCD パイプライン**: ピクセルが VRAM (**BSRAM/SDPB**) から Font ROM (**pROM**) を経由してパネルへ流れる仕組みを理解する。
- **ハードウェアメモリ**: FPGA 内部リソースである BSRAM を利用した高速なメモリアクセスの基礎。
- **クロック管理**: PLL (Phase Locked Loop) を使用して、LCD 用の 9MHz などの正確な周波数を生成する。
- **メモリマップの理解**: CPU から見たアドレス空間の配置を理解する。
- **VRAM の操作**: メモリ上の特定の場所に文字コードを書くと、画面のどこに表示されるかを学ぶ。

## 🏗️ アーキテクチャ

Day 04 では、高速な描画パイプラインを構築しました。

```mermaid
graph TD
    subgraph "表示パス (Display Path)"
        LCD[LCD Controller] --> VRAM
        VRAM --> FR[Font ROM]
        FR --> LCD
    end
```

## 🛠️ 実装ステップ

### パート 1: LCD の駆動

1. **PLL の設定**: 27MHz のベースクロックから 9MHz のクロックを生成。
2. **タイミングジェネレータ**: `lcd.sv` で HSYNC/VSYNC/DEN 信号を作成。
3. **レンダリング**: `lcd_demo.sv` で `vram.sv` と `font_rom.sv` を配線。

### パート 2: LCD のみの統合

Day 04 の完成版は LCD 表示パイプラインの構築に集中しています。CPU レジスタやデコーダのデモ回路は後日登場します。

## 💡 補足：BSRAM (SDPB) と pROM の活用

FPGA 本体にあるロジック（LUT）だけでメモリを作ると、すぐにリソースが枯渇してしまいます。そのため、Tang Nano に搭載されている **BSRAM (Block Static RAM)** という専用のメモリブロックを利用します。

### 1. SDPB (Semi-Dual Port Block RAM)

VRAM として使用します。一方のポートで LCD が読み出しを行い、もう一方のポートで CPU（または初期化回路）が書き込みを行うため、情報の衝突を避けながら高速な描画が可能です。

### 2. pROM (Programmable ROM)

フォントデータを格納するために使用します。あらかじめ定義されたフォントパターンを電源投入時にロードします。

## 🏗️ メモリマップとデータフロー

文字が画面に表示されるまでのデータの流れと、メモリ内でのレイアウトを図解します。

### 実習で使用する 6502 システムのメモリマップ

| アドレス範囲 | 用途 | 説明 |
| :--- | :--- | :--- |
| `0x0000 - 0x00FF` | Zero Page | 高速 8bit アドレッシング, 256B |
| `0x0100 - 0x01FF` | Stack | ハードウェアスタック操作, 256B |
| `0x0200 - 0x7BFF` | Program RAM | メインメモリ (プログラム/データ), 30.5KB |
| `0x7C00 - 0x7FFF` | Shadow VRAM | CPU 読み取り用 VRAM (シャドウ領域), 1KB |
| `0x8000 - 0xDFFF` | (Unmapped) | 将来の拡張用 |
| `0xE000 - 0xE3FF` | Text VRAM | LCD 表示用文字コード (ASCII), 1KB |
| `0xE400 - 0xFFFF` | (Unmapped) | 将来の拡張用 |

### VRAM の画面レイアウト

VRAM は 60 列 × 17 行のグリッド（計 1020 バイト）として管理されています。例えば、VRAM の開始アドレスを `0xE000` とすると、以下のようにマップされます。

- `0xE000`: 画面左上の文字コード (Column 0, Row 0)
- `0xE3FB`: 画面右下の文字コード (Column 59, Row 16)

```mermaid
graph TD
    subgraph "画面座標 (Screen Coordinates)"
        C["列 (Column) <br/> 0 - 59"]
        R["行 (Row) <br/> 0 - 16"]
    end
    C --> CALC["アドレス計算 <br/> 0xE000 + (Row * 60) + Column"]
    R --> CALC
    CALC --> VRAM["VRAM (SDPB) <br/> 1020バイト"]
    VRAM --> OUT["指定位置の <br/> ASCIIコード"]
```

## 💡 「可視化のアーキテクチャ」

ハードウェア開発では、コンソールに「print」することはできません。LCD コントローラを早期に構築することで、ハードウェアネイティブなデバッガを作成しました。明日以降、CPU の内部状態がこの画面に表示されることになります！
