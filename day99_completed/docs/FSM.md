# FSM 対応 TODO

## 背景

現在の `cpu.sv` は状態遷移をすべて `always_ff` ブロック内の `case (state)` に直接書き込み、`state_*` の `.svinc` 断片をタスク化したとはいえ、1つのプロセス内で状態を更新する「1プロセス型」FSMです。この形では状態遷移の並列性が死んでおり、状態遷移ロジックのテスト・検証性にも限界があります。次のフェーズでは、**「状態を保持するプロセス」と「次状態を決めるプロセス」を分離した2プロセス型FSM**へ移行し、状態遷移の可視性と安全性を高めます。

## 目標

- `state`/`fetch_stage` を格納するレジスタを `always_ff` で更新し、`always_comb` で次状態/次ステージ (`next_state`, `next_fetch_stage`) を計算する構造に移行する。
- 状態遷移ロジックで使う共通データ（`state`, `operands`, `fetch_stage` など）をまとめたコンテキスト構造体（仮称 `cpu_ctx_t`）を導入して、タスク/パッケージ間の引数を整理する。
- 最終的には `state_machine_step()` を `always_comb` で呼び出して次状態を計算し、`always_ff` ではそれを `state` にだけ書き戻すようにする。

## 段階的 TODO

1. **コンテキストと next_state を追加**
   - `cpu.sv` に `cpu_state_e next_state;` `fetch_stage_e next_fetch_stage;` を追加し、リセット時に初期化。
   - `state_machine_step()` を `always_comb` でも呼べるようにし、「今の状態」`state` と「次の状態」`next_state` を引数として渡す。
2. **状態タスクを next_state へ書き換える**
   - `state_boot_*`, `state_fetch_*`, `state_write_req_*`, `state_show_info_*`, `state_clear_vram_*` で `state <= ...` を `next_state = ...` に変更し、`state_machine_step()` から `next_state` を受け取る形にする。
   - `state_decode_execute()` も `next_state` へ書き換え、パッケージ呼び出しに `ref cpu_state_e next_state` を渡す。
3. **状態遷移の combinational プロセス**
   - `always_comb` で `next_state`/`next_fetch_stage` を `state_machine_step()` により計算し、副作用も `cpu_ctx_t` 上の next 値にまとめる。
4. **シーケンシャル更新プロセス**
   - `always_ff @(posedge clk ...)` では `state <= next_state;`, `fetch_stage <= next_fetch_stage;` のみにし、レジスタ/フラグは `cpu_ctx_t` の更新でまとめる。
5. **cpu_ctx_t などの整理**
   - `cpu_exec_*_pkg` への引数を `cpu_ctx_t` で統一し、副作用を `cur/next` の差分で扱えるようにする。
6. **テスト＋ドキュメント**
   - `make BOARD=9k clean test` を繰り返し、挙動が変わらないことを確認しつつ `docs/FSM.md` に進捗を記録。

## 作業ステップ構成

1. **Step1〜3（next_state 導入と Boot/Fetch の切り出し）**
   - `cpu.sv` に `next_state`/`next_fetch_stage` を追加し、Boot〜Fetch 系状態の next-state ロジックを `cpu_fsm_next_pkg` へ移して `always_comb`/`always_ff` の分離準備を完了。
2. **Step4（cpu_ctx_t と calc_cpu_next）**
   - `cpu_ctx_t` と `calc_cpu_next(cur,in)` を導入し、命令カテゴリを `cpu_ctx_t` 上の次状態計算（副作用含む）として実装する。
   - 注意: 現時点の `cpu.sv` は `next_ctx = calc_cpu_next(...)` を計算しているが、レジスタ/出力へはまだ反映していない（配線は未完了）。
3. **未完了カテゴリの統合**
   - 残る BRK/IRQ などの decode/execute ロジックを `calc_cpu_next()` に取り込み、最終的に `state_decode_execute()` を `calc_cpu_next()` の結果を反映する薄いラッパにする。
4. **`cpu_ctx_t` ベースへのタスク移行**
   - `state_*_tasks.sv` や `cpu_exec_*_pkg` を `cpu_ctx_t` の field 操作へリファクタし、`next_state`/`next_fetch_stage` への直接書き込みを排除。
5. **2-process FSM 完成**
   - `always_ff` では `cur <= next;` のみを実行し、`make format`/`make -C day99_completed BOARD=9k clean test`/`make -C day99_completed BOARD=9k download` を通じて旧実装との一致と実機動作（PasteBoard問題含む）を確認。

## 現在完了している部分

- Step1〜3：`next_state`/`next_fetch_stage` の追加、Boot〜Fetch 系の next-state を `cpu_fsm_next_pkg` に切り出し。
- Step4（実装側の進捗）：`cpu_ctx_t` と `calc_cpu_next()` を追加し、`calc_cpu_next()` 内で `transfers`〜`flags/custom`〜`branches`〜`compare`〜`logic`〜`shifts`〜`load`〜`store`〜`control_flow`〜`adc/sbc`〜`inc/dec` の命令カテゴリを「pure な次状態計算」として実装済み。
- `DECODE_EXECUTE` は `calc_cpu_next()` の結果（`next_ctx`）を `state_decode_tasks.sv` でレジスタ/出力へ反映するように配線済み（legacy の `cpu_exec_*_pkg` 呼び出しは縮退済み）。
- `state_boot_*`（`INIT/INIT_VRAM/INIT_RAM`）は `calc_cpu_next()` の結果（`next_ctx`）を反映する形へ移行済みで、`make -C day99_completed BOARD=9k download` で実機動作も確認済み。
- `state_fetch_*`（`FETCH_REQ/FETCH_WAIT/FETCH_RECV`）も `calc_cpu_next()` の結果（`next_ctx`）を反映する形へ移行済みで、`make -C day99_completed BOARD=9k download` で実機動作も確認済み。
- `WRITE_REQ` / `CLEAR_VRAM*` / `SHOW_INFO*` も `calc_cpu_next()` の結果（`next_ctx`）を反映する形へ移行済み（`SHOW_INFO` では `show_info_rom` をパッケージ側に持ち、次状態計算内で参照）。
- `cpu.sv` は `always_comb` で `next = calc_cpu_next(cur,in)` を計算し、`always_ff` では `cur <= next;` のみを行う形へ移行済み（2-process FSM の基本形が成立）。
- `make format` / `make -C day99_completed BOARD=9k clean test` は既存警告のみ、`make -C day99_completed BOARD=9k download` も別セッションで実機対応確認済み（`gw_sh` PasteBoard/Connection Invalid によるセグフォルトは継続）。
- `src/cpu/state_*_tasks.sv` と `src/cpu/state_machine.svh` は `src/cpu/legacy/` に移動し、現行CPUのビルド経路と混ざらないように整理済み。
- `cpu_ctx_t` のスリム化を一部実施（未使用だった `next_state`/`next_fetch_stage` フィールドを削除）。

## 現在取り組んでいるステップ

- 2-process FSM が成立したので、次は「警告/型幅の整理」と「残っているlegacyコードの整理」を進める。

## 残りのステップ

1. **型幅/警告の整理**：Verilator の `WIDTHEXPAND/WIDTHTRUNC` 等を、明示的な幅のマスク/キャストで減らす（実機動作を崩さない範囲で段階的に）。
2. **legacyコードの扱いを明確化**：`state_*_tasks.sv` / `state_machine.svh` / `cpu_tasks.svh` など、現状ビルドに入っていない旧経路を「参考実装」として残すか、別ディレクトリへ移す/削除するかを決める。
3. **`cpu_ctx_t` の整理（任意）**：`next_state`/`next_fetch_stage` など、2-process化後に不要になったフィールドを削除して見通しを良くする（影響範囲が大きいので最後に実施）。
4. **未実装命令/割り込み方針**：BRK/IRQ/NMI など未対応領域がある場合、仕様（未実装のまま/実装する/例外扱い）を `calc_cpu_next()` と docs に明記する。

## 明日（再開ポイント）

今日の時点で `make -C day99_completed BOARD=9k download` は実機で稼働確認済み（LCD更新OK / `CVR` OK / `IFO` OK）。

明日は以下から再開する：

1. **残っている警告の確認と整理**
   - コマンド: `make -C day99_completed test`
   - 目標: `WIDTHEXPAND/WIDTHTRUNC` の追加削減、必要なら最小の型幅修正を継続。
   - 現状: `UNUSEDSIGNAL` 系の警告が多く残っている（致命ではないが、最終的に減らす）。
   - 主な対象: `day99_completed/src/cpu/cpu_fsm_next_pkg.sv`

2. **legacyコードの整理方針決め**
   - 方針候補:
     - A) 旧 `state_*_tasks.sv` / `state_machine.svh` / `cpu_tasks.svh` を「参考実装」として残し、`docs/` に“現状は未使用”と明記する
     - B) `src/cpu/legacy/` 等へ移動して、ビルド経路と混ざらないようにする
     - C) もう不要なら削除（リスクがあるので最後）
   - 対象ファイル例:
     - `day99_completed/src/cpu/state_*_tasks.sv`
     - `day99_completed/src/cpu/state_machine.svh`
     - `day99_completed/include/cpu_tasks.svh`

※現状: `day99_completed/src/cpu/state_*_tasks.sv` と `day99_completed/src/cpu/state_machine.svh` は `day99_completed/src/cpu/legacy/` へ移動済み（ビルド未使用）。`day99_completed/include/cpu_tasks.svh` は互換/参考のため残置していますが、現行CPUは参照しません。

3. **（任意）`cpu_ctx_t` のスリム化**
   - 2-process化後に不要なフィールド（例: `next_state`/`next_fetch_stage`）を削除して可読性を上げる。

## Step4 ロールアウト順

1. `state_boot_*` 系：VRAM/RAM の初期化と boot ROM 書き込みをコンテキスト化する。
2. `state_fetch_*` 系：PC/ADB 更新やオペランド読み出しなどのフェッチ副作用を `cpu_ctx_t` に移す。
3. `state_decode_*`／`cpu_exec_*`：decode〜execute の副作用を `calc_cpu_next()` に集約し、順次 pure function 化する。
4. `state_write_req_*`／`state_show_info_*`：書き込み/デバッグ/VRAM 操作を `next` にまとめる。
5. `state_clear_vram_*`／`HALT`：残存状態を `next` に移し、`always_comb`/`always_ff` を完全に分離。

各ステップでは `next` コンテキストの完成度を高めながら `make format` / `make BOARD=9k clean test` / `make BOARD=9k download` を繰り返し、新旧動作の一致を確認します。

## 2-process FSM 完了チェックリスト

以下がすべて満たされれば2プロセス FSM の移行が完了と判断できます:

1. `cpu_types_pkg.sv` に `cpu_ctx_t`（`cur`）と `cpu_next_t`（`next`）を定義し、PC/ADA/DIN/RA/RX/RY/SP/FLAGS/STATE/FETCH_STAGE/`fetch_resume_state`/`show_info_stage` などを一元管理する。
2. `always_comb` 内の `cpu_fsm_next()`（または `state_machine_step()`）が `cur` と入力のみを参照し、`next` を返す純粋関数になっている。副作用はすべて `next` のフィールド更新として扱い、`cpu_exec_*_pkg` も `next` を `ref` で受け取って処理する。
3. `always_ff` は `cur <= next;` のみを実行し、`dout_r`, `vsync_sync`, `counter` などの同期ロジックも `next` 側で計算している。
4. 旧 `state_*_tasks.sv` はビルド経路から外れており（または削除済み）、動作に影響しない状態になっている。
5. `make format`, `make -C day99_completed BOARD=9k clean test`, `make -C day99_completed BOARD=9k download` が通り、LCD表示・VRAMクリアなどの副作用が旧実装と一致していることを確認する。
