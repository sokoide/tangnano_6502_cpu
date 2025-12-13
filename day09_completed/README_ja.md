# Day 09: 480×272 RGB TFT 立ち上げ

---

🌐 Available languages:
[English](./README.md) | [日本語](./README_ja.md)

## このDayでやること

このDayは **480×272 RGB TFTパネル**（RGB565 + `LCD_DEN` + `LCD_CLK`）向けです。  
まずは実機で表示経路が生きていることを確認するため、**RGBカラーバー**を表示します。

## 480×272 LCD の基本仕様

- 解像度: 480×272
- インターフェース: RGB565（R=5bit, G=6bit, B=5bit）
- 制御: `LCD_DEN` + `LCD_CLK`（この例ではHS/VSは未使用）
- ピクセルクロック: 約9MHz（27MHzからPLLで生成）

## ビルド＆書き込み

このプロジェクトでは、以下のコマンドでボードごとにTFTデモをビルド＆書き込みします。

```bash
make BOARD=9k download
make BOARD=20k download
```

## シミュレーション（Verilator）

```bash
make sim
```

`LCD_DEN` がアサートされ、RGB出力が一度でも非ゼロになることを確認するスモークテストです。シミュレーションではPLLはスタブ化されるため、`LCD_CLK` は実質 `XTAL_IN` と同じになります。

## 配線

`day99_completed` と同じ配線を使ってください：
- `LCD_CLK`, `LCD_DEN`
- `LCD_R[4:0]`, `LCD_G[5:0]`, `LCD_B[4:0]`

ピン割り当ては以下：
- `day09_completed/tft_9k.cst`
- `day09_completed/tft_20k.cst`

## ファイル構成

- `day09_completed/top.sv`（タイミング生成 + カラーバー）
- `day09_completed/tft_9k.gprj`, `day09_completed/tft_20k.gprj`
- `day09_completed/gowin_rpll_9k/gowin_rpll9.v`, `day09_completed/gowin_rpll_20k/gowin_rpll9.v`
