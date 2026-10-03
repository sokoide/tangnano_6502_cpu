# GPT 6.1 Sol: GLM成果物の独立レビュー

2026-10-03。対象は実際のworking tree diff、GLM CPU99/Flash報告、
Day 05–18 Makefile/TB、Day 99 FSM/CPU回帰TB。
GLM lessons再開sessionがMakefile等を編集中なので、以下のMakefile指摘は
レビュー時snapshotに対するもので、最終版では再確認する。
RTLは変更していない。先行して許可された独立ALU新TBの追加と実行は別項に記す。

## Sol実装前の必須修正

| 優先度 | 指摘 / 証拠 | 必要な修正 |
| --- | --- | --- |
| P1 | root `Makefile` の `test: sim` は各Dayの `sim` しか呼ばず、新 `test-cpu` を素通りする | root testは各completedのtestを呼び、Day99 CPU/ALU regressionもtestに統合する |
| P1 | `day07_completed/cpu.sv` のdebug_pcがinput宣言なのにassignされる。独立compileはASSIGNINでexit 1 | debug_pcをoutputへ訂正し、実DUT再build/runを確認する |
| P2 | Day99 TB checkpoint0はRAM初期値0と期待値0が一致し、未書込でもpass | checkpoint領域を期待値と異なるsentinelで初期化、またはwrite eventを記録する |
| P2 | Day05–18 CPU build先 `obj_tb_cpu` が.gitignore外。既存generated directoriesが多数untracked | ignored `build/`配下等へ統一し、今回生成したartifactのみ整理する |
| P2 | 各Day LCD sim-buildはBOARDに関係なくtop_9k固定、--assertなし、共通obj_dir | selected wrapper、board/top別builddir、assert有効化を最終Makefileで確認する（GLM再開session担当） |
| P2 | root formatのfindはvendor/generated SVも対象のまま | vendor/generatedを対象から除外する。Flash変更はtextlint除外のみでこの問題は解消していない |

Day99のCMP absolute / abs,X / abs,Y、CPX absolute、CPY absolute
(`CD/DD/D9/EC/CC`) はfetch分類も実行handlerも未実装。
これは今回GLM変更による回帰ではなく、明示された未完了項目。
memory compare全対応の完了判定にはfetch分類とhandler、回帰testの追加が必須。
「即値のabsolute形式」というGLM報告の表現は「absolute形式」とするのが正確。

## Day99 CPU: 実装の評価と検証限界

RTSはstage 1の下位byteとstage 2の `cur.dout_r` 上位byteを結合してから+1する。
BCSは既存branch共通経路へC条件を追加する。
compare helperは8bit `lhs-operand` のZ/N、unsigned大小のCだけを書き、sourceとVを変更しない。
zero-page/X wrap、indirect pointer high byte wrapの式も8bit幅を保持する。
これらの変更自体に新しい不具合は見つからなかった。
既存RAMW15/RAMW16 mask、boot長、未対応命令の停留は後続Sol修正範囲として残る。

実物 `src/cpu.sv` をTB独立同期RAMへ接続して再build/runした。

```sh
mkdir -p /private/tmp/sol-glm-review/day99-cpu
cd day99_completed
verilator --binary --timing --assert -Wno-fatal -Iinclude -Isrc \
  --Mdir /private/tmp/sol-glm-review/day99-cpu --top-module tb_cpu_regression \
  src/cpu.sv src/tb_cpu_regression.sv \
  > /private/tmp/sol-glm-review/day99-build.log 2>&1
cd /private/tmp/sol-glm-review
./day99-cpu/Vtb_cpu_regression > day99-run.log 2>&1
```

build/run exit 0、12 checkpoint表示pass、t=28070。
GLMが報告したネガティブコントロールは今回再実行していない。

TBの拡充が必要な点:

- checkpoint0は上記の初期値一致による未書込検出漏れがある。
- headerはVとsource保存をうたうが、programはV=1を準備せず、BVS/BVCも使わない。
  compare直後にAをcheckpoint番号で上書きするため、A保存を直接確認しない。
  X/Yの保存もTBが明示的に観測しない。
- compareごとに入力Cの両値を同operandで確認せず、間接pointer `$FF->$00`、
  indexed page crossing、address境界も不足。
- 入れ子RTSとcross-page returnは実行するが、最終SP復元やstack byte/write回数を直接確認しない。
- done sentinelで終了し、HLT後PC/state不変は検査しない。
- TB RAMはcebを無視して毎clk読む。実際のread enable契約を検証するTBではない。
- boot off-by-oneは余分なNOPで吸収している。boot修正後はlength=1/最大長で
  write count、最終byte、範囲外read/writeを専用TBで確認する。

V=0/1とsource register保存、SP復元、入力C両値、absolute compareを
次のCPU99回帰拡充へ渡す。現TB passを命令全形式・実機の証明として扱わない。

## Day05–18: 実DUTと新TBの独立実行

各completedのworking directoryで、starter内のshared TBと**そのcompletedのcpu.sv**を
明示してVerilatorを実行した。別DayのDUTをcompileする問題は見つからなかった。
Day06/08/10のinterface defineは各Makefileと同じものを使用した。

```text
verilator --binary --timing --assert -Wno-fatal --top-module tb_cpu
  --Mdir /private/tmp/sol-glm-review/dayXX-cpu [interface define]
  ../dayXX/sim/tb_cpu.sv cpu.sv
/private/tmp/sol-glm-review/dayXX-cpu/Vtb_cpu
```

結果一覧: `/private/tmp/sol-glm-review/results.json`。
各Dayのbuild/run logs: `dayXX-cpu-build.log` / `dayXX-cpu-run.log`、同directory内。

- completed Day05/06/08/09/10/11/12/13/14/15/16/17/18: 13件build/runともexit 0。
- completed Day07: build exit 1、run未実行。
  `cpu.sv:98 Assigning to input/const variable: debug_pc`。
- starterはTODOを含むため今回runしていない。starterをcompletedと同じpass数に数えない。

shared TBはbounded wait、post-NBA sampling、error_countをfatalへ伝播するよう改善されている。
Day15 compare/INC/DEC、Day18 custom instructionsとJSR/RTSも明示的な検査が追加された。
Day06/08/10のconditional interfaceは存在しないportを接続する誤りを避けるもので、
今回読んだ差分でstarterを無条件passにする弱化は見つからなかった。
特にDay10 starterのstack memory検査はunguardedで未実装なら失敗する。

ただしDay10–18のTBは依然 `assign data_in=mem[address_bus]` の非同期memoryである。
実RAM同期read、疎なenableでのwrite回数、Day18表示中のRAM arbitrationを検証しない。
このpassとhardware受入は分離する。
後続設計は `REVIEW_SOL_CURRICULUM_DESIGN_ja.md` を参照。

## Flash成果物

root build/sim/cleanの失敗伝播、LED時刻計算、LDA即値表記、Day18 opcode、
Day99実階層と単体ALU未接続の訂正はコードと整合する。
CPU命令suiteが未統合という文書は現在のroot/Day99 Makefileには正しいが、
Sol統合後はtest説明を更新する。
textlint実行、Gowin build、LCD/CPU実機確認は今回行っていない。

## 先行ALU永続TBの状態

`src/tb_alu_regression.sv` はGPT 6.1 Solにより新規追加済み。
整数加減算とsigned rangeから独立期待値を計算し、DUTのoverflow bit式を複製しない。
--assert、fatal、500000ns timeout付きで393216 vectorsを完走しexit 0。

build log: `/private/tmp/alu-sol-permanent-build.log`。
run log: `/private/tmp/alu-sol-permanent-run.log`。
初回はtmp親directory未作成でbuild失敗し、mkdir後に同commandを再実行して成功。
詳細commandと結果は `REVIEW_SOL_TOOLS_ja.md` に追記済み。
Makefile統合は親agent担当。

判定: Day99限定修正はレビュー通過。全体のtest入口は上の必須修正と
GLM再開session最終版の再検証が必要。commit/pushなし。
