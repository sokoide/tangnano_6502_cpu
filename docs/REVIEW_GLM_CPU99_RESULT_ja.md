# Day 99 CPU 回帰修正の実装結果（GLM-5.3 実施分）

- 実施日: 2026-10-02
- 実装モデル: GLM-5.3（Claude Code 上で実行）
- 対象: `day99_completed/src/cpu/cpu_fsm_next_pkg.sv` の既定3件（RTS / BCS / CMP・CPX・CPY）と新規回帰テストベンチ
- スコープ外（指示により未変更）: Makefile / docs 修正、boot オフバイワン（R06）、アドレス 15bit マスク混在（R07）、他 CPU / RAM / boot / LCD / 独立 ALU

## 実装内容

### 1. RTS (`$60`) 戻りアドレス組立修正（R04）

`calc_decode_control_flow_next` の RTS stage 2 で、従来は `cur.fetched_data + 1` を使っており
上位バイトが前命令の残骸（stale）だった。stage 2 時点で `fetched_data[15:8]` はまだ未更新のため:

```systemverilog
pc1 = {cur.dout_r, cur.fetched_data[7:0]} + 1'b1;
```

に変更し、stage 1 でラッチした下位バイトと今回読んだ `dout_r`（上位バイト）を +1 の前に結合する。
`& RAMW16` マスクは R07 の方針決定までそのまま残した。

### 2. BCS (`$B0`) 分岐ハンドラ追加（R05 の一部）

`calc_decode_branches_next` の case に `8'hB0: branch_taken = cur.flg_c;` を追加。
fetch 分類には既に列挙済みで実行 handler が無かったもの。

### 3. CMP / CPX / CPY のメモリ形式実装（R05 の一部）

`calc_decode_compare_next` を拡張。即値3種はヘルパー `complete_compare` に統一し、
fetch 分類（opcode メタデータ）に列挙済みのメモリ形式を実装した:

| opcode | 命令 | 実装方式 |
|---|---|---|
| `$C5` | CMP zp | `request_data_fetch` → `dout_r` で比較 |
| `$D5` | CMP zp,X | 8bit 加算で zp wrap |
| `$C1` | CMP (zp,X) | `fetched_data_bytes` 0..3 の多段（LDA `$A1` と同型） |
| `$D1` | CMP (zp),Y | 同上（LDA `$B1` と同型）、ポインタ+Y は 16bit wrap |
| `$E4` | CPX zp | CMP zp と同型 |
| `$C4` | CPY zp | 同上 |

比較 semantics: `C = (lhs >= operand)`（borrow なし）、`Z/N` は 8bit 差分、
ソースレジスタと `V` は保存、入力 `C` は不使用。
即値の absolute 形式（`$CD` 等）は fetch 分類自体に無いため本変更では追加していない。

## 回帰テスト `src/tb_cpu_regression.sv`（新規）

- DUT は実物 `src/cpu.sv`。RAM は TB 内の独立した 1 クロック同期モデル
  （`cea` 書込み、`adb` を毎エッジ読出 = アドレス呈示の次サイクルでデータ出力）。
- boot プログラムは生成物 `include/boot_program.sv` を使わず、TB 内蔵のハンドアセンブル
  286 バイト（org `$0200`）。各テストは番号を `$0500+i` にチェックポイントとして書き、
  flag 誤りは `$7BFE=$FF`、完了は `$7BFF=$A5` + HLT。
- 自己検査・有界（20,000 サイクルで watchdog `$fatal`）。`--assert` 指定。

テスト項目（12チェックポイント）:

| # | 内容 |
|---|---|
| 0 | CMP 即値の基本（C/Z/N） |
| 1 | CMP zp（一致 → C=1, Z=1） |
| 2 | CMP zp,X（`$F8+$10` の zp wrap → `$08`） |
| 3 | CMP (zp,X)（ptr `$40/$41` → `$0340`、C=0/N=1） |
| 4 | CMP (zp),Y（`$0300+Y` → `$0320`、C=1） |
| 5 | CPX zp |
| 6 | CPY zp（C=0/N=1） |
| 7 | BCS taken（SEC 後） |
| 8 | BCS not taken（CLC 後） |
| 9 | RTS 入れ子（JSR sub1 → JSR sub2 → RTS ×2） |
| 10 | RTS cross-page（JSR を `$02FD` に配置、push `$02FF`、RTS → `$0300`、$FF 桁上げ） |
| 11 | 入れ子内側の RTS 到達確認 |

## 検証コマンドと結果（day99_completed から）

```console
$ verilator --binary --timing --assert -Wno-fatal -Iinclude -Isrc \
    --Mdir build/glm-cpu-regression --top-module tb_cpu_regression \
    src/cpu.sv src/tb_cpu_regression.sv
$ ./build/glm-cpu-regression/Vtb_cpu_regression
[ok]   checkpoint 0..11 （全 12 件）
[PASS] tb_cpu_regression: all 12 checkpoints verified at t=28070
exit code: 0
```

### ネガティブコントロール（検出力確認）

バグを一時的に復元して同一テストベンチで失敗することを確認（確認後すべて復元・削除済み）:

| 復元したバグ | 結果 | exit code |
|---|---|---|
| RTS 組立を旧ロジックに戻す | checkpoint 9/10/11 FAIL + timeout watchdog | 1 |
| BCS handler を削除 | checkpoint 3 以降 FAIL + timeout（未処理命令で DECODE_EXECUTE 停留） | 1 |
| CMP zp handler を削除 | checkpoint 1 以降 FAIL + timeout | 1 |

## 既知の未解決事項（本スコープ外、Sol レビュー後の修正予定）

- R06: boot loader の長さ判定オフバイワン（`0..length` の 1 バイト超過書込み）。TB では
  末尾に NOP を置き影響を回避。R06 修正時は配列範囲外参照の防止も必要。
- R07: PC / 実効アドレス計算への `RAMW15/RAMW16` マスク混在。今回の修正は既存の
  マスク方針を踏襲（RTS の `& RAMW16`、(zp),Y の 16bit wrap は `$7FFF` 未満のアドレスでのみ検証）。
- PLP (`$28`)、CLD/SED、decimal ADC/SBC、CMP の absolute/indexed-absolute 形式（`$CD` `$DD` `$D9` `$EC` `$CC` 等、
  fetch 分類への追加から必要）は未実装のまま。
- 独立 `cpu_alu.sv` の CMP 仕様（入力 C 依存）は本件では触れていない（git status の
  `cpu_alu.sv` 変更は本セッション開始前のもの）。

## 変更ファイル

- `day99_completed/src/cpu/cpu_fsm_next_pkg.sv`（RTS 1 件、BCS 1 行、compare 関数拡張）
- `day99_completed/src/tb_cpu_regression.sv`（新規）
- 本レポート
