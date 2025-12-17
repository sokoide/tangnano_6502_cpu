# Day 10: 6502 アセンブリ演習 完成版

このディレクトリには `day10/README_ja.md`/`day10/README.md` に記載された 6502 アセンブリ演習の完成版が格納されています。cc65 ツールチェーンを使い、Tang Nano のカスタム命令やLCD制御を駆使した実用的なデモを用意しました。

## 収録物
- `hello_world.s`: `CVR` でVRAMをクリアしたあと文字列を並べ、`HLT` で停止します。
- `counter_display.s`: 16進カウンタ＋簡易アニメーションを指定行に表示します。
- `scroll_text.s`: 長いメッセージをスクロール表示しながら1行を消去・ディレイします。
- `build.cfg`: RAM / ZP / VRAM マップを定義する ld65 リンカ設定ファイル。
- `Makefile`: すべてのサンプルをビルドし、Intel HEXへ変換し、`hex_to_sv.py` を使って `include/boot_program.sv` を生成します。
- `hex_to_sv.py`: HEXファイルを読み込み、SystemVerilogの `boot_memory` 書き込み文を生成します。
- `include/boot_program.sv`: デフォルトの `hello_world` を元に生成されたブートROM。別プログラムに切り替えたら `make include` で再生成してください。

## ビルド
### 必要なツール
`ca65`/`ld65`（cc65）、および `srec_cat` をインストールしてください。macOSなら `brew install cc65 srecord` で揃います。

### 全サンプルをまとめてビルド
```bash
cd day10_completed
make
```
`build.cfg` をもとに `.o` → `.bin` → `.hex` と順に生成します（`hello_world`/`counter_display`/`scroll_text`）。

### 単体ビルド
```bash
make PROGRAM=scroll_text
```
`PROGRAM`変数でビルド対象を切り替えられます。

## ブートROM生成
デフォルトは `hello_world` なので、単純に `make include` で `include/boot_program.sv` が更新されます。
```bash
make include
```
他のプログラムをROMにしたいときは `BOOT_PROGRAM` を渡します。
```bash
make include BOOT_PROGRAM=counter_display
```
`hex_to_sv.py` が `.hex` に含まれる非ゼロバイトを読み取り、`initial begin ... end` の中で `boot_memory` に書き込む文を出力します。

## SystemVerilogプロジェクトへの組み込み
生成された `include/boot_program.sv` を `boot_memory` を持つトップモジュールに繋ぎ、CPUのリセットベクタが `$0200` を参照するようにすれば、スクロールやカウンタが実機で動きます。`include/boot_program.sv` は実際に書き込まれるVRAMへの文字レイアウトが分かるため、デバッグにも役立ちます。

## 備考
- 各デモは最後に `HLT` (`.byte $EF`) を実行するため、ループしない状態で停止します。
- `counter_display.s` / `scroll_text.s` はゼロページ `$80`〜`$83` を一時変数に使っています。
- `srec_cat` は `$0200` からのロードを想定して `.hex` のオフセットも調整します。
- `make clean` で `.o`/`.bin`/`.hex` と `include/boot_program.sv` をすべて削除できます（再生成には `make include` を再実行）。

## FPGAビルド＆書き込み
Day10 のハードウェア例はC6: Day04～Day08 の 6502 CPU スタック＋Day07 風メモリコントローラ（ `$E000～$E3FF` の VRAM 書き込みを Day09 の VRAM/LCD パイプラインに渡す）＋生成済み `include/boot_program.sv` を読み込む `boot_rom` を内包し、これだけで TFT にアセンブリデモを描画できます。

ビットストリームの生成と書き込みは以下のコマンドで行います。

```bash
make build BOARD=9k
make download BOARD=20k
```

`build`/`download` は `hw_9k.gprj`/`hw_20k.gprj` を開き、`top_9k.sv`/`top_20k.sv` から LCD + CPU + `boot_rom` を合成します。`boot_rom` は `include/boot_program.sv` のデータを ROM に展開するので、発行した `.hex` と `hex_to_sv.py` で生成した ROM がそのまま CPU にロードされます。また、VRAM データは CPU 側と LCD 側で `vram.sv` によって共有され、LCD に直接表示されます。

ソフトウェアをビルドしたあと、`include/boot_program.sv` を必ず生成してからこれらのターゲットを実行してください。`make test` は Verilator の `tb_tft.sv` シミュレーションで `test` コマンドを立ち上げて色の付いたピクセルが出ることを確かめるものです。

```bash
make test BOARD=9k
```

`make build/download/test` を実行するためには `gw_sh`、`programmer_cli`、`verilator` が `PATH` にある必要があります。
