# GLM レッスン実装レビュー結果 (day05–18)

- 実施エージェント: GLM 5.3 (Claude Agent SDK 上の GLM セッション)
- 実施日: 2026-10-03
- スコープ: day05–18 の Makefile / Testbench / README ドキュメントのみ。
  CPU・RAM・lcd_demo の RTL、vendor/generated 系ファイル、day99 のロジックは本スコープ外。

## 実施した変更 (前セッション分を含む全体サマリ)

### 1. Makefile (day05–18 の starter / completed 計 28 ファイル)

- CPU ロジックシミュレーションのビルドディレクトリを `obj_$(SIM_CPU_TOP)` /
  `obj_tb_cpu` から**`build/$(BOARD)/$(SIM_CPU_TOP)`**に統一。
  - completed 側は既存の `SIM_CPU_TOP` / `TB_CPU_DEFINES` / `test-cpu` ターゲット定義をそのまま維持。
  - starter 側も既存の `sim-cpu-build` / `test-cpu` / `sim` ターゲット構成は変更せず、変数のみ導入。
- LCD (TFT) シミュレーションビルド (`sim-build`) も per-board 化:
  - `--Mdir build/$(BOARD)/$(SIM_TOP)` (旧 `obj_dir`)
  - ソースの `top_9k.sv` 固定を `top_$(BOARD).sv` に変更し `BOARD=20k` で `top_20k.sv` を使用
  - `--assert` を追加
- レシピに `mkdir -p` を追加 (後述の追加修正)。
- `clean` を `rm -rf build obj_dir obj_tb_cpu` 系に更新。

### 2. Testbench (day05–18 各 `sim/tb_cpu.sv`)

- ロジック検証用 TB を day07–18 のカリキュラム内容 (転送/算術/分岐/スタック/
  論理演算/シフト/比較/インデックス間接/カスタム命令) に合わせて更新。
- 既知の留意点: **day07 のみコンパイルエラー**。`cpu.sv` 側で `debug_pc` が
  input として扱われていることが原因で TB からドライブできない。
  **CPU 側の修正は Sol が実施するため本レビューでは未修正。**

### 3. README / README_ja (day07–18)

- Verification セクションのテストプログラム例を、更新後の TB に実際に載っている
  プログラムと一致するよう更新 (day08/13/14/15/16/17/18 を重点確認)。
- Simulation 手順を `make test-cpu` 中心の記述に更新
  (`make sim` は TFT smoke test も併せて実行する旨を注記)。
- day08 README_ja の学習目標に重複していた「テストのパス」項目を 1 つに削除。

## 検証結果 (今回のセッションで実測)

- `day08_completed`: `make test-cpu` → **ALL TESTS PASSED**
- `day18_completed`: `make test-cpu` (build ディレクトリ削除後のクリーン状態から) → **ALL TESTS PASSED**
- `make -n` で `BOARD=20k` の LCD ビルドが `--Mdir build/20k/tb_tft` + `top_20k.sv` + `--assert` になることを確認。
- 前セッションの全 completed 一斉 test-cpu の既知結果: **day07 のコンパイルエラーを除き全パス** (day13/14 含む)。今回再全数実行は省略。
- starter (day05–18) の TODO 実装前のテスト失敗は**想定どおり (expected FAIL)**。

## 追加修正: per-board ディレクトリの mkdir

初回は `build/$(BOARD)/...` が存在しない状態で Verilator が
`Can't write file: build/9k/tb_cpu/...` で失敗した (Verilator はネストした
`--Mdir` を自動作成しない)。全 28 Makefile の該当レシピに `mkdir -p` を追加し、
クリーン状態からの `test-cpu` 再実行でパスを確認した。

## 注意 (主張の範囲)

- `make sim` の TFT smoke test はあくまで表示系の疎通確認であり、
  **メモリ実装や CPU タイミングの正しさを証明するものではない**。
  ロジック検証は各日 `test-cpu` (Verilator + `--assert`) によるもの。

## 残作業

- day07 の `debug_pc` input 問題 (CPU 側) — Sol が対応予定。
- day05–18 starter の TODO 実装 (受講者作業分)。
- README の全面再校 (全日 en/ja の細部表現) は本スコープでは未実施。
