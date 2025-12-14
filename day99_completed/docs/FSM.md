# FSM 対応 TODO

## 背景

現在の `cpu.sv` は状態遷移をすべて `always_ff` ブロック内の `case (state)` に直接書き込み、`state_*` の `.svinc` 断片をタスク化したとはいえ、　1つのプロセス内で状態を更新する「1プロセス型」FSMです。この形では状態遷移の並列性が死んでおり、状態遷移ロジックのテスト・検証性にも限界があります。  
次のフェーズでは、**「状態を保持するプロセス」と「次状態を決めるプロセス」を分離した2プロセス型FSM**へ移行し、状態遷移の可視性と安全性を高めます。

## 目標

- `state`/`fetch_stage` を格納するレジスタを `always_ff` で更新し、`always_comb` で次状態/次ステージ (`next_state`, `next_fetch_stage`) を計算する構造に移行する。
- 既存の状態タスク（`state_*_tasks.sv`や`state_decode_tasks.sv`）は、`state <= ...` ではなく `next_state = ...` を設定するよう書き換える。
- 状態遷移ロジックで使う共通データ（`state`, `operands`, `fetch_stage` など）をまとめたコンテキスト構造体（仮称 `cpu_ctx_t`）を導入して、タスク/パッケージ間の引数を整理する。
- 最終的には `state_machine_step()` を `always_comb` で呼び出して次状態を計算し、`always_ff` ではそれを `state` にだけ書き戻すようにする。

## 段階的 TODO

1. **コンテキストと next_state を追加**
   - `cpu.sv` に `cpu_state_e next_state;` `fetch_stage_e next_fetch_stage;` を追加し、リセット時に初期化。
   - `state_machine_step()` を `always_comb` でも呼べるようにし、「今の状態」`state` と「次の状態」`next_state` を引数として渡す。
2. **状態タスクを next_state へ書き換える**
   - `state_boot_*`, `state_fetch_*`, `state_write_req_*`, `state_show_info_*`, `state_clear_vram_*` で `state <= ...` を `next_state = ...` に変更し、`state_machine_step()` から `next_state` を受け取る形へ。
   - `state_decode_execute()` も `next_state` へ書き換え、パッケージ呼び出しに `ref cpu_state_e next_state` を渡す。
3. **状態遷移の combinational プロセス**
   - 新たな `always_comb` ブロックで `next_state`/`next_fetch_stage` を `state_machine_step()` により計算し、必要な副作用（`fetch_stage` による条件）も扱う。
4. **シーケンシャル更新プロセス**
   - 既存の `always_ff @(posedge clk ...)` では `state <= next_state;`, `fetch_stage <= next_fetch_stage;` のみ行い、その他はコンテキストの順序で処理。
5. **cpu_ctx_t などの整理**
   - `cpu_ctx` 構造体を定義して `cpu_exec_*_pkg` への引数を整理。状態タスクが `ctx` を更新するようにすれば、次フェーズで `next_state` だけでなく `ra`, `pc` なども一貫性を持って扱える。
6. **テスト＋ドキュメント**
   - `state_*` タスクと `cpu.sv` の同期が整ったら `make BOARD=9k clean test` を再実行し、変化がないことを確認。  
   - `docs/FSM.md` に進捗や注意点を記録しつつ、`MODULE_MAP.md` やアーキテクチャドキュメントに簡単な更新を追加。

## 今後の着手

1. `state_machine_step()` のインターフェースを「`state`・`fetch_stage` を入力として、`next_state`・`next_fetch_stage` を出力する`状態遷移関数`」に変更する。
2. 各 state タスクを `next_state` へ書き換え、現行動作との整合性を保持するための一時的な `next_state` 落ち着き場を設ける。
3. そのうえで `always_ff` 側に `state <= next_state; fetch_stage <= next_fetch_stage;` のみ残す構成へ移行。

この方針に沿って、まず `state_machine_step()` を `next_state` を扱える形に書き換えることから着手します。

---

## 進捗ログ

### 2025-12-14: Step 1〜2 を実装（破壊的変更なしで移行準備）

- `cpu.sv` に `next_state` / `next_fetch_stage` を追加し、リセット時の初期化も追加。
- `state_machine_step()` 側で `next_state = state; next_fetch_stage = fetch_stage;` を毎サイクルのデフォルトとして設定する形に変更。
- `state_*_tasks.sv` 群は `state <= ...` / `fetch_stage <= ...` ではなく、基本的に `next_state = ...` / `next_fetch_stage = ...` を書く形へ移行。
- `fetch_resume_state`（旧 `next_state` の意味）を維持し、メモリ READ 待ちの復帰先として使い続ける。
- `state_decode_tasks.sv` は `cpu_exec_*_pkg` を **次状態参照（`next_state` / `next_fetch_stage`）に対して呼び出す** 形に変更し、実行系がフェッチ要求を出せるようにした。
- `cpu_exec_*_pkg.sv` 側の `state <= ...` / `fetch_stage <= ...` は、`ref` で受け取った「次状態参照」を書き換える意図に合わせて `state = ...` / `fetch_stage = ...` へ変更（`<=` のままだと常に「現在状態」を上書きしてしまい、HW で止まる原因になり得る）。

#### 既知の落とし穴（今回潰したもの）
- `next_fetch_stage` を導入した段階で、実行パッケージが `fetch_stage <= ...` のままだと「次フェッチステージ」が更新されず、実機で表示が出なくなるケースがある（シミュレーションでは検出しにくい）。
- decode から exec パッケージを呼ぶとき、`fetch_stage` を `next_fetch_stage` に差し替えないと同様に止まる。

#### 現状の構造
- **まだ 2プロセス（always_comb/always_ff）にはしていない。**  
  いまは「状態遷移の行き先」だけを `next_state/next_fetch_stage` に寄せて、既存の逐次（always_ff）実装を壊さずに Step 3 へ進める段階。

### 次にやること（Step 3〜）
- Step 3（always_comb で次状態計算）に進むには、状態遷移だけでなく **PC/ADB/WE 等の“副作用”も next 値として持つ** 必要があるため、`cpu_ctx_t cur/next` に段階的に寄せていく（`cpu_2proc_skeleton.sv` の方針）。

### 2025-12-14: Step 3 の着手（次状態ロジックの切り出し開始）
- `src/cpu/cpu_fsm_next_pkg.sv` を追加し、まず Boot/FETCH 周りの「次状態のみ（副作用なし）」ロジックを `function` として切り出し開始。
  - 目的: 今後 `always_comb` に移したときに、状態遷移が副作用に引きずられて壊れないようにする。
  - まだ `cpu.sv` には接続していない（段階移行のため）。

### 2025-12-14: Step 3 を部分配線（Boot の一部だけ next-state 関数で駆動）
- `cpu_fsm_next_pkg` に `consts_pkg` を取り込み、`COLUMNS/ROWS` 等を package 内で参照できるようにした。
- `cpu.sv` に `calc_boot_fetch_next()` の呼び出し（`always_comb`）を追加し、まず `INIT/INIT_RAM` だけは `state <= boot_fetch_next.next_state` を使うようにした。
  - 副作用（RAM 書き込みなど）は従来どおり `state_machine_step()` 側で実行し、**状態更新だけを置き換える**最小の差分にしている。
  - 次は `FETCH_*` 系の状態も同様に段階的に置き換えていく（実機での確認を挟みながら進める）。
- `BOARD=9k` の `make download` で **実機動作（LCD表示）OK** を確認。

### 2025-12-14: Step 3 を拡大（FETCH_REQ / FETCH_WAIT まで next-state 関数で駆動）
- `FETCH_REQ` / `FETCH_WAIT` も `calc_boot_fetch_next()` の出力で `state/fetch_stage` を更新するように拡大。
- `BOARD=9k` の `make download` で **実機動作（LCD表示）OK** を確認。

### 2025-12-14: Step 3 を拡大（FETCH_RECV まで next-state 関数で駆動）
- `FETCH_RECV` も `calc_boot_fetch_next()` の出力で `state/fetch_stage` を更新するように拡大。
- `BOARD=9k` の `make download` で **実機動作（LCD表示）OK** を確認。

### 2025-12-14: Step 3 を拡大（WRITE_REQ まで next-state 関数で駆動）
- `WRITE_REQ` も `calc_boot_fetch_next()` の出力で `state` を更新するように拡大（副作用は従来どおりタスク側）。
- `state_machine.svh` から `FETCH_OPERAND*` の誤った重複 case を削除（`fetch_stage` は `state` ではないため）。
- `BOARD=9k` の `make download` で **実機動作（LCD表示）OK** を確認。

### 2025-12-14: Step 3 を拡大（INIT_VRAM まで next-state 関数で駆動）
- `INIT_VRAM` も `calc_boot_fetch_next()` の出力で `state/fetch_stage` を更新するように拡大。
- `BOARD=9k` の `make download` で **実機動作（LCD表示）OK** を確認。

### 2025-12-14: Step 3 を拡大（CLEAR_VRAM/CLEAR_VRAM2 まで next-state 関数で駆動）
- `CLEAR_VRAM` / `CLEAR_VRAM2` も `calc_boot_fetch_next()` の出力で `state/fetch_stage` を更新するように拡大。
- `BOARD=9k` の `make download` で **実機動作（LCD表示）OK** を確認。

### 2025-12-14: Step 3 を拡大（SHOW_INFO まで next-state 関数で駆動）
- `SHOW_INFO`（入口のみ）も `calc_boot_fetch_next()` の出力で `state` を更新するように拡大。
  - `SHOW_INFO2` は内部に stage/counter/mem_read があり、次状態だけでなく副作用も絡むため現時点では既存タスクに残す。
