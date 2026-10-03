# GPT 6.1 Sol 独立レビュー: HEX変換 / 単体ALU

レビュー日: 2026-10-02。モデル: GPT 6.1 Sol。
対象: `day99_completed/utils/hex_fpga/{main.go,main_test.go,go.mod}` と
`day99_completed/src/cpu_alu.sv` の GLM-5.3 実装。
実装ファイルは変更せず、独立検証の一時ファイルを `/private/tmp` に作成した。
以下はレビュー時点の状態であり、GLM による追加修正後は再検証する。

## 修正が必要な指摘

### P2: type 04のrecord addressが非0でも受理される

`main.go` の type 04 分岐は payload 長と upper address を確認するが、
record address が `0x0000` であることを確認していない。
checksum が有効な次の不正入力を CLI が exit 0 で受理し、既存出力を置換した。

```text
:020001040000F9
:01020000EA13
:00000001FF
```

再現入力: `/private/tmp/hex-fpga-sol-review/bad-ela.hex`。
再現コマンド:

```sh
cd day99_completed/utils/hex_fpga
GOCACHE=/private/tmp/hex-fpga-sol-review-cache go run . \
  -hexfile /private/tmp/hex-fpga-sol-review/bad-ela.hex \
  -svfile /private/tmp/hex-fpga-sol-review/old.sv
```

推奨: type 04 で `rec.addr != 0` を拒否する。
非 0address と有効 checksum の fixture を追加し、失敗時の旧出力保持も確認する。

## テストの不足

- `main_test.go` の `TestConvertPreservesDestinationOnInvalidInput` は
  `good[:len(good)-1] + "00"` により奇数 hex 長を作る。
  checksum 検査より前に停止するため、checksum 不正時の旧出力保持試験にはならない。
  `-2`へ変更し、エラーが `checksum mismatch` を含むことも検査する。
- `TestCapacity` の超過ケースは 7905 bytes であり、コメントの「1 byte 超過」と一致しない。
  7681 bytes の境界試験を追加すると明確になる。独立 CLI 検証では 7681 bytes を正常に拒否した。
- repo の `src/tb_cpu_modules.sv` の既存 CMP 試験は N を確認せず、入力 C の両値も試さない。
  `A=$80, M=$00, C=0/1`、同値、負の差を永続的な回帰試験に追加する。
- GLM の `/private/tmp/alu_check/tb_alu_isolated.sv` は CMP の期待 N を
  `((a-b)>>7)` と 32bit のまま比較し、`a=0,b=1` で 33554431 と 1bit N を比較する。
  生成 binary はこの oracle 誤りで exit 1 となった。これを DUT の失敗として扱わない。
  SBC oracle も `~c` の式幅に依存するため、整数の `1-c` を明示するのが適切。

## 独立検証結果

### Go / HEX

```sh
cd day99_completed/utils/hex_fpga
GOCACHE=/private/tmp/hex-fpga-sol-review-cache go test -count=1 ./...
GOCACHE=/private/tmp/hex-fpga-sol-review-cache go build \
  -o /private/tmp/hex-fpga-sol-review/hex_fpga .
```

既存 Go tests 全件 pass、exit 0。
独立 CLI fixture は `/private/tmp/hex-fpga-sol-review/` に保存した。

| fixture | CLI結果 | 出力確認 |
| --- | --- | --- |
| `capacity-7680.hex` | exit 0 | 最大容量を受理 |
| `capacity-7681.hex` | exit 1 | 旧出力保持、temp残存なし |
| `checksum.hex` | exit 1 | 旧出力保持、temp残存なし |
| `duplicate-eof.hex` | exit 1 | 旧出力保持、temp残存なし |
| `rename.hex` → `destination-dir` | exit 1 | rename失敗後も既存dir内sentinel保持、temp残存なし |

type 04 の address 検証欠落以外に、容量・checksum・EOF・連続配置・atomic 置換の
実装上の不具合は今回のレビューでは見つからなかった。
電源断後の永続性や実 FPGA 上の動作はこの検証の対象外。

### 単体ALU

独立 oracle を `/private/tmp/alu-sol-review/tb_alu_sol.sv` に作成した。
CMP、ADC、SBC を各 `256 × 256 × 2`、合計**393216 vectors**実行し、
R/C/Z/N/V のすべてを確認した。8bit 切り詰めと `1-c` を oracle に明示した。

```sh
cd day99_completed
verilator --binary --timing --sv --top-module tb_alu_sol -Wno-fatal \
  -Iinclude -Isrc --Mdir /private/tmp/alu-sol-review/obj_dir \
  /private/tmp/alu-sol-review/tb_alu_sol.sv src/cpu_alu.sv \
  > /private/tmp/alu-sol-review/build.log 2>&1
/private/tmp/alu-sol-review/obj_dir/Vtb_alu_sol
```

ビルド log: `/private/tmp/alu-sol-review/build.log`。
実行結果: `PASS: CMP ADC SBC 393216 exhaustive vectors`、exit 0。
Verilator 5.052。ビルド warning は独立 harness 内の 1bit 値から integer への幅拡張。

CMP N を 8bit `A-M` から計算する修正は正しく、入力 C に依存しない。
ADC/SBC の二進演算にも今回の変更による回帰は見つからなかった。
単体 ALU が現在の CPU 実行経路に接続されていることや、decimal mode、実機動作を
証明する検証ではない。

## GLM追加修正後の再レビュー / ready判定

2026-10-02、GPT 6.1 Sol が final の `main.go/main_test.go` を再読し、再検証した。

- type 04 の `rec.addr != 0` 拒否と、checksum が有効な非 0address fixture 追加を確認。
  初回 P2 は解消した。
- checksum fixture が `good[:len(good)-2] + "00"` に修正され、
  `checksum mismatch` の assert も追加された。
- 容量超過 fixture が正確に 7681 bytes へ修正された。
- `GOCACHE=/private/tmp/hex-fpga-sol-review-cache go test -count=1 ./...` を再実行し、
  全件 pass、exit 0 (`ok hex_fpga 0.113s`)。
- final binary を `hex_fpga_final` として再 build し、初回の独立 fixture
  `bad-ela.hex` (`:020001040000F9`) を再実行した。
  CLI exit 1、`extended linear address record address must be 0x0000` を確認。
  `final-ela-old.sv` の旧内容が byte 単位で保持され、temp 残存もなかった。
  証拠 log: `/private/tmp/hex-fpga-sol-review/final-ela-review.log`。
- `docs/REVIEW_GLM_TOOLS_RESULT_ja.md` は 393216 vectors 検証の実施者を独立 Sol と
  明記しており、ALU 検証の帰属に誤りはない。
  「修正（3 点）」の見出しに 4 点を列挙している軽微な文書誤りは残る。

判定: **HEX変更はready**。今回レビュー範囲の blocking issue は解消した。
単体 ALU の既存独立 393216 vectors pass も維持して評価する。
repo に永続 CMP N 回帰 test を置く推奨と、実機/CPU 統合の未検証範囲は残る。
実装ファイルを編集せず、commit/push は実施していない。

## 永続ALU回帰TBの追加

2026-10-03、GPT 6.1 Sol が `day99_completed/src/tb_alu_regression.sv` を追加した。
整数の加減算と signed range overflow を oracle に使い、DUT の overflow bit 式を複製しない。
CMP/ADC/SBC の 393216 vectors を R/C/Z/N/V について検査し、assert 失敗を fatal へ伝播する。
500000ns の watchdog を持つ。Makefile 統合は親 agent 担当。

```sh
mkdir -p /private/tmp/alu-sol-permanent
cd day99_completed
verilator --binary --timing --assert --sv --top-module tb_alu_regression \
  -Wall -Wno-fatal -Iinclude -Isrc --Mdir /private/tmp/alu-sol-permanent/obj_dir \
  src/tb_alu_regression.sv src/cpu_alu.sv \
  > /private/tmp/alu-sol-permanent-build.log 2>&1
/private/tmp/alu-sol-permanent/obj_dir/Vtb_alu_regression \
  > /private/tmp/alu-sol-permanent-run.log 2>&1
```

build/run とも exit 0、`PASS: CMP/ADC/SBC ALU regression (393216 vectors)`。
初回 build は tmp 親 directory 未作成で失敗したため、mkdir 後に同 command を再実行して成功した。
GLM tools report の「修正 3 点」見出しも「4 点」へ訂正した。
