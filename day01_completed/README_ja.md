# Day 01 Completed: LED Blink Project

Tang Nano FPGA用のシンプルなLEDチカチカプロジェクトの完成版です。

## ファイル構成

- `top.sv` - メインモジュール (LED点滅制御)
- `tang_nano_9k.cst` - Tang Nano 9K用ピン制約
- `tang_nano_20k.cst` - Tang Nano 20K用ピン制約
- `led_blink.gprj` - GoWin EDAプロジェクトファイル
- `Makefile` - ビルド自動化

## 機能

- 27MHzクロックを25bitカウンタで分周
- 約0.8Hz (約1.25秒間隔) でLED点滅
- Tang Nano 9K/20K 両対応

## ビルド方法

### Tang Nano 9K の場合
```bash
make BOARD=9k download
```

### Tang Nano 20K の場合
```bash
make BOARD=20k download
```

## 動作確認

プログラム後、ボード上のLEDが約1.25秒間隔で点滅することを確認してください。

## 学習ポイント

1. **SystemVerilogの基本構文**
   - モジュール定義
   - always_ff文によるクロック同期回路
   - assign文による組み合わせ回路

2. **クロック分周**
   - カウンタによる分周回路
   - ビット幅の計算 (27MHz / 2^25 ≈ 0.8Hz)

3. **FPGA開発フロー**
   - 合成 (Synthesis)
   - 配置配線 (Place & Route)
   - ビットストリーム生成
   - プログラミング

4. **制約ファイル**
   - ピン配置の指定
   - 電気的特性の設定