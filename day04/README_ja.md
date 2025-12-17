# Day 04: LCDパイプラインプレビュー

---

🌐 対応言語:
[English](./README.md) | [日本語](./README_ja.md)

## 🎯 本日のフォーカス

Day 04 では LCD 表示パイプラインを体験します。

- 9 MHz のピクセルクロックを作る PLL（`Gowin_rPLL9`）の仕組みを見る
- VRAM → フォント ROM → LCD のレンダリングの流れを追う
- `top_9k.sv` / `top_20k.sv` を使って TFT パネルを直接ドライブする方法を確認する

## 🌲 day04_completed/ 以下の主要ファイル

- `top_9k.sv` / `top_20k.sv`：ボード専用ラッパー。リセット/クロックと TFT 信号を繋ぐ
- `lcd_demo.sv`：`Gowin_rPLL9` → `lcd.v` → `font_rom.v` → `vram.v` を連結した軽量トップ
- `lcd/`：LCD表示 RTL（`lcd.sv`、`vram.sv`、`font_rom.sv`、`tb_tft.sv`）
- `include/consts.svh`：480×272 テキスト表示のタイミング定数
- `gowin_rpll_9k/` / `gowin_rpll_20k/`：9MHz クロック用の PLL モジュール
- `tang_nano_9k.cst` / `tang_nano_20k.cst`：RGB、DEN、CLK、XTAL、ResetButton を割り当てた制約

## 🛠️ ビルド/書き込み手順

1. GoWin で対象ボード用プロジェクト（`day04_completed/hw_9k.gprj` など）を開く。
2. `top_9k.sv` / `top_20k.sv` をトップモジュールに設定し、上記 RTL を読み込む。
3. LCD ピン割り当て済み制約を使う（`clk` や `led` は不要）。
4. 通常どおり Synthesis → Place & Route → Generate .fs。
5. `programmer_cli` で `*.fs` をダウンロードすれば TFT にテキストが表示される。

## 🧪 シミュレーション

以下のコマンド例で Verilator シミュレーションが可能です（`day04_completed/sim/tb_tft.sv` などを使います）。

```bash
cd day04_completed
verilator -Wall --sv --trace -cc lcd/tb_tft.sv lcd/lcd.sv lcd/vram.sv lcd/font_rom.sv sim/Gowin_rPLL9_stub.sv --exe -o Vtb_tft
```

テストベンチは `LCD_DEN` が立ち、非黒ピクセルが出ることを確認します。

## 💡 学びのメモ

- `vram.sv` が VRAM 上の文字コードを提供し、`font_rom.sv` がビットマップへ変換。
- `lcd.sv` がキャラクタタイミングを正確に制御して TFT へピクセルを送出。
- 先に表示パイプラインを実際の LCD で確認することで、後続の CPU/メモリ統合がイメージしやすくなります。

次回（Day 05～）は CPU アーキテクチャに移りますが、今日だけは LCD をじっくり観察する日です。
