# Day 06: 即値LDAと2段階のfetch

[English](README.md) | [日本語](README_ja.md)

## 実習の見取り図

この Day のスターターで編集します。

| 項目           | 内容                              |
| -------------- | --------------------------------- |
| 編集する箇所   | cpu.svのopcode/operand fetch TODO |
| 提供済みの前提 | PC、A、pc_enableとLCD配線         |
| テストの期待値 | 即値LDA後のA/PC、enable=0で保持   |
| 実機で見るもの | ROMのLDA後A=$42、以降はNOP        |

## この日の到達点

`cpu.sv` の A レジスタと、opcode/operand を順に読む 2 状態 FSM を実装する。
`A9 42` は `LDA #$42` であり、`$A9` は命令、`$42` は A へ入れるデータである。
現行 completed は LDA と A/PC の更新を実装する。Z/N フラグや独立 decoder/flag module の
統合はこの Day の CPU には含めていない。CPU の演算フラグは Day 08 で検査する。

## Step by Step

1. `cpu.sv` のリセットを実装する。PC=`$0200`、A=`$00`、状態は opcode fetch に戻す。
2. opcode fetch で `$A9` を認識し、PC/address を operand へ進める。
3. operand fetch で入力値を A へ保存し、次の opcode へ進める。
4. 既存の `pc_enable` 入力で FSM の更新を制御する。
   `pc_enable=0` で状態を保持する。Day 04–09 は ROM 読出しで、同期 RAM の待ち時間は Day 10 で導入する。
5. `make test-cpu` で複数の即値 LDA、PC、停止中の保持を確認する。
   完成例は同じテストベンチへ完成 CPU を接続しています。スターターは未実装部分があるため、実装前にテストが失敗しても正常です。
6. `make sim` でも LCD smoke を確認し、`make BOARD=9k` / `make BOARD=20k` でビルドする。
   LCD の表示だけでは命令やフラグの正しさを検証できない。

## メモリ上の例

| アドレス | バイト     | 意味                  |
| -------- | ---------- | --------------------- |
| `$0200`  | `$A9`      | LDA immediateのopcode |
| `$0201`  | `$42`      | Aへ保存するoperand    |
| `$0202`  | 次のopcode | LDA終了後のfetch先    |

## 追加練習: decoderとflag calculator

[`day06/simple_decoder.sv`](../day06/simple_decoder.sv)と
[`day06/flag_calculator.sv`](../day06/flag_calculator.sv)は独立した部品の追加課題。
現在の CPU は内部 case で LDA を認識し、この 2 部品を instantiate しない。
completed にはこれらの独立課題の解答・単体テストを含めていないため、
`make test-cpu` の合格はこれらの完成を意味しない。
Z=`result == 0`、N=`result[7]` を単体検査し、C/V は後の ADC/SBC の仕様と区別する。

## 次のDay

Day 07 で X/Y とレジスタ転送を加える。Day 08 で ADC/SBC と C/V/Z/N の検証へ進む。

CPU 単体テストと実機 ROM は別の入力です。表の実機期待値は `rom.sv` / LCD 配線から読み取った値であり、全ボードでの実機確認済みという意味ではありません。

LCD の VSync は表示書込みクロックへ 2 段同期し、立上りでフレーム更新を開始します。VRAM 読出しと font 読出しは画素クロック内で処理します。
