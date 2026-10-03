# Sol CPU99最終差分の独立レビュー

レビュー日: 2026-10-03
対象: active CPU/FSM/types/constants、`tb_cpu_contract`、`tb_cpu_regression`、命令表、[CPU実装結果](REVIEW_SOL_CPU99_RESULT_ja.md)。
作業: read-only レビューと fresh build/run。本書以外の source は変更していない。LCD/メモリ担当自身の変更はレビュー対象外。

## 指摘

### C01 / P1: LDA間接2命令のoperand長分類が表と一致しない

`day99_completed/src/cpu/cpu_fsm_next_pkg.sv:209,213` の `$A1/$B1` は `FETCH_OPERAND1OF2` 群に入っている。一方、実行 handler は 8bit zero-page operand を使い、次命令へ `pc_plus2` で戻る。命令表の `LDA idx/idy` も 1byte operand である。

現在の 32KiB mirror では余分に次 byte を読み、その後正しい PC へ戻るため通常の LDA 結果は一致する。しかし命令長 audit としては不整合で、余分な RAM read と待ち state を発生させる。将来 read に副作用を持つ MMIO を追加する際にも問題となる。

修正: A1/B1 を 1byte operand 群へ移す。実行 test で値・次 PC を確認し、FETCH_OPERAND2 へ入らないことを観測する。

今回の静的照合は命令表の address mode から期待 operand byte 数を導き、fetch case と比較した。142 分類（実装/custom141 + SED fault1）のうち相違は A1/B1 の 2 件のみ。命令表を読んだだけで RTL の分類が一致したとは判断していない。

### C02 / P1: regressionの終了oracleが最終CPU停止状態を確認しない

`day99_completed/src/tb_cpu_regression.sv:384–420` は done sentinel を見て 4edge 待ち、SP/checkpoint/fail byte を確認して PASS する。最終 CPU state、fault_reason、停止後の CEA/VCEA は確認していない。

したがって全 checkpoint/done 書込み後の HLT が unsupported fault に変わる、または CPU が継続実行する変異をこの TB 単独では検出できない。これは source 上の終了条件からの指摘であり、今回 source 変異を行って再現した結果ではない。`tb_cpu_contract` は別に HALT/FAULT を待つが、この regression program 自体の正常終了確認の代替にはならない。

修正: bounded wait で HALT へ到達し、FAULT_NONE、期待最終 PC、SP、停止後 write enable=0 を検査する。done を書いた後に FAULT へ入る場合は即 fatal とする。

### C03 / P2: 新absolute比較の非等値/source選択とpointer末尾wrapは動的未検証

`tb_cpu_contract:99–115` の 14 比較 forms は、全 form とも source/operand=$40 の等値だけを検査し、A/X/Y も同じ値である。新 CD/DD/D9/EC/CC の borrow/非等値や CPX/CPY の source 選択を誤った場合に強く検出するには、register を異なる値にしたケースが必要。

GLM regression は一部 forms で大小差・borrow を検査しており、比較全体の基本演算が未検証という意味ではない。新 absolute forms の等値・C 入力非依存・V 保持・正しい address 読出しの検査は有効。

pointer の zero-page `$FF→$00` 読出し wrap も今回の TB には明示 case がない。RTL は 8bit `zp_addr` を使っており静的には正しいが、index 加算 wrap の case を pointer 高 byte 読出し wrap の実行証拠とは扱わない。

追加案: A/X/Y に別値、operand より小/等/大、C 入力両値の absolute 比較、各 indirect 形式で pointer 低 byte を$FF に置いた case、JMP indirect `$FFFF→$0000` の platform 仕様 case。

## 確認した正しい経路

- Boot: INIT で 0/超過を fault。配列 guard は INIT_RAM/boot_write/idx<length/idx<7680。最終 idx は length−1 で、write 準備から次 edge の write retirement を経て FETCH へ進む。length 回を検査する TB の retirement 条件は実際の CPU output edge を数えている。
- Write: next CEA/VCEA 標準 0。STA/STX/STY/RMW が共通 decode へ進み、通常 store が FETCH_REQ へ持続しない。JSR の 2 回 write、PHA/PHP の stack write も独立 edge で発行する。
- VRAM/shadow: E000–E3FF read は shadow、write は VRAM+shadow。同じ index/data で更新。7C00–7FFF/FC00–FFFF の直接 CPU write を fault 化し、mirror で read-only を迂回できない。E3FC–E3FF も物理容量に含む。
- Clear: address0 を準備し、次 index を VRAM/shadow 両方へ使い、1023 の write retirement 後に次命令へ移る。全 1024index の write 数=1 と内容一致を TB が検査する。
- PC/effective address: CPU 加算は 16bit、RAM15bit 変換は decode へ分離。zero-page index/pointer は 8bit temporary で truncate。RTS は読出し直後の上位 byte と保持済み下位 byte を組み立てて+1。
- PLP/PHP: SP を 8bit 加算して stack 読出し、N/V/I/Z/C 復元、B/bit5 は状態 flag へ復元しない。PHP の出力 B/bit5=1。D=1 の PLP と SED は decimal fault、CLD は明示対応という binary-only 方針と一致。
- Fault: 未分類 opcode を operand 推測なしで停止し opcode/PC を保持。fault_reason 非 zero は FAULT へ集約し CEA/VCEA/CEB を 0、reset まで reason を保持する。HALT とは区別する。
- Oracle: checkpoint0 を含む全 checkpoint の CC poison、fail byte、bounded timeout、fatal が有効。RAM model は独立同期 read で CEB を尊重する。CPU 内部 handler を直接呼ぶだけの検証ではなく、boot→fetch→execute を通る。

## 今回の独立実行

repo root から Verilator 5.052 で fresh build。両 build/run とも exit 0。

```sh
verilator --binary --timing --assert -Wno-fatal \
  -Iday99_completed/include -Iday99_completed/src \
  --Mdir /private/tmp/sol-cpu-contract-review --top-module tb_cpu_contract \
  day99_completed/src/cpu.sv day99_completed/src/tb_cpu_contract.sv
/private/tmp/sol-cpu-contract-review/Vtb_cpu_contract

verilator --binary --timing --assert -Wno-fatal \
  -Iday99_completed/include -Iday99_completed/src \
  --Mdir /private/tmp/sol-cpu-regression-review --top-module tb_cpu_regression \
  day99_completed/src/cpu.sv day99_completed/src/tb_cpu_regression.sv
/private/tmp/sol-cpu-regression-review/Vtb_cpu_regression
```

契約 TB の全項目 PASS、regression の 12checkpoint PASS を確認した。上記 P1 指摘は、この PASS だけでは保証しない経路として残る。作者の negative test 結果は実装結果文書で確認したが、今回は変異を再実行していない。

レビューsnapshot SHA256:

```text
cpu_fsm_next_pkg.sv 37d313600821844b1b57d444200d04af3f8acc5b9592d53c9ef2903eaf0cb59c
tb_cpu_contract.sv  9ce94a6e7398e10589cde522b99842cf250a5d92dd197c59aa03e482bf319ddc
tb_cpu_regression.sv 73b41766a3ac1fb6204064872add10b906ab31368baef708ae5fbfad5f35f816
```

FPGA 合成・配置配線・実機受入は本レビューの範囲外。sandbox 内 Gowin 初期化失敗と、root が後続実行している sandbox 外合成は別結果として扱う。
