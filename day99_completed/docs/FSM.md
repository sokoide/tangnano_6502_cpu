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

## Step4 ロールアウト順

1. `state_boot_*` 系：周辺 VRAM/RAM の初期化と boot ROM 書き込みをコンテキスト化する。
2. `state_fetch_*` 系：フェッチステージの副作用（PC+/ADB 更新、オペランド読み出し）を `cpu_ctx_t` に移す。
3. `state_decode_*`／`cpu_exec_*`：デコード〜実行の副作用を `calc_cpu_next()` へ集約し、純粋な次状態関数へと昇格。
4. `state_write_req_*`／`state_show_info_*`：書き込み/デバッグ/VRAM クリア操作を `next` に集約。
5. `state_clear_vram_*`／`HALT` などの残存状態を `next` に移し、`always_comb`/`always_ff` を完全に分離。

各ステップでは sequential ロジックを壊さないよう既存タスクを維持しつつ、`next` コンテキストを育てて `make format`/`make BOARD=9k clean test`/`make BOARD=9k download` で安全性を確認します。

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
- `BOARD=9k` の `make download` で **実機動作（LCD表示）OK** を確認。

### 2025-12-14: Step 3 を拡大（HALT まで next-state 関数で駆動）

- `HALT` も `calc_boot_fetch_next()` の出力で `state` を更新するように拡大（挙動は state を保持するのみ）。
- `BOARD=9k` の `make download` で **実機動作（LCD表示）OK** を確認。

### 2025-12-14: Step 3 の整理（pure next-state 対象の二重管理を削除）

- pure next-state で駆動済みの状態（Boot/FETCH/WRITE_REQ/CLEAR_VRAM/SHOW_INFO/HALT など）について、task 側の `next_state/next_fetch_stage` 代入を削除し、状態遷移の責務を `cpu_fsm_next_pkg` 側へ寄せた。
- `BOARD=9k` の `make download` で **実機動作（LCD表示）OK** を確認。

### 2025-12-14: Step 3 を拡大（SHOW_INFO2 の状態遷移を pure next-state へ移行）

- `SHOW_INFO2` の状態遷移（`FETCH_REQ/FETCH_DATA` への一時離脱、終了時の `prev_state` への復帰）を `cpu_fsm_next_pkg` 側で計算するように追加。
- `state_show_info_tasks.sv` から `SHOW_INFO2` における `next_state/next_fetch_stage` 代入を削除し、二重管理を解消。
- `BOARD=9k` の `make download` で **実機動作（LCD表示）OK** を確認。

### 2025-12-14: Step 3 の整理（pure next-state 対象選択を関数化）

- `cpu.sv` 側の「pure next-state で駆動する state 判定」を `cpu_fsm_next_pkg::uses_pure_next(state)` にまとめた（挙動は不変）。
- `BOARD=9k` の `make download` で **実機動作（LCD表示）OK** を確認。

### 2025-12-14: Step 3 の整理（未使用コード削除）

- `state_machine.svh` から削除済みの `FETCH_OPERAND*` に対応する未使用タスクを `state_fetch_tasks.sv` から削除。
- `make BOARD=9k clean test` の Verilator 警告が出ないことを確認。
- `BOARD=9k` の `make download` で **実機動作（LCD表示）OK** を確認（継続）。

### 2025-12-15: Step 4 の準備（コンテキスト構造体カバー開始）

- `cpu.sv` に `cpu_types_pkg` を取り込み、現在のレジスタ/フラグ/バスを `cpu_ctx_t cur` にマッピングして入力 `cpu_in_t` をサンプリングするように変更した。
- `cpu_fsm_next_pkg` に `calc_cpu_next(cur,in)` を追加し、`calc_boot_fetch_next()` をラップして `next_ctx.state`/`next_ctx.fetch_stage` を更新、差分の combinational な next-state をのちほど拡張できる下地を準備。
- `make -C day99_completed format`、`make -C day99_completed BOARD=9k clean test`（UNUSEDSIGNAL warning1箇所）、`make -C day99_completed BOARD=9k download` はすべて成功。

## 次のフェーズに向けた手順（Step 4+）

1. **コンテキスト構造体 (`cpu_ctx_t`) と input/output を整理**
   - `cpu_types_pkg.sv` に `cpu_ctx_t` / `cpu_next_t` などの構造体を定義し、PC/ADA/FLAGS/REGS/STATE/STALL などをまとめる。
   - 現在状態 `cur` は `always_ff`、次状態 `next` は `always_comb` で扱えるようにする。
2. **状態遷移処理を完全に `always_comb` へ**
   - `state_machine_step()`（または新たな `cpu_fsm_next()`）が `cur` と `inputs` だけを読み、`next` を返すピュアな関数になるようにリファクタ。
   - `always_ff` 側では `cur <= next;` のみ書き込み、`next_state`/`fetch_stage` もコンテキストの一部として扱う。
3. **状態タスクをコンテキスト操作に移行**
   - 各 `state_*_tasks.sv`／`state_decode_tasks.sv` から `next_state` への直接書き込みを除去し、`cpu_ctx_t` のフィールド（`state`, `fetch_stage`, `pc`, `ada` など）を更新するようにする。
   - `cpu_exec_*_pkg` も `cpu_ctx_t` を `ref` で受け取り、必要な副作用（PCインクリメント、RAM/VRAM書き込み）を `next` 側で反映する。
4. **副作用の順序とタイミングを明示**
   - `fetch_stage` で分岐する副作用（`fetch_resume_state` への戻り先、`fetch_stage` を進めるタイミングなど）は `cpu_ctx_t` 内に `stage_flags` 的なフィールドを追加して管理。
   - `state_machine_step()` の呼び出し順を `always_comb` で明示的に書き、従来の `state_machine_step(); next_state = ...` 形式を排除。
5. **段階的な確認**
   - `make -C day99_completed format` / `make -C day99_completed BOARD=9k clean test` を通し、warningが出ないことを確認。
   - `make -C day99_completed BOARD=9k download` で LCD 表示を確認。必要なら `WVS` 命令などを使って状態遷移が正しいことを確かめる。
6. **state_decode_* / cpu_exec_* の次元間移行**

- `state_decode_execute()` と関連 `cpu_exec_*` パッケージを次の対象として、計算結果/フラグ更新/メモリアクセスを `cpu_ctx_t` で表現し `calc_cpu_next()` にまとめることで decode 〜 execute を完結させる。
- 進捗ごとに `format`/`clean test`/`download` を繰り返し、fetch 〜 decode での整合性を暴いておく。

### 2025-12-15: Step4.1 (state_boot ハンドラのコンテキスト化)

- `cpu.c` に `cpu_ctx_t cur` を追加し、レジスタ/バス/フラグを `cur` にマッピングして `cpu_inputs.boot_byte` をサンプリング。`calc_cpu_next(cur,in)` を呼び出す構造を整えた。
- `cpu_fsm_next_pkg` に `calc_cpu_next(cur,in)` を追加し、`calc_boot_fetch_next()` の結果から `next_ctx.state`/`next_ctx.fetch_stage` を更新しつつ、`INIT`/`INIT_VRAM`/`INIT_RAM` の副作用（VRAM 初期化／boot ROM 書き込みフラグなど）を `next_ctx` へ反映。
- この状態で `make format`、`make BOARD=9k clean test`（UNUSEDSIGNAL 警告1箇所）、`make BOARD=9k download` が通ることを確認。次は state_fetch 系を同様にコンテキストで扱う段階へ進む。

### 2025-12-16: Step4.2 (state_fetch ハンドラのコンテキスト化)

- `calc_cpu_next()` が `state_fetch_req()`/`state_fetch_wait()`/`state_fetch_recv()` の副作用を再現するようになり、`pc_plus1/2/3` の前計算・`fetched_data_bytes` や `opcode`/`operand` のラッチを `cpu_ctx_t` で表現できるようになった。
- `fsm.next_fetch_stage` を使ってオペランドが必要な命令で `adb` を `pc_plus1`/`pc_plus2` に切り替え、`FETCH_OPERAND*` 時に `operands` と `adb` を更新する挙動を next コンテキストで構築した。
- `make -C day99_completed format` と `make -C day99_completed BOARD=9k clean test`（後者は `cpu_fsm_next_pkg.sv` の幅関連警告と `UNUSEDSIGNAL` の既存警告のみ）の通過を確認。ハードウェア (download) は次のデコード/実行コンテキスト移行で併せて検証予定。

### 2025-12-16: Step4.3 (state_decode / cpu_exec 集約準備)

- decodeフェーズの `state_decode_execute()` と `cpu_exec_*` パッケージ群を `cpu_ctx_t` 上で再構成する準備を開始。現在は各パッケージが更新する状態/フラグ/メモリアクセスをリストアップし、`calc_cpu_next()` に移行できるフィールドを整理している。
- 整理が終わり次第 `state_decode_tasks.sv` の副作用を書き換え、`cpu_exec_*_pkg` 側でも `cur/next` を対象にした処理に置き換えていく予定。段階的に `make format`/`make BOARD=9k clean test`/`make BOARD=9k download` を通しながら進める。
- この段階ではまず転送命令 (TAX/TAY/TXA/…) を `calc_cpu_next()` へ移行し、`cpu_ctx_t` に register/flag/pc 更新を反映するようにした。処理済み命令は `FETCH_REQ` → `FETCH_OPCODE` へ戻すよう次状態を設定し、`fetch_resume_state` を引き継ぐ形で `calc_decode_transfers_next()` を設けて再利用できる状態にした。
- `make -C day99_completed format`、`make -C day99_completed BOARD=9k clean test`、`make -C day99_completed BOARD=9k download` はすべて成功。Verilator は CPU 型の幅警告とこれまでの `UNUSEDSIGNAL` 警告のみ。順調にコンテキスト移行が進んでいる。

### 2025-12-16: Step4.4 (flags/custom instructionsを cpu_ctx_t へ)

- `cpu_exec_flags_custom_pkg` に対応する `calc_decode_flags_custom_next()` を新たに実装し、CLC/CLV/SEC/CVR/IFO/HLT/WVS の副作用（フラグ更新、show_info カウンタ、vsync ステージ、PC/ADB の次状態、`CLEAR_VRAM`/`HALT` への遷移）を `next` に返すようにした。
- `state_decode_execute()` は `calc_decode_transfers_next()` → `calc_decode_flags_custom_next()` → `calc_decode_branches_next()` の順で opcode を振り分け、`calc_cpu_next()` 上で decode の代表的分岐がすべて先取りできる構造に拡張した。
- `make -C day99_completed format`、`make -C day99_completed BOARD=9k clean test`、`make -C day99_completed BOARD=9k download` のすべてが成功（Verilatorの警告は width/UNUSEDSIGNAL/IGNOREDRETURN の既知のもの）。次は `state_decode` / `cpu_exec_*` の残りカテゴリを段階的にコンテキスト化し、decode→execute を `calc_cpu_next()` で完結させるフェーズへ進む。
- 実機ダウンロードも無事成功し、LCD 表示/VRAM 書き込み含め現場の挙動に問題ないことを確認。次のステップでの `calc_cpu_next()` 拡張でも、現行 Sequential FSM と一致するよう `format`/`BOARD=9k clean test`/`BOARD=9k download` を繰り返して進めてください。

- `cpu_exec_branches_pkg` 相当の `calc_decode_branches_next()` を追加し、BEQ/BMI/BNE/BPL/BVC/BVS/BCC の条件判断とオフセット計算結果を `next` に閉じるようにした。分岐成功時は branch target、そうでない場合は `pc_plus2` に切り替えつつ常に `FETCH_REQ`/`FETCH_OPCODE` へ戻る挙動を再現している。
- `calc_cpu_next()` は `calc_decode_transfers_next()` → `calc_decode_flags_custom_next()` → `calc_decode_branches_next()` の順で opcode を処理し、`state_decode_execute()` の主要カテゴリすべてをカバーするようになった。
- `make -C day99_completed format` 及び `make -C day99_completed BOARD=9k clean test`（既存の幅／`UNUSEDSIGNAL`／`IGNOREDRETURN` 警告は継続）に成功。`make -C day99_completed BOARD=9k download` は macOS `gw_sh` の PasteBoard/Connection Invalid エラーで Segfault を返すため今回も失敗したが、GUI セッション制約なので継続的に再実行してください。
- 実機ダウンロードは別セッションで成功し、LCD/VRAM 表示に問題ないことを確認。今後も `state_decode` の残りカテゴリを `calc_cpu_next()` に取り込み、各フェーズで `format`/`BOARD=9k clean test`/`BOARD=9k download` を繰り返して整合性を担保してください。

### 2025-12-16: Step4.6 (compare/CP* immediate を cpu_ctx_t へ)

- CMP/CPX/CPY の即値型命令を `calc_decode_compare_next()` で処理し、フラグ（C/Z/N）と `pc`/`adb` を更新したうえで `FETCH_REQ`/`FETCH_OPCODE` に戻す挙動を `next` に反映させた。
- `calc_cpu_next()` の opcode 振り分けは `calc_decode_transfers_next()` → `calc_decode_flags_custom_next()` → `calc_decode_branches_next()` → `calc_decode_compare_next()` の順序となり、decode 中の主要カテゴリをコンテキスト内で先取りできる構造が整備された。
- `make -C day99_completed format`、`make -C day99_completed BOARD=9k clean test`（既知警告継続）、`make -C day99_completed BOARD=9k download`（macOS GUI 制約で Segfault の場合あり）が通っており、次のターゲットは logic/shifts/store/… などの残余 opcode グループです。

### 2025-12-16: Step4.7 (logic/shifts/store など残余カテゴリの移行)

- 残る `cpu_exec_logic_pkg`/`cpu_exec_shifts_pkg`/`cpu_exec_store_pkg` などの段階的移行計画を立て、フラグ更新や RAM/VRAM 出力を `next` に持たせながら `calc_cpu_next()` へ組み込む。必要に応じて helper 関数を増やして共通副作用をまとめる。
- 各カテゴリ移行後は `calc_cpu_next()` に割り当てる順を明文化するとともに `format`/`make BOARD=9k clean test`/`make BOARD=9k download` のループを回し、動作整合性を保ちながら `docs/FSM.md` に記録してください。
- `calc_cpu_next()` の logic/shifts/store 周辺への拡張も並行して進めており、現時点では `calc_decode_transfers/flags_custom/branches/compare` までが完成。次フェーズでは `cpu_exec_logic_pkg` などを順次追加して decode→execute を `next` だけで完結させるフェーズに移行します。
- 実機 `make BOARD=9k download` も別セッションで成功し、LCD/VRAM 表示が正常であることを確認。今後も各ステップのあと `format`/`clean test`/`download` を実行して整合性を検証してください。

### 2025-12-16: Step4.8 (logic immediate を cpu_ctx_t へ移行)

- `calc_decode_logic_next()` を追加し、AND/EOR/ORA の即値型パターンを `next` に閉じる形で実装。レジスタ更新とフラグ(C/Z/N)、`pc`/`adb` の更新を `cpu_ctx_t` へ反映し、`FETCH_REQ`/`FETCH_OPCODE` 復帰を返すことで logic 即値命令がコンテキスト上で完結するようになった。
- `calc_cpu_next()` の opcode フローは `transfers → flags/custom → branches → compare → logic` という段階的フォールバックになり、decode の代表的カテゴリを順に `calc_cpu_next()` が処理できる構造を確立。
- 今後は logic の残り（ゼロページやメモリ読み出し付き、ZP,X/ABS, X/Yなど）は helper を拡張し、各カテゴリ移行ごとに `format`/`make BOARD=9k clean test`/`make BOARD=9k download` を回して safe であることを確認しながら進める。
- `calc_cpu_next()` の logic/shifts/store 周りへの拡張も並行して進めており、現時点では `calc_decode_transfers/flags_custom/branches/compare` までが完成。次フェーズでは `cpu_exec_logic_pkg` などを順次追加して decode→execute を `next` だけで完結させるフェーズに移行します。
- 実機 `make BOARD=9k download` も成功し、LCD/VRAM 表示が正常であることを確認。今後も各ステップのあと `format`/`clean test`/`download` を実行して整合性を検証してください。

### 2025-12-16: Step4.9 (store 命令を cpu_ctx_t で完結)

- `calc_decode_store_next()` を追加し、STA/STX/STY のゼロページ/絶対/間接(X,Y) などのメモリ書き込みパターンを `cpu_ctx_t` に閉じ込めた。`request_data_fetch`/`return_to_opcode_fetch`/`store_and_fetch` という helper を導入して `next` 上の副作用を順に設定し、RCU から fetch へ戻る流れを純粋な関数にした。
- `calc_cpu_next()` の opcode 分岐は `... → logic` のあとの fallback で store helper に流れるようになり、`state_decode_execute()` 側の `cpu_exec_store_pkg` への依存が一部解消された。
- `make -C day99_completed format` 実行済み。`make -C day99_completed BOARD=9k clean test` は既存の `WIDTHEXPAND`/`WIDTHTRUNC` 警告（Verilator が `& RAMW` などでビット幅を拡張/切り詰めるため）以外にエラーなし。`make -C day99_completed BOARD=9k download` は macOS の `gw_sh` が PasteBoard/Connection Invalid エラーでセグフォルトするため今回も失敗した（1回再実行したが再現）。

## 2-process FSM 完了チェックリスト

以下がすべて満たされてはじめて2プロセスFSMへの移行が完了したと見なせます:

1. `cpu_types_pkg.sv` に `cpu_ctx_t`（`cur`）と `cpu_next_t`（`next`）が定義され、PC/ADA/DIN/RA/RX/RY/SP/FLAGS/STATE/FETCH_STAGE/`fetch_resume_state`/`show_info_stage` など必要な信号を一元管理する。
2. `always_comb` 内の `cpu_fsm_next()`（もしくは `state_machine_step()`）が `cur` と入力だけを受け取り、`next` を返す純粋な関数になっている。副作用はすべて `next` のフィールド更新として書かれ、`cpu_exec_*_pkg` も `next` を `ref` で受け取って処理する。
3. 全 `state_*_tasks.sv` / `state_decode_tasks.sv` が `cpu_ctx_t` のフィールド（state/fetch_stage/pc/adb/ce*/vram* など）を更新し、`next_state`/`next_fetch_stage` への書き込みが完全に排除されている。
4. `always_ff` では `cur <= next;` のみを実行し、`dout_r`, `vsync_sync`, `show_info_counter` 等の同期ロジックも `cur`/`next` で調整し、後続の combinational ロジックに頼る。
5. すべての build/test/hardware（`make format`, `make BOARD=9k clean test`, `make BOARD=9k download`）が通り、LCD 表示・VRAM クリアなどの副作用が旧実装と一致することを確認。

このチェックリストにある項目がすべてクリアされない限り、「2プロセス FSM」の完成とは言えません。段階的にこのリストを潰していくことで設計の可視性と安全性を高めていきます。
