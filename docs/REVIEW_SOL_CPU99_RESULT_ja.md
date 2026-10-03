# Day 99 CPUのSol設計修正と検証

作業日: 2026-10-03。対象: R05/R06/R07/R08/R13。
GLMのRTS/BCS/zero-page・indirect比較修正を土台に、active経路 `cpu.sv → calc_cpu_next` を修正した。参考 `cpu_memory.sv` のみを直した結果ではない。

## 実装

- Boot容量7680 byte、lengthはbyte数。0/超過をwriteなしのfaultへ。有効INIT_RAM indexだけ配列参照。最後のregistered write edge後にFETCHを許可し、厳密にlength回書込む。
- 通常CEA/VCEAは標準0。STA/STX/STYとRMWのwrite decodeを同じhelperへ集約し、一命令writeを一edgeにする。欠けていたSTY absolute ($8C)も追加した。
- Text VRAMは1024 byte、可視1020セル。全1024セルclearとshadowのindex/dataを一致。VRAM readはshadowへdecodeしRMWを可能にした。7C00–7FFF/FC00–FFFFのCPU直接writeはfault。
- PC、branch、absolute/indexed effective addressは16bit wrap。物理15bit RAM mirrorは維持しVRAM decodeを優先。JMP indirectは16bit次addressを読む仕様で、NMOS page-wrap bugを再現しない。
- A1/B1のLDA indirect operandを旧2 byte分類から正しい1 byteへ修正。pointer高位byteのFF→00 wrapと命令PCを動的検査。
- CMP absolute/absolute,X/absolute,Y、CPX/CPY absolute (CD/DD/D9/EC/CC)を追加。比較は入力Cを使わず、V/source registerを保持。
- PLPはSP increment後のstack byteからN/V/I/Z/Cを復元。PHPはB/bit5を1にする。CLDに対応し、SEDおよびPLPでD=1を要求した場合は明示decimal fault。BCD未実装を黙って二進演算で代用しない。
- Unsupported opcodeはoperand長を推測して読み進めず `FAULT_OPCODE` へ。HALTとFAULTを別stateにし、`cur.fault_reason`、opcode、命令PCから理由を識別する。faultはresetまで保持しwrite/read enableを抑止する。
- active FSMの古い「未接続・planned」headerを訂正。generated/vendorは編集せず、外部CPU portも変更していない。
- 命令表の256opcodeを静的audit。141個の実装/custom decode、SEDの明示fault、114個のunsupported。全命令互換を示す表現を訂正し、現mapとdecimal方針を明文化した。

## 検証

Verilator 5.052。両TBはactive CPUと独立した一clock同期RAMを接続しCEBを尊重する。assert有効、bounded timeout、不一致はfatal。完成CPU全入力の網羅や実機成功を意味しない。

リポジトリルートから:

```sh
verilator --binary --timing --assert -Wno-fatal \
  -Iday99_completed/include -Iday99_completed/src \
  --Mdir /private/tmp/sol-cpu-contract-final5 --top-module tb_cpu_contract \
  day99_completed/src/cpu.sv day99_completed/src/tb_cpu_contract.sv
/private/tmp/sol-cpu-contract-final5/Vtb_cpu_contract
verilator --binary --timing --assert -Wno-fatal \
  -Iday99_completed/include -Iday99_completed/src \
  --Mdir /private/tmp/sol-cpu-regression-final3 --top-module tb_cpu_regression \
  day99_completed/src/cpu.sv day99_completed/src/tb_cpu_regression.sv
/private/tmp/sol-cpu-regression-final3/Vtb_cpu_regression
```

| テスト | 結果 |
|---|---|
| tb_cpu_regression | 12 checkpoints PASS、build/run exit 0 |
| tb_cpu_contract | 全項目PASS、build/run exit 0 |

契約TBの検査:

- length 0/1/7679/7680/7681、boot address/write数、範囲外の次byte未変更、最後のwrite前FETCH禁止。
- DFFF/E000/E3FB/E3FC/E3FF/E400、STA/STX/STY/INC/ASLのwrite数、VRAM readback、全内部VRAMwriteのshadow一致。
- shadow両端とmirror alias4ケースのwrite拒否、全1024セルclearのindex別write数=1、停止後write抑止。
- 14比較forms × 入力Cの両値、V=1保持、A/X/Y不変、SP復元を直接観測。絶対5formsは別途 unequal/borrow両結果、A/X/Yを異なる値、V=0で検査し、source選択を直接確認。GLM命令結果の異大小/borrowは既存12checkpointも継続検査。
- PLP/PHPのN/V/I/Z/CとB/bit5、CLD、SED/PLP decimal fault、unsupported $00のopcode/PC診断。
- LDA/CMPのindirect,X・indirect,Yでpointer lowをFFに置き、高位byteを00から読むケース。100は違う値にしてstack領域へ誤読すれば失敗。
- PC 7FFF→8000/FFFF→0000、正負branchで7FFF境界、absolute indexed FFFF+1→0000。

GLM TBはcheckpoint0の期待値0がRAM初期値0と一致していたため、全checkpointをCCでpoisonし、実際のwriteがなければ失敗するよう修正した。nested/cross-page RTS後SP=FFも直接確認する。done sentinel後にbounded HALT待ち、FAULT_NONE、停止後CEA/VCEA=0を確認し、sentinelだけを完了としない。

## ネガティブ検証

本体を変えず `/private/tmp/sol-neg-*` にCPU/include/TBを複製して故意の誤りを導入。以下の8ケースはfresh build、同じassert/timeoutで検出しrun exit 1。

| 変異 | 検出結果 |
|---|---|
| 次状態CEA/VCEA標準0を削除 | write count 期待11/8が22/16、fatal |
| boot終了をbyte数でなく最終index比較へ戻す | 最終boot write retirement前FETCH、fatal |
| clear shadow indexを旧cur.v_adaへ戻す | shadow/video mismatch、fatal |
| checkpoint0 write先だけを050Cへ変える | checkpoint0=CCのまま、期待00との差でfatal |
| CPX/CPYのsourceを誤ってAへ変更 | unequal/borrow/distinct-source検査でfatal |
| A1/B1を2 byte operand分類へ戻す | second operand fetch禁止assertでfatal |
| A1でread全体を省略しAを保持して次命令へ | initial A=33とRAM=44の差を検出、fatal |
| B1でread全体を省略しAを保持して次命令へ | initial A=33とRAM=44の差を検出、fatal |

変異スクリプト実行: `python3 /private/tmp/sol_cpu_negative.py` (各実行exit 0)。初回pulse/boot/clear/checkpoint、追加source/operand/noread-a1/noread-b1を別runで検査。再実行はスクリプト末尾のkind listで選択する。build/run logは各 `/private/tmp/sol-neg-*/{build,run}.log`。一時スクリプト・logは永続成果物ではない。変異内容は上表に保存した。

A1/B1の初回変異は結果とPCだけでは検出できなかった。誤分類で次opcodeを余分に読んでも、LDAはoperand lowだけを使いPC+2へ戻るためである。結果oracleを緩めず、1 byte命令のFETCH_OPERAND2禁止assertを追加し、同じ変異が失敗することを再確認した。

LCD担当のC03クロスレビューでLDA pointer-wrapケースのinitial Aと期待RAM値が両方44と指摘された。n0/n1のinitial Aを33へ変え、期待RAM44との違いを作った。CMP n2/n3はA44を維持する。RTLを変えずfresh final5でPASSし、A1/B1それぞれreadを丸ごと省略してAを保持するcopyがfatal/exit1になることを独立に確認した。

## 限界・残課題

256表はRTL上の実装有無とoperand分類の静的照合。全256opcodeを全入力・全flags・全page境界で動的網羅した結果ではない。割込み、decimal演算、NMOS違法命令、cycle accuracy、NMOS JMP間接page-wrap bugは非互換。未実装例はLDY abs,X ($BC)とROR abs,X ($7E)。

旧INIT_VRAM診断stateはbootから到達しないため、誤って入ればfaultにする。CPU resetはRAM/VRAM内容のclearではない。IFOのframe atomicity/debugger ownership、long-running stability、実RAMのcollision/CDC、9K/20K合成・配置配線・実機受入はこのCPU単体検証の証明範囲外。
