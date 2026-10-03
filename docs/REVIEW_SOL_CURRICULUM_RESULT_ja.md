# Day10–18 同期RAM / Day18所有権修正の実装結果

2026-10-03、実装・検証モデル: GPT 6.1 Sol。
設計: `REVIEW_SOL_CURRICULUM_DESIGN_ja.md`。
Makefilesは親agentが統合し、GLMのvendor/generated/gprjは変更していない。
commit/push/program/Vault/memory更新なし。

## 実装

- Day10–18のstarter/completed `ram.sv` 全18本を1clock同期readモデルへ変更。
  hardwareのGowin clocked SDPB interfaceとread待ち契約を揃えた。
  同edge read/write collisionの値には依存しない設計とした。
- completed CPU全9本へ `memory_ready` と `step_pending` を追加。
  state実行後に1clock settleし、reset解除後もfirst readをprimeする。
  settle中に到着するmanual enable pulseは1bit pendingへ保存し、一度だけ実行する。
  write_enをenableの外で毎clk default0にし、RAM writeは発行後の1edgeだけ受理する。
- Day07 completedのdebug_pcをinputからoutputへ修正。
- Day18 CPUにmemory_holdを追加。hold中はarchitectural stateを保持し、
  memory_readyを無効化する。release後はCPU addressを再readしてからresumeする。
  CVR/IFO出力も1clock pulseとなった。
- Day18 WVSは毎clk vsync edgeを観測し、WAIT_VSYNCをenable/settleとは独立に進める。
  manual stepping停止中もedgeをcountする。count=0/1は1edgeで終了する既存契約を保持。
  次のopcodeの実行はCPU enable契約に戻る。
  topではLCD domainのvsyncを2段同期してCPUへ供給する。
- Day18 topはboot/debug/CPUのaddress/write_en/dinを一体で選択。
  reset中writeを禁止、boot優先、debug中はRAM writeを常に0とする。
- IFO受付でPC/A/X/Y/P/Sをcaptureし、render中CPUを停止する。
  PCはIFO退役後のnext instruction address。
  RAM dumpはaddress→wait→captureの後、同じdebug_byteから両nibble/bitを作る。
- CVRはclear-onlyとして1024 cellへspaceを書いて完了する。
  IFOはclear→regs→dump。最後のregistered VRAM writeをS_DRAINでretireしてからreleaseする。
- Day18 starter/completedのsimulation VRAMにwrite portを接続し、1024 cellを保持。
  以前のread-onlyモデルを信号観測だけで合格と扱う問題を解消した。
- starter Day18 CPUへinterface/read待ち/pulse scaffoldだけ追加し、命令TODOを残した。
  他starter CPUの課題は解答で埋めていない。
  shared Day18 TBにはmemory_hold接続と、watchdogでboundedなWVS開始待ちを追加。

CPUのfullspeed microstate throughputはsettle挿入により最大1/2。
6502の実cycle数を再現する変更ではない。WVSのdevice event観測は毎clk動作する。
pendingは1bitなので、単一settle期間に複数の独立step要求をqueueするinterfaceではない。

## 独立検証

新TBはroot `sim/` に置き、実物の各completed CPUと実 `ram.sv` を接続する。
all-passだけでなく、write transactionのaddress/data/受理回数を検査する。
各TBにfatalと有界watchdogを設け、--assert付きで実行した。

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

shared TBは非同期memoryを残した命令ロジック検査であり、同期RAMの証拠は追加TBに依拠する。
CPUをforceして進める試験はしていない。
Day18統合ではbootstrap用のcombinational fixture ROMだけをTB内で置換し、
productionのtop/CPU/boot_loader/RAM/VRAMを使う。production `rom.sv` と同時compileしない。

### 再実行コマンド

同期RAM TBを各Dayから実行する。DAY18_CPU defineはDay18だけ必要。

```sh
cd day10_completed
mkdir -p /private/tmp/sol-curriculum/day10-p1
verilator --binary --timing --assert -Wno-fatal \
  --top-module tb_curriculum_sync -GSTEP_PERIOD=1 \
  --Mdir /private/tmp/sol-curriculum/day10-p1 \
  ../sim/tb_curriculum_sync.sv cpu.sv ram.sv
/private/tmp/sol-curriculum/day10-p1/Vtb_curriculum_sync
```

Day11–18、period4/16へ同じcommandを適用した。
Day18は `+define+DAY18_CPU` を追加する。
実行一覧: `/private/tmp/sol-curriculum/sync-results.json`。
logs: 同directoryの `dayXX-pN-build.log` / `dayXX-pN-run.log`。

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

top統合は以下を `(RESET_DURING_INFO, REPEAT_REQUESTS)=(0,0),(1,0),(0,1)` で実行する。

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
変更範囲の `git diff --check` はexit 0。

試験作成途中にsuccess後も同評価内でtimeoutへfallthroughするTBを修正した。
最終試験はcompleted flagとloop breakを使い、exit 0とPASSだけでなく
Fatal/Errorがlogにないことを確認した。

## 教材と残る境界

親agentが修正したDay05 READMEはPC/reset/enableを本課題、独立register fileを追加課題と
区別し、現completedと整合する。Day06もLDA/A/PCと独立decoder/flag部品を分離している。
Day06 starterにはpc_enable portがないので、保持の指示をcompleted限定にするか、
starterへport追加する手順を明示する点を親agentへ報告した。

Day10以降の既存cycle表をhardware clock数の検証結果として扱わない。
新同期wait/pulse/hold契約を教材実装の基礎とし、starterのTODOが未完了なら
CPU testの失敗をexpected incompleteと区別する。

未検証: Gowin synthesis/実primitiveのcollision特性/実機でのfullspeed/LCD描画/長期安定性。
既存VRAM multi-bit read-address CDCとfont readのhardware timingはこの修正では再設計していない。
hardware受入と、親agentによる全体make testの最終結果は別に記録する。
