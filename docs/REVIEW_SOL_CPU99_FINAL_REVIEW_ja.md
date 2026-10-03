# Sol CPU99最終差分の独立レビュー

レビュー日: 2026-10-03
対象: active CPU/FSM/types/constants、`tb_cpu_contract`、`tb_cpu_regression`、命令表、[CPU実装結果](REVIEW_SOL_CPU99_RESULT_ja.md)。
作業: read-onlyレビューとfresh build/run。本書以外のsourceは変更していない。LCD/メモリ担当自身の変更はレビュー対象外。

## 指摘

### C01 / P1: LDA間接2命令のoperand長分類が表と一致しない

`day99_completed/src/cpu/cpu_fsm_next_pkg.sv:209,213` の `$A1/$B1` は `FETCH_OPERAND1OF2` 群に入っている。一方、実行handlerは8bit zero-page operandを使い、次命令へ `pc_plus2` で戻る。命令表の `LDA idx/idy` も1byte operandである。

現在の32KiB mirrorでは余分に次byteを読み、その後正しいPCへ戻るため通常のLDA結果は一致する。しかし命令長auditとしては不整合で、余分なRAM readと待ちstateを発生させる。将来readに副作用を持つMMIOを追加する際にも問題となる。

修正: A1/B1を1byte operand群へ移す。実行testで値・次PCを確認し、FETCH_OPERAND2へ入らないことを観測する。

今回の静的照合は命令表のaddress modeから期待operand byte数を導き、fetch caseと比較した。142分類（実装/custom141 + SED fault1）のうち相違はA1/B1の2件のみ。命令表を読んだだけでRTLの分類が一致したとは判断していない。

### C02 / P1: regressionの終了oracleが最終CPU停止状態を確認しない

`day99_completed/src/tb_cpu_regression.sv:384–420` はdone sentinelを見て4edge待ち、SP/checkpoint/fail byteを確認してPASSする。最終CPU state、fault_reason、停止後のCEA/VCEAは確認していない。

したがって全checkpoint/done書込み後のHLTがunsupported faultに変わる、またはCPUが継続実行する変異をこのTB単独では検出できない。これはsource上の終了条件からの指摘であり、今回source変異を行って再現した結果ではない。`tb_cpu_contract` は別にHALT/FAULTを待つが、このregression program自体の正常終了確認の代替にはならない。

修正: bounded waitでHALTへ到達し、FAULT_NONE、期待最終PC、SP、停止後write enable=0を検査する。doneを書いた後にFAULTへ入る場合は即fatalとする。

### C03 / P2: 新absolute比較の非等値/source選択とpointer末尾wrapは動的未検証

`tb_cpu_contract:99–115` の14比較formsは、全formともsource/operand=$40の等値だけを検査し、A/X/Yも同じ値である。新CD/DD/D9/EC/CCのborrow/非等値やCPX/CPYのsource選択を誤った場合に強く検出するには、registerを異なる値にしたケースが必要。

GLM regressionは一部formsで大小差・borrowを検査しており、比較全体の基本演算が未検証という意味ではない。新absolute formsの等値・C入力非依存・V保持・正しいaddress読出しの検査は有効。

pointerのzero-page `$FF→$00` 読出しwrapも今回のTBには明示caseがない。RTLは8bit `zp_addr` を使っており静的には正しいが、index加算wrapのcaseをpointer高byte読出しwrapの実行証拠とは扱わない。

追加案: A/X/Yに別値、operandより小/等/大、C入力両値のabsolute比較、各indirect形式でpointer低byteを$FFに置いたcase、JMP indirect `$FFFF→$0000` のplatform仕様case。

## 確認した正しい経路

- Boot: INITで0/超過をfault。配列guardはINIT_RAM/boot_write/idx<length/idx<7680。最終idxはlength−1で、write準備から次edgeのwrite retirementを経てFETCHへ進む。length回を検査するTBのretirement条件は実際のCPU output edgeを数えている。
- Write: next CEA/VCEA標準0。STA/STX/STY/RMWが共通decodeへ進み、通常storeがFETCH_REQへ持続しない。JSRの2回write、PHA/PHPのstack writeも独立edgeで発行する。
- VRAM/shadow: E000–E3FF readはshadow、writeはVRAM+shadow。同じindex/dataで更新。7C00–7FFF/FC00–FFFFの直接CPU writeをfault化し、mirrorでread-onlyを迂回できない。E3FC–E3FFも物理容量に含む。
- Clear: address0を準備し、次indexをVRAM/shadow両方へ使い、1023のwrite retirement後に次命令へ移る。全1024indexのwrite数=1と内容一致をTBが検査する。
- PC/effective address: CPU加算は16bit、RAM15bit変換はdecodeへ分離。zero-page index/pointerは8bit temporaryでtruncate。RTSは読出し直後の上位byteと保持済み下位byteを組み立てて+1。
- PLP/PHP: SPを8bit加算してstack読出し、N/V/I/Z/C復元、B/bit5は状態flagへ復元しない。PHPの出力B/bit5=1。D=1のPLPとSEDはdecimal fault、CLDは明示対応というbinary-only方針と一致。
- Fault: 未分類opcodeをoperand推測なしで停止しopcode/PCを保持。fault_reason非zeroはFAULTへ集約しCEA/VCEA/CEBを0、resetまでreasonを保持する。HALTとは区別する。
- Oracle: checkpoint0を含む全checkpointのCC poison、fail byte、bounded timeout、fatalが有効。RAM modelは独立同期readでCEBを尊重する。CPU内部handlerを直接呼ぶだけの検証ではなく、boot→fetch→executeを通る。

## 今回の独立実行

repo rootからVerilator 5.052でfresh build。両build/runともexit 0。

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

契約TBの全項目PASS、regressionの12checkpoint PASSを確認した。上記P1指摘は、このPASSだけでは保証しない経路として残る。作者のnegative test結果は実装結果文書で確認したが、今回は変異を再実行していない。

レビューsnapshot SHA256:

```text
cpu_fsm_next_pkg.sv 37d313600821844b1b57d444200d04af3f8acc5b9592d53c9ef2903eaf0cb59c
tb_cpu_contract.sv  9ce94a6e7398e10589cde522b99842cf250a5d92dd197c59aa03e482bf319ddc
tb_cpu_regression.sv 73b41766a3ac1fb6204064872add10b906ab31368baef708ae5fbfad5f35f816
```

FPGA合成・配置配線・実機受入は本レビューの範囲外。sandbox内Gowin初期化失敗と、rootが後続実行しているsandbox外合成は別結果として扱う。
