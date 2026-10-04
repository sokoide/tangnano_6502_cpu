# Day18からDay99へ

Day18 と Day99 は同じ CPU ファイルをそのまま使う構成ではありません。まず `day99_completed` に入り、`make test` と、使用するボードを指定したビルドを行います。

| 項目              | Day18                                                       | Day99                                                                                          |
| ----------------- | ----------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| CPU制御           | `cpu.sv` の単一 `always_ff` にFSMと命令処理                 | `cpu_ctx_t` の現在値から `calc_cpu_next` で次状態を計算し、`always_ff` で取り込む2-process FSM |
| CPUの演算・decode | CPU内に実装                                                 | `cpu_fsm_next_pkg.sv` 内に実装。独立 `cpu_alu.sv` / `cpu_decoder.sv` はCPU未接続               |
| 起動              | `boot_loader.sv` が `rom.sv` の256バイトを `$0200` へコピー | アセンブルしたブートイメージからCPUがRAMを初期化                                               |
| VRAM              | CPUアドレス空間に未接続。LCD側の表示FSMをCVR/IFOで制御      | CPUから `$E000–$E3FF` へ文字を書ける。読出し用コピーは `$7C00–$7FFF`                           |
| WVSの回数         | `max(1,N)` 回。0も1回                                       | `N+1` 回。0は1回、1は2回                                                                       |
| 未対応opcode      | 各Dayのdefault処理に依存                                    | fault停止。サブセット外命令を黙って実行しない                                                  |

Day18 の `WVS #$3A` は 58 回待ち、Day99 で同じ回数待つオペランドは `$39` です。独自命令は標準 6502 アセンブラが認識しないため、サンプルと同じように `.byte` で表現します。

## 同期RAMを読むときの時間

Day10–18 の CPU は `memory_ready` と `step_pending` で RAM の読出し待ちと実行許可を扱います。下表は 1 つの要求を発行した後の代表的な流れです。ノンブロッキング代入の右辺はエッジ直前の値を読むため、RAM と CPU が同じエッジで動いても、新しい RAM 出力をそのエッジで CPU が取り込むことはできません。

| エッジ | CPU                                                           | 同期RAM                              |
| ------ | ------------------------------------------------------------- | ------------------------------------ |
| t0     | FSMが要求アドレスを出力、`memory_ready=0`                     | エッジ直前のアドレスを読む           |
| t1     | 待機し `memory_ready=1`。enable要求を保存                     | t0で出したアドレスを読み、出力を更新 |
| t2     | enableまたは保存済み要求があれば、t1の読出し結果でFSMを進める | 現在のアドレスを読む                 |

書込みは `write_en` と有効アドレス・データの組で RAM に受理されます。Day18 では表示 FSM が RAM を使う間、`memory_hold` で CPU を待たせます。

各 Day の CPU 単体テストにある `assign data_in = mem[address_bus]` は非同期読出しモデルです。その合格だけでは BSRAM の待ち時間を確認できません。completed の `make test-sync` は同期 RAM で連続実行と間欠 enable を確認します。Day99 ではさらに登録済み読出し経路を使います。

## 自分のプログラムを動かす

```bash
cd day99_completed
make prog PROG=simple   # examples/simple.sからブートROMを生成
make BOARD=9k          # 合成・配置配線。20KならBOARD=20k
make BOARD=9k download
```

生成ファイルを直接編集せず、`examples/*.s` を変更してください。[命令契約](../day99_completed/docs/INSTRUCTIONS.md)で対応命令・メモリ配置を確認してからプログラムを書きます。割り込み、decimal 演算、NMOS 6502 のサイクル完全互換は対象外です。

シミュレーション、配置配線のタイミング結果、ボード上の起動・表示はそれぞれ別に確認します。
