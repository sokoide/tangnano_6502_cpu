# Day 10: 480×272 RGB TFT 立ち上げ

---

🌐 Available languages:
[English](./README.md) | [日本語](./README_ja.md)

## このDayでやること

Day 10 でも `day99_completed` と同じ **480×272 RGB TFTパネル**（RGB565 + `LCD_DEN` + `LCD_CLK`）を使います。

まずは実機で表示経路の切り分けができるよう、**アニメーションするカラーバー**を表示します。

## ビルド＆書き込み

このプロジェクトでは、以下のコマンドでボードごとにTFTカラーバーをビルド＆書き込みします。

```bash
make BOARD=9k download
make BOARD=20k download
```

## シミュレーション（Verilator）

```bash
make test
```

`LCD_DEN` がアサートされ、RGB出力が一度でも非ゼロになることを確認するスモークテストです。シミュレーションではPLLはスタブ化されるため、`LCD_CLK` は実質 `XTAL_IN` と同じになります。

## 配線

`day99_completed` と同じ配線を使ってください：

- `LCD_CLK`, `LCD_DEN`
- `LCD_R[4:0]`, `LCD_G[5:0]`, `LCD_B[4:0]`

ピン割り当ては以下：

- `day10_completed/tft_9k.cst`
- `day10_completed/tft_20k.cst`

## ファイル構成

- `day10_completed/top.sv`（タイミング生成 + カラーバー）
- `day10_completed/tft_9k.gprj`, `day10_completed/tft_20k.gprj`
- `day10_completed/gowin_rpll_9k/gowin_rpll9.v`, `day10_completed/gowin_rpll_20k/gowin_rpll9.v`
