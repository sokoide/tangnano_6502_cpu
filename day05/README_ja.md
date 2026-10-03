# Day 05: プログラムカウンタ・リセット・実行許可

[English](README.md) | [日本語](README_ja.md)

## この日の到達点

`cpu.sv` に16bitのPCを作る。リセットで `$0200` に戻し、`pc_enable=1` のクロックで
1だけ進める。`pc_enable=0` なら保持する。`address_bus` と `debug_pc` に同じPCを出力する。
この段階では命令を解読しない。PCを進める動作は、後の命令fetchを作る準備である。

## Step by Step

1. `cpu.sv` のPCを順序回路として実装する。非同期・active-lowリセットを確認する。
2. 実行許可のある立上りでだけPCを更新する。加算は16bitでwrapする。
3. `make test-cpu` を実行し、リセット値・2回のincrement・停止中の保持を検査する。
4. `make sim` を実行する。CPUテストに加えてLCDのsmoke testも実行される。
5. `make BOARD=9k` または `make BOARD=20k` でビルドする。実機では表示用の遅い
   enableに従ってPCが進む。今回のシミュレーション成功だけで実機を確認したとは扱わない。

starterのTODOを実装する前はCPUテストが失敗する。完成例は同じテストを
`day05_completed/cpu.sv` に接続する。リセット後は `$0200 → $0201 → $0202` が期待値である。
LCDにあるA/X/Y/P/SPの欄はこのCPUのレジスタファイルを検査するものではない。

## 追加練習: レジスタファイル

[`day05/cpu_registers.sv`](../day05/cpu_registers.sv) はA/X/Y/SP/Pを保持する独立した追加課題。
現行CPUやLCDには接続しておらず、このDayのcompletedにも解答・単体テストは含めていない。
CPUテストの合格を、この追加課題の合格として数えない。
レジスタのリセット・write enable・保持を自分の単体テストで確かめる練習に使う。

## 次のDay

Day 06でAレジスタと `LDA #imm` のopcode/operand fetchを加える。
RAM・Zero Page・stackはDay 10から導入する。Day 04–09の命令供給はROMである。
