# Day 06: 即値LDAと2段階のfetch

[English](README.md) | [日本語](README_ja.md)

## この日の到達点

`cpu.sv` のAレジスタと、opcode/operandを順に読む2状態FSMを実装する。
`A9 42` は `LDA #$42` であり、`$A9` は命令、`$42` はAへ入れるデータである。
現行completedはLDAとA/PCの更新を実装する。Z/Nフラグや独立decoder/flag moduleの
統合はこのDayのCPUには含めていない。CPUの演算フラグはDay 08で検査する。

## Step by Step

1. `cpu.sv` のリセットを実装する。PC=`$0200`、A=`$00`、状態はopcode fetchに戻す。
2. opcode fetchで `$A9` を認識し、PC/addressをoperandへ進める。
3. operand fetchで入力値をAへ保存し、次のopcodeへ進める。
4. starterのCPU interfaceに `pc_enable` 入力を追加する（completedには既にある）。
   `pc_enable=0` で状態を保持する。Day 04–09はROM読出しで、同期RAMの待ち時間はDay 10で導入する。
5. `make test-cpu` で複数の即値LDA、PC、停止中の保持を確認する。
   完成例は同じテストベンチへ完成CPUを接続しています。スターターは未実装部分があるため、実装前にテストが失敗しても正常です。
6. `make sim` でもLCD smokeを確認し、`make BOARD=9k` / `make BOARD=20k` でビルドする。
   LCDの表示だけでは命令やフラグの正しさを検証できない。

## メモリ上の例

| アドレス | バイト | 意味 |
| --- | --- | --- |
| `$0200` | `$A9` | LDA immediateのopcode |
| `$0201` | `$42` | Aへ保存するoperand |
| `$0202` | 次のopcode | LDA終了後のfetch先 |

## 追加練習: decoderとflag calculator

[`day06/simple_decoder.sv`](../day06/simple_decoder.sv) と
[`day06/flag_calculator.sv`](../day06/flag_calculator.sv) は独立した部品の追加課題。
現在のCPUは内部caseでLDAを認識し、この2部品をinstantiateしない。
completedにはこれらの独立課題の解答・単体テストを含めていないため、
`make test-cpu` の合格はこれらの完成を意味しない。
Z=`result == 0`、N=`result[7]` を単体検査し、C/Vは後のADC/SBCの仕様と区別する。

## 次のDay

Day 07でX/Yとレジスタ転送を加える。Day 08でADC/SBCとC/V/Z/Nの検証へ進む。
