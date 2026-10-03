# レビュー修正結果 (Flash session)

- 日付: 2026-10-02
- 実装モデル: GLM (glm-5.3-flash, Claude Agent SDK)
- 対象リポジトリ: `~/repo/sokoide/fpga/tangnano_6502_cpu`
- 前提: 前回 Flash セッションは 90 ファイル超を調査したが編集ゼロだったため、絞り込んだスコープで即実装した。
- 制約: day05..18 の Makefile/CPU テストと day99 の CPU FSM は GLM5.3 が並行所有のため未編集。commit/push/Vault/memory/vendor/生成物は変更なし。

## 実装した修正

### 1. ルート Makefile（ループの失敗伝播 + format除外）

`Makefile`:

- `build` / `sim` / `clean` の for ループ内の `$(MAKE) -C $$day ...` に `|| exit 1;` を追加し、
  いずれかの day が失敗したらループ全体を即座に異常終了させるようにした（従来は失敗が握り潰され、
  `make test` が常に成功扱いになる問題があった）。
- `format` ターゲットの `textlint` に `--ignore-path .textlintignore` を追加
  （markdownlint と同様に `conductor/`・`CLAUDE.md`・`AGENTS.md` を textlint の対象外にする）。

新規ファイル `.textlintignore`:

```text
conductor/
CLAUDE.md
AGENTS.md
```

### 2. day02 / day03 の Makefile に `--assert`

`day02/Makefile`、`day02_completed/Makefile`、`day03/Makefile`、`day03_completed/Makefile`:

- Verilator 実行フラグを `-Wall -Wno-fatal --assert --sv --timing --trace --binary` に変更。
  テストベンチ内の `assert` が古い Verilator でも確実に評価されるようにする意図。

### 3. day01 docs: LED 点滅タイミングの訂正

`day01_completed/README.md` / `README_ja.md`:

- 誤: 「約 0.8 秒間隔で点滅」→ 正: counter bit 24 は 27 MHz で `2^24 / 27 MHz = 0.621 秒` ごとに反転、
  フル周期（on+off）は `1.243 秒`。検証手順とコード例のコメント（誤 `approx. 1Hz`）の両方を修正。

### 4. day06 docs: LDA イミディエートの表記訂正

`day06/README.md` / `README_ja.md`（student 側のみ。day06_completed は既に正しかった）:

- 誤: アセンブリ表記 `LDA #$A9` ＋ 機械語 `A9 42` → 正: `LDA #$42`。
  （`A9 42` は「オペコード 0xA9 = LDA immediate、オペランド 0x42」を意味する）

### 5. day18 docs: カスタム命令オペコードの訂正

`day18/README.md`、`day18/README_ja.md`、`day18_completed/README.md`、`day18_completed/README_ja.md`:

- 誤 `0x12/0x22/0x32` → 実装 (`include/opcodes.svh`、`cpu.sv` と突き合わせて確認) に合わせて訂正:
  - `0xFF` **WVS** (Wait for V-Sync)
  - `0xCF` **CVR** (Clear VRAM)
  - `0xDF` **IFO** (Info)
  - `0xEF` **HLT** (Halt CPU) — 表から抜けていたため行を追加
- mermaid 図の `Fetch 0x12 (WVS)` も `Fetch 0xFF (WVS)` に修正。

### 6. day99 docs: 実アーキテクチャへの同期

`day99_completed/README.md` / `README_ja.md`:

- プロジェクト構成図の虚偽を修正: 存在しない `src/top.sv` と `tests/` を削除し、実際の
  `top_9k.sv`/`top_20k.sv`（ボードラッパ）→ `top_core.sv` → `cpu.sv`（+ `cpu/cpu_fsm_next_pkg.sv`,
  `cpu/cpu_types_pkg.sv`）構成、`sim/`（Verilator スタブ）、`src/tb_*.sv` を反映。
- 「包括的なテスト（unit tests, integration suites）」という記述を「スモークレベルのシミュレーションのみ
  （`make test` = `tb_vram_smoke`、オプション `make sim-ram`、命令レベルのテストスイートは未統合、
  DSIM テストベンチは Linux/Windows 必須）」に訂正。

`day99_completed/docs/MODULE_MAP.md`:

- mermaid を実階層（`top_9k/top_20k → top_core → cpu/lcd/ram`、`cpu → cpu_fsm_next_pkg/cpu_types_pkg`）に修正。
- 読書順リストから `src/top.sv` を除去し、`top_core.sv` と `src/cpu/` 配下の package を案内に追加。
- `src/cpu_decoder.sv` / `src/cpu_alu.sv` / `src/cpu_memory.sv` が**cpu.sv には未接続の単体モジュール**
  （`tb_cpu_modules.sv` でのみ使用）であることを明記。

`day99_completed/docs/BUILD.md`:

- ボード切替の対象を `src/top.sv` → `src/top_9k.sv` / `src/top_20k.sv`、`lcd_cpu_bsram.gprj` →
  `day99_9k.gprj` / `day99_20k.gprj`（Makefile の `PROJ := day99_$(BOARD).gprj` と一致）に訂正。

## 使用したコマンド / 検証

- 編集は Python スクリプトで一括適用（各置換の出現数を assert、部分的な適用なしを保証）。
- `git diff --check` — 空白エラーなし（pass）。
- `make -n build` / `make -n format`（ルート）— `|| exit 1` と `--ignore-path .textlintignore` が
  展開されることを確認。
- `make -C day02_completed -n sim` / `make -C day03 -n sim` — `--assert` 付きの verilator 行を確認。
- 突き合わせ確認に使用した実装: `day18_completed/include/opcodes.svh`（`OP_WVS=8'hFF`, `OP_CVR=8'hCF`,
  `OP_IFO=8'hDF`, `OP_HLT=8'hEF`）、`day99_completed/src/`（`top_core.sv` のみが `cpu cpu_inst` を
  instantiate、`cpu.sv` が `cpu_fsm_next_pkg::calc_cpu_next` を使用）。

### 未実施の検証（サンドボックス制約）

- `pnpm dlx textlint ...` の実行（`--ignore-path` フラグの実機確認）。フラグと `.textlintignore`
  自動読み込みは textlint 公式ドキュメントの動作だが、`pnpm dlx` がサンドボックスで承認必須のため
  実行検証は未実施。次回 `make format` 実行時に要確認。
- Verilator 実行（`make test`）は本スコープ外（day99 側は GLM5.3 が所有中のため触らない）。

## 残作業

1. **day99 側ドキュメントの残存古い参照**: `day99_completed/CLAUDE.md`（`src/top.sv`、
   `lcd_cpu_bsram.gprj`、テストに関する記述）、`docs/DEVELOPER.md`、
   `docs/README_architecture_en.md` / `_ja.md` は未確認・未修正。本スコープ外として未着手。
2. **`make format` の実行検証**: textlint `--ignore-path` の実機確認（上記）。
3. **ルート README.md / README_ja.md**: 同種の古い記述（`top.sv` 等）がないか未監査。
4. **命令レベルのシミュレーション整備**: day99 は現状スモークのみ。README の記述は実態に合わせて
   「スモークのみ」と訂正済み。今後テストスイートを整備する場合は README の「Simulation」節を更新すること。
5. **並行作業中のファイル**: `day99_completed/src/cpu_alu.sv`、`utils/hex_fpga/*`、
   `src/tb_alu_regression.sv`（未追跡）には他セッションの変更があり、本セッションでは一切触れていない。
6. **day05..18 の Makefile/CPU テストと day99 CPU FSM**: GLM5.3 が所有中。本スコープで触れたのは
   day02/day03（student + completed）の Makefile のみ。
