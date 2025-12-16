# 2-process FSM（完了）

このCPUは **2-process FSM**（`always_comb` で `next` を計算し、`always_ff` で `cur <= next` を更新）へ移行完了しています。

## 現状の構造

- 状態保持: `day99_completed/src/cpu.sv` の `cpu_ctx_t cur`
- 次状態計算: `day99_completed/src/cpu/cpu_fsm_next_pkg.sv` の `calc_cpu_next(cur,in) -> next`
- 更新: `day99_completed/src/cpu.sv` の `always_ff` は `cur <= next;` のみ（同期系も `next` 側で計算）

## 完了したこと（チェック）

- boot/fetch/decode/execute/write/show_info/clear_vram の各状態が `calc_cpu_next()` で完結
- `IFO`（show-info ROM）も `cpu_fsm_next_pkg.sv` 側に統合して純粋な次状態計算で進行
- legacy経路を `day99_completed/src/cpu/legacy/` に隔離（現行ビルドでは未使用）
  - `state_*_tasks.sv` / `state_machine.svh` / `cpu_tasks.svh` / `cpu_exec_*_pkg.sv` / `cpu_2proc_skeleton.sv`
- `cpu_ctx_t` をスリム化（未使用だった `next_state`/`next_fetch_stage` を削除）

## 検証結果

- シミュ: `make -C day99_completed clean test` が PASS
- 実機: `make -C day99_completed BOARD=9k download` で稼働確認済み（LCD更新 / `CVR` / `IFO`）

## 完了後の整備（残タスク）

1. **未実装命令/割り込み方針の明記**
   - BRK/IRQ/NMI など未対応領域の扱いを docs に明記（未実装のまま/実装する/エラー扱い等）。
2. **警告整理（任意）**
   - 追加で削減したい警告があれば、最小の型幅修正/キャストで対応（現状は実害のないものは抑制済み）。
3. **`cpu_ctx_t` の再整理（任意）**
   - 状態・出力・デバッグの分離、未使用フィールドの追加削除など（影響が大きいので最後）。
