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
   - `cpu_ctx_t` と `calc_cpu_next(cur,in)` を導入し、`transfers`〜`flags/custom`〜`branches`〜`compare`〜`logic`〜`shifts`〜`load`〜`store` までの opcode カテゴリを `cpu_ctx_t` の副作用計算へ順に移す。
3. **未完了カテゴリの統合**
   - 残る ADC/SBC 系―BRK/IRQ などの decode/execute ロジックを `calc_cpu_next()` に取り込み、`state_decode_execute()` を `calc_cpu_next()` 呼び出しに限定。
4. **`cpu_ctx_t` ベースへのタスク移行**
   - `state_*_tasks.sv` や `cpu_exec_*_pkg` を `cpu_ctx_t` の field 操作へリファクタし、`next_state`/`next_fetch_stage` への直接書き込みを排除。
5. **2-process FSM 完成**
   - `always_ff` では `cur <= next;` のみを実行し、`make format`/`make -C day99_completed BOARD=9k clean test`/`make -C day99_completed BOARD=9k download` を通じて旧実装との一致と実機動作（PasteBoard問題含む）を確認。

## 現在完了している部分

- Step1〜3：`next_state`/`next_fetch_stage` の追加、Boot〜Fetch 系の next-state を `cpu_fsm_next_pkg` に切り出し。
- Step4（Step4.1〜4.11）：`cpu_ctx_t` と `calc_cpu_next()` の導入により `transfers`〜`store` の opcode カテゴリを `cpu_ctx_t` の副作用で処理する構造が完成。また `calc_decode_inc_dec_next()` を追加して INC/DEC や INX/INY/DEX/DEY を組み込んだ。
- `make format` / `make -C day99_completed BOARD=9k clean test` は既存警告のみ、`make -C day99_completed BOARD=9k download` も別セッションで実機対応確認済み（`gw_sh` PasteBoard/Connection Invalid によるセグフォルトは継続）。

## 現在取り組んでいるステップ

- Step4 の残りとして、制御フロー系（JMP/JSR/RTS/PHA/PLA/PHP）と ADC/SBC 等の decode/execute ロジックを `calc_cpu_next()` に追加し、`state_decode_execute()` を純粋な `calc_cpu_next()` 呼び出しへ移行する。
- `cpu_ctx_t` を操作する形へ `state_*_tasks.sv` / `cpu_exec_*_pkg` を順次更新し、`next_state`/`next_fetch_stage` への直接書き込みを排除。
- 実機向け `make -C day99_completed BOARD=9k download` は PasteBoard/Connection Invalid の警告があるものの TangNano実機で LCD 表示含め正常動作を確認済み。

## 残りのステップ

1. `cpu_ctx_t` で保存すべき副作用すべてを `calc_cpu_next()` に集約、BRK/IRQ や割込み前後の処理も同様にピュア関数化。
2. `state_*_tasks.sv` や `cpu_exec_*_pkg` のリファクタ完了後、`always_ff` を `cur <= next;` だけに絞った 2-process FSM を完全化。
3. フォーマット、Verilator テスト、実機ダウンロード（PasteBoard エラー対策含む）を繰り返して整合性を確認しながら完了の基準を満たす。

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
3. 全 `state_*_tasks.sv` / `state_decode_tasks.sv` が `cpu_ctx_t` のフィールド（`state`, `fetch_stage`, `pc`, `adb`, `ce*`, `vram*` など）を更新し、`next_state`/`next_fetch_stage` への直接書き込みを排除している。
4. `always_ff` は `cur <= next;` のみを実行し、`dout_r`, `vsync_sync`, `show_info_counter` などの同期ロジックは `cur`/`next` の差分で処理する。
5. `make format`, `make -C day99_completed BOARD=9k clean test`, `make -C day99_completed BOARD=9k download` が通り、LCD表示・VRAMクリアなどの副作用が旧実装と一致していることを確認する。
