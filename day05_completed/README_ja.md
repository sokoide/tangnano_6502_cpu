# Day 05: プログラムカウンタ・リセット・実行許可

[English](README.md) | [日本語](README_ja.md)

## この日の到達点

`cpu.sv` に 16bit の PC を作る。リセットで `$0200` に戻し、`pc_enable=1` のクロックで
1 だけ進める。`pc_enable=0` なら保持する。`address_bus` と `debug_pc` に同じ PC を出力する。
この段階では命令を解読しない。PC を進める動作は、後の命令 fetch を作る準備である。

## Step by Step

1. `cpu.sv` の PC を順序回路として実装する。非同期・active-low リセットを確認する。
2. 実行許可のある立上りでだけ PC を更新する。加算は 16bit で wrap する。
3. `make test-cpu` を実行し、リセット値・2 回の increment・停止中の保持を検査する。
4. `make sim` で CPU テストに加えて LCD smoke test も実行する。
5. `make BOARD=9k` または `make BOARD=20k` でビルドする。実機では表示用の遅い
   enable に従って PC が進む。今回のシミュレーション成功だけで実機を確認したとは扱わない。

starter の TODO を実装する前は CPU テストが失敗する。完成例は同じテストを
`day05_completed/cpu.sv` に接続する。リセット後は `$0200 → $0201 → $0202` が期待値である。
LCD にある A/X/Y/P/SP の欄はこの CPU のレジスタファイルを検査するものではない。

## 追加練習: レジスタファイル

[`day05/cpu_registers.sv`](../day05/cpu_registers.sv)は A/X/Y/SP/P を保持する独立した追加課題。
現行 CPU や LCD には接続しておらず、この Day の completed にも解答・単体テストは含めていない。
CPU テストの合格を、この追加課題の合格として数えない。
レジスタのリセット・write enable・保持を自分の単体テストで確かめる練習に使う。

## 次のDay

Day 06 で A レジスタと `LDA #imm` の opcode/operand fetch を加える。
RAM・Zero Page・stack は Day 10 から導入する。Day 04–09 の命令供給は ROM である。
