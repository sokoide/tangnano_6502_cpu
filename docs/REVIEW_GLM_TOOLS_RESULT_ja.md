# レビュー結果 — hex_fpga / cpu_alu（GLM）

- 実施モデル: **glm-5.3**
- 対象: `day99_completed/utils/hex_fpga`（converter）、`day99_completed/src/cpu_alu.sv`（ALU）
- 日付: 2026-10-02

## 変更対象の現状（diff 内）

converter と ALU の変更はすでに working tree の diff に含まれている:

- `day99_completed/src/cpu_alu.sv` — 変更済み（本セッションでは編集なし）
- `day99_completed/utils/hex_fpga/main.go` / `main_test.go` — 変更済み＋本セッションの修正
- `day99_completed/utils/hex_fpga/go.mod` 変更、`go.sum` 削除、`main_test.go` 新規（untracked）

## 本セッションで実施した修正（4点、hex_fpga のみ）

1. **main.go**: type 04（Extended Linear Address）レコードの `rec.addr != 0` を拒否する検証を追加。
   アドレスフィールドは常に 0x0000 でなければならず、違反時は
   `extended linear address record address must be 0x0000` エラー。
2. **main_test.go**: `TestExtendedLinearAddress` に、チェックサム有効な状態で
   ELA アドレスフィールドが非ゼロ（0x0012）のレコードを拒否する回帰テストを追加。
3. **main_test.go チェックサムフィクスチャ修正**:
   `TestConvertPreservesDestinationOnInvalidInput` の `good[:len(good)-1]+"00"` は
   1文字のみ切り詰め、奇数長の hex 行となり意図した「チェックサム不一致」ではなく
   hex 桁数エラーを発生させていた。`good[:len(good)-2]+"00"` に修正し、
   エラーが `checksum mismatch` であることを明示的にアサート。
4. **main_test.go TestCapacity**: 7905 バイト（31×255）のオーバーフロー案例を
   容量+1 の厳密に 7681 バイトへ変更（境界値検証として正確なものへ）。

## テスト結果

```
$ env GOCACHE=/private/tmp/tangnano-go-cache go test ./...
ok  	hex_fpga	0.287s
```

exit 0、全テスト合格。

## ALU 検証（独立 Sol 実施分・帰属明記）

`cpu_alu.sv` の CMP / ADC / SBC 393,216 ベクトル検証は**独立した Sol により実施・合格**
済みであり、その結果は Sol の作業に帰属する。本セッション（glm-5.3）は ALU を
一切編集していない。

## 備考

- IDE 診断の `packages.Load error` / `BrokenImport` はデフォルト GOCACHE
  (`~/Library/Caches/go-build`) の権限問題に起因する LSP の誤検出であり、
  指定 GOCACHE での実テストには影響しない。
- commit / push は指示なしのため未実施。
