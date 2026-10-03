# Day10–18 同期RAM / Day18所有権修正の実装結果

2026-10-03、実装・検証モデル: GPT 6.1 Sol。
設計: `REVIEW_SOL_CURRICULUM_DESIGN_ja.md`。
Makefiles は親 agent が統合し、GLM の vendor/generated/gprj は変更していない。
commit/push/program/Vault/memory 更新なし。

## 実装

- Day10–18 の starter/completed `ram.sv` 全 18 本を 1clock 同期 read モデルへ変更。
  hardware の Gowin clocked SDPB interface と read 待ち契約を揃えた。
  同 edge read/write collision の値には依存しない設計とした。
- completed CPU 全 9 本へ `memory_ready` と `step_pending` を追加。
  state 実行後に 1clock settle し、reset 解除後も first read を prime する。
  settle 中に到着する manual enable pulse は 1bit pending へ保存し、一度だけ実行する。
  write_en を enable の外で毎 clk default0 にし、RAM write は発行後の 1edge だけ受理する。
- Day07 completed の debug_pc を input から output へ修正。
- Day18 CPU に memory_hold を追加。hold 中は architectural state を保持し、
  memory_ready を無効化する。release 後は CPU address を再 read してから resume する。
  CVR/IFO 出力も 1clock pulse となった。
- Day18 WVS は毎 clk vsync edge を観測し、WAIT_VSYNC を enable/settle とは独立に進める。
  manual stepping 停止中も edge を count する。count=0/1 は 1edge で終了する既存契約を保持。
  次の opcode の実行は CPU enable 契約に戻る。
  top では LCD domain の vsync を 2 段同期して CPU へ供給する。
- Day18 top は boot/debug/CPU の address/write_en/din を一体で選択。
  reset 中 write を禁止、boot 優先、debug 中は RAM write を常に 0 とする。
- IFO 受付で PC/A/X/Y/P/S を capture し、render 中 CPU を停止する。
  PC は IFO 退役後の next instruction address。
  RAM dump は address→wait→capture の後、同じ debug_byte から両 nibble/bit を作る。
- CVR は clear-only として 1024 cell へ space を書いて完了する。
  IFO は clear→regs→dump。最後の registered VRAM write を S_DRAIN で retire してから release する。
- Day18 starter/completed の simulation VRAM に write port を接続し、1024 cell を保持。
  以前の read-only モデルを信号観測だけで合格と扱う問題を解消した。
- starter Day18 CPU へ interface/read 待ち/pulse scaffold だけ追加し、命令 TODO を残した。
  他 starter CPU の課題は解答で埋めていない。
  shared Day18 TB には memory_hold 接続と、watchdog で bounded な WVS 開始待ちを追加。

CPU の fullspeed microstate throughput は settle 挿入により最大 1/2。
6502 の実 cycle 数を再現する変更ではない。WVS の device event 観測は毎 clk 動作する。
pending は 1bit なので、単一 settle 期間に複数の独立 step 要求を queue する interface ではない。

## 独立検証

新 TB は root `sim/` に置き、実物の各 completed CPU と実 `ram.sv` を接続する。
all-pass だけでなく、write transaction の address/data/受理回数を検査する。
各 TB に fatal と有界 watchdog を設け、--assert 付きで実行した。

| 検証 | 結果 |
| --- | --- |
| `tb_curriculum_sync`、Day10–18 × STEP_PERIOD=1/4/16 | 27件build/run exit 0、Fatal/Errorなし |
| 最初のwrite発行直後に12clock enableを停止 | PHA/JSR計3writeを正しいaddress/dataで1回ずつ受理、停止中PC保持 |
| `tb_manual_step`、Day10実CPU/RAM | settle中の単発pulseを2回ともqueueし、enableなしで再実行しない、exit 0 |
| shared `make test-cpu`、Day07–18 | 12件exit 0。Day07 interface修正も実buildで確認 |
| `tb_day18_vsync` | manual停止中の短いsettle-cycle edgeをWVS #2で2回count、#0は1edge、exit 0 |
| Day18 top統合、通常 | boot256byte全一致、CVR1024write/全cell確認、全regs snapshot/128byte dump一致、resume store/HLT、exit 0 |
| Day18 top統合、IFO途中reset | busy/requestの残りを再生せずbootから再開始し、同じ検証pass、exit 0 |
| Day18 top統合、repeated/mixed requests | IFO3回/CVR2回、後続store、snapshot/dump一致、exit 0 |
| starter Day18 top `--lint-only` | exit 0。既存幅warningと未実装TODOは残る |
| 旧Day10 CPU + 新同期RAMのnegative control | PHA write mismatch、exit 1。新TBが旧待ち不足を検出 |

shared TB は非同期 memory を残した命令ロジック検査であり、同期 RAM の証拠は追加 TB に依拠する。
CPU を force して進める試験はしていない。
Day18 統合では bootstrap 用の combinational fixture ROM だけを TB 内で置換し、
production の top/CPU/boot_loader/RAM/VRAM を使う。production `rom.sv` と同時 compile しない。

### 再実行コマンド

同期 RAM TB を各 Day から実行する。DAY18_CPU define は Day18 だけ必要。

```sh
cd day10_completed
mkdir -p /private/tmp/sol-curriculum/day10-p1
verilator --binary --timing --assert -Wno-fatal \
  --top-module tb_curriculum_sync -GSTEP_PERIOD=1 \
  --Mdir /private/tmp/sol-curriculum/day10-p1 \
  ../sim/tb_curriculum_sync.sv cpu.sv ram.sv
/private/tmp/sol-curriculum/day10-p1/Vtb_curriculum_sync
```

Day11–18、period4/16 へ同じ command を適用した。
Day18 は `+define+DAY18_CPU` を追加する。
実行一覧: `/private/tmp/sol-curriculum/sync-results.json`。
logs: 同 directory の `dayXX-pN-build.log` / `dayXX-pN-run.log`。

```sh
cd day10_completed
mkdir -p /private/tmp/sol-curriculum/manual
verilator --binary --timing --assert -Wno-fatal --top-module tb_manual_step \
  --Mdir /private/tmp/sol-curriculum/manual \
  ../sim/tb_manual_step.sv cpu.sv ram.sv
/private/tmp/sol-curriculum/manual/Vtb_manual_step

cd ../day18_completed
mkdir -p /private/tmp/sol-curriculum/vsync
verilator --binary --timing --assert -Wno-fatal --top-module tb_day18_vsync \
  --Mdir /private/tmp/sol-curriculum/vsync \
  ../sim/tb_day18_vsync.sv cpu.sv ram.sv
/private/tmp/sol-curriculum/vsync/Vtb_day18_vsync
```

top 統合は以下を `(RESET_DURING_INFO, REPEAT_REQUESTS)=(0,0),(1,0),(0,1)` で実行する。

```sh
cd day18_completed
mkdir -p /private/tmp/sol-curriculum/integrated-0-0
verilator --binary --timing --assert -Wno-fatal --top-module tb_day18_integration \
  -GRESET_DURING_INFO=0 -GREPEAT_REQUESTS=0 \
  --Mdir /private/tmp/sol-curriculum/integrated-0-0 \
  ../sim/tb_day18_integration.sv sim/Gowin_rPLL9_stub.sv \
  lcd_demo.sv cpu.sv boot_loader.sv ram.sv \
  lcd/lcd.sv lcd/vram.sv lcd/font_rom.sv
/private/tmp/sol-curriculum/integrated-0-0/Vtb_day18_integration
```

一覧: `/private/tmp/sol-curriculum/integration-results.json`。
logs: `integrated-R-P-build.log` / `integrated-R-P-run.log`。
shared tests: `shared-results.json` / `shared-dayXX.log`。
negative control: `old-cpu-build.log` / `old-cpu-run.log`。
変更範囲の `git diff --check` は exit 0。

試験作成途中に success 後も同評価内で timeout へ fallthrough する TB を修正した。
最終試験は completed flag と loop break を使い、exit 0 と PASS だけでなく
Fatal/Error が log にないことを確認した。

## 教材と残る境界

親 agent が修正した Day05 README は PC/reset/enable を本課題、独立 register file を追加課題と
区別し、現 completed と整合する。Day06 も LDA/A/PC と独立 decoder/flag 部品を分離している。
Day06 starter には pc_enable port がないので、保持の指示を completed 限定にするか、
starter へ port 追加する手順を明示する点を親 agent へ報告した。

Day10 以降の既存 cycle 表を hardware clock 数の検証結果として扱わない。
新同期 wait/pulse/hold 契約を教材実装の基礎とし、starter の TODO が未完了なら
CPU test の失敗を expected incomplete と区別する。

未検証: Gowin synthesis/実 primitive の collision 特性/実機での fullspeed/LCD 描画/長期安定性。
既存 VRAM multi-bit read-address CDC と font read の hardware timing はこの修正では再設計していない。
hardware 受入と、親 agent による全体 make test の最終結果は別に記録する。
