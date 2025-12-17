# Day 09: VRAM文字表示システム

この完成版プロジェクトでは、`day09/README_ja.md` で説明されている文字表示＋VRAMアーキテクチャを実装しています。LCDのテキストバッファに事前に文字コードを書き込み、フォントROMを参照しながら 480×272 RGB TFT に文字列を出力します。

## 構成
- `hw_9k.*`, `hw_20k.*`: Tang Nano 9K/20K 向けの Gowin プロジェクトファイル（`top` モジュールをトップに設定）。
- `top_9k.sv`, `top_20k.sv`: ボード固有のリセット極性と表示出力を握るラッパーモジュール。
- `top_core.sv`: 9MHz の PLL、`lcd` テキスト描画、フォントROM、VRAMバッファをまとめたモジュール。
- `lcd.sv`: Day 99 から持ってきた文字表示コントローラ。VRAM からコードを取り出し、フォントROM でピクセルを生成する。
- `vram.sv`: 「VRAM TEXT / CHAR LCD / FPGA SHOW」というメッセージで初期化された 1KB VRAM。`lcd` のリードアドレスに同期して値を返す。
- `font_rom.sv`: デモで使うアルファベットだけを定義したフォントROM。
- `sim/tb_tft.sv`: LCD_DEN が立ち、黒以外のピクセルが出力されることをチェックするシミュレーションベンチ。

## FPGAビルド
```bash
cd day09_completed
make BOARD=9k
make BOARD=20k
```
`Makefile` は `day08_completed/Makefile` と同じ構成で、`gw_sh`/`programmer_cli` を探し、`hw_*.gprj` を開いて `.fs` ファイルを生成します。Gowin GUI からプロジェクトを開くときも `top` モジュールがトップとして選ばれている必要があります。

## 書き込み
```bash
make download BOARD=9k
```
`programmer_cli` を使って SRAM にビットストリームを書き込みます。Gowin ツールチェーンが `PATH` に入っていることを確認してください。

## シミュレーション
```bash
make sim BOARD=9k
```
Verilator による `tb_tft.sv` シミュレーションを実行します。文字列が描画されると `LCD_DEN` が立ち、RGB 出力が黒ではなくなるはずです。

## 備考
- `lcd.sv` は VRAM（$E000）上の文字コードを取り出し、フォントROM で文字のピクセルを生成する構造になっています。
- `vram.sv` は文字列を先読みしており、CPU が無くても画面にテキストが表示されます。
- `font_rom.sv` にはデモで使う文字しか入っておらず、その他のコードは空白として描画されます。
