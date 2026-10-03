# GPT 6.1 Sol: GLM成果物の独立レビュー

2026-10-03。対象は実際の working tree diff、GLM CPU99/Flash 報告、
Day 05–18 Makefile/TB、Day 99 FSM/CPU 回帰 TB。
GLM lessons 再開 session が Makefile 等を編集中なので、以下の Makefile 指摘は
レビュー時 snapshot に対するもので、最終版では再確認する。
RTL は変更していない。先行して許可された独立 ALU 新 TB の追加と実行は別項に記す。

## Sol実装前の必須修正

| 優先度 | 指摘 / 証拠 | 必要な修正 |
| --- | --- | --- |
| P1 | root `Makefile` の `test: sim` は各Dayの `sim` しか呼ばず、新 `test-cpu` を素通りする | root testは各completedのtestを呼び、Day99 CPU/ALU regressionもtestに統合する |
| P1 | `day07_completed/cpu.sv` のdebug_pcがinput宣言なのにassignされる。独立compileはASSIGNINでexit 1 | debug_pcをoutputへ訂正し、実DUT再build/runを確認する |
| P2 | Day99 TB checkpoint0はRAM初期値0と期待値0が一致し、未書込でもpass | checkpoint領域を期待値と異なるsentinelで初期化、またはwrite eventを記録する |
| P2 | Day05–18 CPU build先 `obj_tb_cpu` が.gitignore外。既存generated directoriesが多数untracked | ignored `build/`配下等へ統一し、今回生成したartifactのみ整理する |
| P2 | 各Day LCD sim-buildはBOARDに関係なくtop_9k固定、--assertなし、共通obj_dir | selected wrapper、board/top別builddir、assert有効化を最終Makefileで確認する（GLM再開session担当） |
| P2 | root formatのfindはvendor/generated SVも対象のまま | vendor/generatedを対象から除外する。Flash変更はtextlint除外のみでこの問題は解消していない |

Day99 の CMP absolute / abs,X / abs,Y、CPX absolute、CPY absolute
(`CD/DD/D9/EC/CC`) は fetch 分類も実行 handler も未実装。
これは今回 GLM 変更による回帰ではなく、明示された未完了項目。
memory compare 全対応の完了判定には fetch 分類と handler、回帰 test の追加が必須。
「即値の absolute 形式」という GLM 報告の表現は「absolute 形式」とするのが正確。

## Day99 CPU: 実装の評価と検証限界

RTS は stage 1 の下位 byte と stage 2 の `cur.dout_r` 上位 byte を結合してから+1 する。
BCS は既存 branch 共通経路へ C 条件を追加する。
compare helper は 8bit `lhs-operand` の Z/N、unsigned 大小の C だけを書き、source と V を変更しない。
zero-page/X wrap、indirect pointer high byte wrap の式も 8bit 幅を保持する。
これらの変更自体に新しい不具合は見つからなかった。
既存 RAMW15/RAMW16 mask、boot 長、未対応命令の停留は後続 Sol 修正範囲として残る。

実物 `src/cpu.sv` を TB 独立同期 RAM へ接続して再 build/run した。

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

build/run exit 0、12 checkpoint 表示 pass、t=28070。
GLM が報告したネガティブコントロールは今回再実行していない。

TB の拡充が必要な点:

- checkpoint0 は上記の初期値一致による未書込検出漏れがある。
- header は V と source 保存をうたうが、program は V=1 を準備せず、BVS/BVC も使わない。
  compare 直後に A を checkpoint 番号で上書きするため、A 保存を直接確認しない。
  X/Y の保存も TB が明示的に観測しない。
- compare ごとに入力 C の両値を同 operand で確認せず、間接 pointer `$FF->$00`、
  indexed page crossing、address 境界も不足。
- 入れ子 RTS と cross-page return は実行するが、最終 SP 復元や stack byte/write 回数を直接確認しない。
- done sentinel で終了し、HLT 後 PC/state 不変は検査しない。
- TB RAM は ceb を無視して毎 clk 読む。実際の read enable 契約を検証する TB ではない。
- boot off-by-one は余分な NOP で吸収している。boot 修正後は length=1/最大長で
  write count、最終 byte、範囲外 read/write を専用 TB で確認する。

V=0/1 と source register 保存、SP 復元、入力 C 両値、absolute compare を
次の CPU99 回帰拡充へ渡す。現 TB pass を命令全形式・実機の証明として扱わない。

## Day05–18: 実DUTと新TBの独立実行

各 completed の working directory で、starter 内の shared TB と**そのcompletedのcpu.sv**を
明示して Verilator を実行した。別 Day の DUT を compile する問題は見つからなかった。
Day06/08/10 の interface define は各 Makefile と同じものを使用した。

```text
verilator --binary --timing --assert -Wno-fatal --top-module tb_cpu
  --Mdir /private/tmp/sol-glm-review/dayXX-cpu [interface define]
  ../dayXX/sim/tb_cpu.sv cpu.sv
/private/tmp/sol-glm-review/dayXX-cpu/Vtb_cpu
```

結果一覧: `/private/tmp/sol-glm-review/results.json`。
各 Day の build/run logs: `dayXX-cpu-build.log` / `dayXX-cpu-run.log`、同 directory 内。

- completed Day05/06/08/09/10/11/12/13/14/15/16/17/18: 13 件 build/run とも exit 0。
- completed Day07: build exit 1、run 未実行。
  `cpu.sv:98 Assigning to input/const variable: debug_pc`。
- starter は TODO を含むため今回 run していない。starter を completed と同じ pass 数に数えない。

shared TB は bounded wait、post-NBA sampling、error_count を fatal へ伝播するよう改善されている。
Day15 compare/INC/DEC、Day18 custom instructions と JSR/RTS も明示的な検査が追加された。
Day06/08/10 の conditional interface は存在しない port を接続する誤りを避けるもので、
今回読んだ差分で starter を無条件 pass にする弱化は見つからなかった。
特に Day10 starter の stack memory 検査は unguarded で未実装なら失敗する。

ただし Day10–18 の TB は依然 `assign data_in=mem[address_bus]` の非同期 memory である。
実 RAM 同期 read、疎な enable での write 回数、Day18 表示中の RAM arbitration を検証しない。
この pass と hardware 受入は分離する。
後続設計は `REVIEW_SOL_CURRICULUM_DESIGN_ja.md` を参照。

## Flash成果物

root build/sim/clean の失敗伝播、LED 時刻計算、LDA 即値表記、Day18 opcode、
Day99 実階層と単体 ALU 未接続の訂正はコードと整合する。
CPU 命令 suite が未統合という文書は現在の root/Day99 Makefile には正しいが、
Sol 統合後は test 説明を更新する。
textlint 実行、Gowin build、LCD/CPU 実機確認は今回行っていない。

## 先行ALU永続TBの状態

`src/tb_alu_regression.sv` は GPT 6.1 Sol により新規追加済み。
整数加減算と signed range から独立期待値を計算し、DUT の overflow bit 式を複製しない。
--assert、fatal、500000ns timeout 付きで 393216 vectors を完走し exit 0。

build log: `/private/tmp/alu-sol-permanent-build.log`。
run log: `/private/tmp/alu-sol-permanent-run.log`。
初回は tmp 親 directory 未作成で build 失敗し、mkdir 後に同 command を再実行して成功。
詳細 command と結果は `REVIEW_SOL_TOOLS_ja.md` に追記済み。
Makefile 統合は親 agent 担当。

判定: Day99 限定修正はレビュー通過。全体の test 入口は上の必須修正と
GLM 再開 session 最終版の再検証が必要。commit/push なし。
