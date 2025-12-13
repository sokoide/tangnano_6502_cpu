# Tang Nano 9K/20K ボード設定（実機優先）

この教材は **Tang Nano 9K** と **Tang Nano 20K** の両方をサポートします。FPGA初心者が最初につまずきやすいのは、「HDLは同じでも **デバイス/制約(.cst)/リセット極性** がボードで変わる」点です。

## ボード選択

- Tang Nano **9K**
  - Device: `GW1NR-9C`
  - ピン配置（クロック/LED 等）が 20K と異なる（各dayの `.cst` を参照）
- Tang Nano **20K**
  - Device: `GW2AR-18C`

多くの完成版プロジェクトは次で切り替えできます：

```bash
make BOARD=9k   # デフォルト
make BOARD=20k
```

## 必要ツール

- Gowin EDA
  - `gw_sh`（バッチビルド）
  - `programmer_cli`（書き込み）
- あると便利
  - `gtkwave`（波形ビューア）
  - `verilator`（lint。Makefile対応している場合）

### macOS のツールパス

Gowin EDA をアプリとして入れている場合、`gw_sh` / `programmer_cli` が `PATH` に無いことがあります。その場合は `make` にパスを渡します：

```bash
make GWSH=/Applications/GowinIDE.app/Contents/Resources/Gowin_EDA/IDE/bin/gw_sh \
     PRG=/Applications/GowinIDE.app/Contents/Resources/Gowin_EDA/Programmer/bin/programmer_cli \
     download
```

## Day 01 の「成功条件」

Day 01（LEDチカチカ）は実機の健全性チェックです：

- ビルドが通る（synth/pnr エラー無し）
- 書き込みが通る（programmer がデバイスを認識し SRAM に書ける）
- LED が目視できる速度で点滅する

Day 01 が不安定なまま Day 02 以降へ進むと、原因切り分けが急激に難しくなるので、まずここを確実に通すのがおすすめです。
