# GPT 6.1 Sol 独立レビュー: HEX変換 / 単体ALU

レビュー日: 2026-10-02。モデル: GPT 6.1 Sol。
対象: `day99_completed/utils/hex_fpga/{main.go,main_test.go,go.mod}` と
`day99_completed/src/cpu_alu.sv` のGLM-5.3実装。
実装ファイルは変更せず、独立検証の一時ファイルを `/private/tmp` に作成した。
以下はレビュー時点の状態であり、GLMによる追加修正後は再検証する。

## 修正が必要な指摘

### P2: type 04のrecord addressが非0でも受理される

`main.go` の type 04 分岐はpayload長とupper addressを確認するが、
record addressが `0x0000` であることを確認していない。
checksumが有効な次の不正入力をCLIがexit 0で受理し、既存出力を置換した。

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

推奨: type 04で `rec.addr != 0` を拒否する。
非0addressと有効checksumのfixtureを追加し、失敗時の旧出力保持も確認する。

## テストの不足

- `main_test.go` の `TestConvertPreservesDestinationOnInvalidInput` は
  `good[:len(good)-1] + "00"` により奇数hex長を作る。
  checksum検査より前に停止するため、checksum不正時の旧出力保持試験にはならない。
  `-2`へ変更し、エラーが `checksum mismatch` を含むことも検査する。
- `TestCapacity` の超過ケースは7905 bytesであり、コメントの「1 byte超過」と一致しない。
  7681 bytesの境界試験を追加すると明確になる。独立CLI検証では7681 bytesを正常に拒否した。
- repoの `src/tb_cpu_modules.sv` の既存CMP試験はNを確認せず、入力Cの両値も試さない。
  `A=$80, M=$00, C=0/1`、同値、負の差を永続的な回帰試験に追加する。
- GLMの `/private/tmp/alu_check/tb_alu_isolated.sv` はCMPの期待Nを
  `((a-b)>>7)` と32bitのまま比較し、`a=0,b=1` で33554431と1bit Nを比較する。
  生成binaryはこのoracle誤りでexit 1となった。これをDUTの失敗として扱わない。
  SBC oracleも `~c` の式幅に依存するため、整数の `1-c` を明示するのが適切。

## 独立検証結果

### Go / HEX

```sh
cd day99_completed/utils/hex_fpga
GOCACHE=/private/tmp/hex-fpga-sol-review-cache go test -count=1 ./...
GOCACHE=/private/tmp/hex-fpga-sol-review-cache go build \
  -o /private/tmp/hex-fpga-sol-review/hex_fpga .
```

既存Go tests全件pass、exit 0。
独立CLI fixtureは `/private/tmp/hex-fpga-sol-review/` に保存した。

| fixture | CLI結果 | 出力確認 |
| --- | --- | --- |
| `capacity-7680.hex` | exit 0 | 最大容量を受理 |
| `capacity-7681.hex` | exit 1 | 旧出力保持、temp残存なし |
| `checksum.hex` | exit 1 | 旧出力保持、temp残存なし |
| `duplicate-eof.hex` | exit 1 | 旧出力保持、temp残存なし |
| `rename.hex` → `destination-dir` | exit 1 | rename失敗後も既存dir内sentinel保持、temp残存なし |

type 04のaddress検証欠落以外に、容量・checksum・EOF・連続配置・atomic置換の
実装上の不具合は今回のレビューでは見つからなかった。
電源断後の永続性や実FPGA上の動作はこの検証の対象外。

### 単体ALU

独立oracleを `/private/tmp/alu-sol-review/tb_alu_sol.sv` に作成した。
CMP、ADC、SBCを各 `256 × 256 × 2`、合計 **393216 vectors** 実行し、
R/C/Z/N/Vのすべてを確認した。8bit切り詰めと `1-c` をoracleに明示した。

```sh
cd day99_completed
verilator --binary --timing --sv --top-module tb_alu_sol -Wno-fatal \
  -Iinclude -Isrc --Mdir /private/tmp/alu-sol-review/obj_dir \
  /private/tmp/alu-sol-review/tb_alu_sol.sv src/cpu_alu.sv \
  > /private/tmp/alu-sol-review/build.log 2>&1
/private/tmp/alu-sol-review/obj_dir/Vtb_alu_sol
```

ビルドlog: `/private/tmp/alu-sol-review/build.log`。
実行結果: `PASS: CMP ADC SBC 393216 exhaustive vectors`、exit 0。
Verilator 5.052。ビルドwarningは独立harness内の1bit値からintegerへの幅拡張。

CMP Nを8bit `A-M` から計算する修正は正しく、入力Cに依存しない。
ADC/SBCの二進演算にも今回の変更による回帰は見つからなかった。
単体ALUが現在のCPU実行経路に接続されていることや、decimal mode、実機動作を
証明する検証ではない。

## GLM追加修正後の再レビュー / ready判定

2026-10-02、GPT 6.1 Solがfinalの `main.go/main_test.go` を再読し、再検証した。

- type 04の `rec.addr != 0` 拒否と、checksumが有効な非0address fixture追加を確認。
  初回P2は解消した。
- checksum fixtureが `good[:len(good)-2] + "00"` に修正され、
  `checksum mismatch` のassertも追加された。
- 容量超過fixtureが正確に7681 bytesへ修正された。
- `GOCACHE=/private/tmp/hex-fpga-sol-review-cache go test -count=1 ./...` を再実行し、
  全件pass、exit 0 (`ok hex_fpga 0.113s`)。
- final binaryを `hex_fpga_final` として再buildし、初回の独立fixture
  `bad-ela.hex` (`:020001040000F9`) を再実行した。
  CLI exit 1、`extended linear address record address must be 0x0000` を確認。
  `final-ela-old.sv` の旧内容がbyte単位で保持され、temp残存もなかった。
  証拠log: `/private/tmp/hex-fpga-sol-review/final-ela-review.log`。
- `docs/REVIEW_GLM_TOOLS_RESULT_ja.md` は393216 vectors検証の実施者を独立Solと
  明記しており、ALU検証の帰属に誤りはない。
  「修正（3点）」の見出しに4点を列挙している軽微な文書誤りは残る。

判定: **HEX変更はready**。今回レビュー範囲のblocking issueは解消した。
単体ALUの既存独立393216 vectors passも維持して評価する。
repoに永続CMP N回帰testを置く推奨と、実機/CPU統合の未検証範囲は残る。
実装ファイルを編集せず、commit/pushは実施していない。

## 永続ALU回帰TBの追加

2026-10-03、GPT 6.1 Solが `day99_completed/src/tb_alu_regression.sv` を追加した。
整数の加減算とsigned range overflowをoracleに使い、DUTのoverflow bit式を複製しない。
CMP/ADC/SBCの393216 vectorsをR/C/Z/N/Vについて検査し、assert失敗をfatalへ伝播する。
500000nsのwatchdogを持つ。Makefile統合は親agent担当。

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

build/runともexit 0、`PASS: CMP/ADC/SBC ALU regression (393216 vectors)`。
初回buildはtmp親directory未作成で失敗したため、mkdir後に同commandを再実行して成功した。
GLM tools reportの「修正3点」見出しも「4点」へ訂正した。
