# Day 99 CPUのSol設計修正と検証

作業日: 2026-10-03。対象: R05/R06/R07/R08/R13。
GLM の RTS/BCS/zero-page・indirect 比較修正を土台に、active 経路 `cpu.sv → calc_cpu_next` を修正した。参考 `cpu_memory.sv` のみを直した結果ではない。

## 実装

- Boot 容量 7680 byte、length は byte 数。0/超過を write なしの fault へ。有効 INIT_RAM index だけ配列参照。最後の registered write edge 後に FETCH を許可し、厳密に length 回書き込む。
- 通常 CEA/VCEA は標準 0。STA/STX/STY と RMW の write decode を同じ helper へ集約し、一命令 write を一 edge にする。欠けていた STY absolute ($8C)も追加した。
- Text VRAM は 1024 byte、可視 1020 セル。全 1024 セル clear と shadow の index/data を一致。VRAM read は shadow へ decode し RMW を可能にした。7C00–7FFF/FC00–FFFF の CPU 直接 write は fault。
- PC、branch、absolute/indexed effective address は 16bit wrap。物理 15bit RAM mirror は維持し VRAM decode を優先。JMP indirect は 16bit 次 address を読む仕様で、NMOS page-wrap bug を再現しない。
- A1/B1 の LDA indirect operand を旧 2 byte 分類から正しい 1 byte へ修正。pointer 高位 byte の FF→00 wrap と命令 PC を動的検査。
- CMP absolute/absolute,X/absolute,Y、CPX/CPY absolute (CD/DD/D9/EC/CC)を追加。比較は入力 C を使わず、V/source register を保持。
- PLP は SP increment 後の stack byte から N/V/I/Z/C を復元。PHP は B/bit5 を 1 にする。CLD に対応し、SED および PLP で D=1 を要求した場合は明示 decimal fault。BCD 未実装を黙って二進演算で代用しない。
- Unsupported opcode は operand 長を推測して読み進めず `FAULT_OPCODE` へ。HALT と FAULT を別 state にし、`cur.fault_reason`、opcode、命令 PC から理由を識別する。fault は reset まで保持し write/read enable を抑止する。
- active FSM の古い「未接続・planned」header を訂正。generated/vendor は編集せず、外部 CPU port も変更していない。
- 命令表の 256opcode を静的 audit。141 個の実装/custom decode、SED の明示 fault、114 個の unsupported。全命令互換を示す表現を訂正し、現 map と decimal 方針を明文化した。

## 検証

Verilator 5.052。両 TB は active CPU と独立した一 clock 同期 RAM を接続し CEB を尊重する。assert 有効、bounded timeout、不一致は fatal。完成 CPU 全入力の網羅や実機成功を意味しない。

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

| テスト            | 結果                                  |
| ----------------- | ------------------------------------- |
| tb_cpu_regression | 12 checkpoints PASS、build/run exit 0 |
| tb_cpu_contract   | 全項目PASS、build/run exit 0          |

契約 TB の検査:

- length 0/1/7679/7680/7681、boot address/write 数、範囲外の次 byte 未変更、最後の write 前 FETCH 禁止。
- DFFF/E000/E3FB/E3FC/E3FF/E400、STA/STX/STY/INC/ASL の write 数、VRAM readback、全内部 VRAMwrite の shadow 一致。
- shadow 両端と mirror alias4 ケースの write 拒否、全 1024 セル clear の index 別 write 数=1、停止後 write 抑止。
- 14 比較 forms × 入力 C の両値、V=1 保持、A/X/Y 不変、SP 復元を直接観測。絶対 5forms は別途 unequal/borrow 両結果、A/X/Y を異なる値、V=0 で検査し、source 選択を直接確認。GLM 命令結果の異大小/borrow は既存 12checkpoint も継続検査。
- PLP/PHP の N/V/I/Z/C と B/bit5、CLD、SED/PLP decimal fault、unsupported $00 の opcode/PC 診断。
- LDA/CMP の indirect,X・indirect,Y で pointer low を FF に置き、高位 byte を 00 から読むケース。100 は違う値にして stack 領域へ誤読すれば失敗。
- PC 7FFF→8000/FFFF→0000、正負 branch で 7FFF 境界、absolute indexed FFFF+1→0000。

GLM TB は checkpoint0 の期待値 0 が RAM 初期値 0 と一致していたため、全 checkpoint を CC で poison し、実際の write がなければ失敗するよう修正した。nested/cross-page RTS 後 SP=FF も直接確認する。done sentinel 後に bounded HALT 待ち、FAULT_NONE、停止後 CEA/VCEA=0 を確認し、sentinel だけを完了としない。

## ネガティブ検証

本体を変えず `/private/tmp/sol-neg-*` に CPU/include/TB を複製して故意の誤りを導入。以下の 8 ケースは fresh build、同じ assert/timeout で検出し run exit 1。

| 変異                                      | 検出結果                                  |
| ----------------------------------------- | ----------------------------------------- |
| 次状態CEA/VCEA標準0を削除                 | write count 期待11/8が22/16、fatal        |
| boot終了をbyte数でなく最終index比較へ戻す | 最終boot write retirement前FETCH、fatal   |
| clear shadow indexを旧cur.v_adaへ戻す     | shadow/video mismatch、fatal              |
| checkpoint0 write先だけを050Cへ変える     | checkpoint0=CCのまま、期待00との差でfatal |
| CPX/CPYのsourceを誤ってAへ変更            | unequal/borrow/distinct-source検査でfatal |
| A1/B1を2 byte operand分類へ戻す           | second operand fetch禁止assertでfatal     |
| A1でread全体を省略しAを保持して次命令へ   | initial A=33とRAM=44の差を検出、fatal     |
| B1でread全体を省略しAを保持して次命令へ   | initial A=33とRAM=44の差を検出、fatal     |

変異スクリプト実行: `python3 /private/tmp/sol_cpu_negative.py` (各実行 exit 0)。初回 pulse/boot/clear/checkpoint、追加 source/operand/noread-a1/noread-b1 を別 run で検査。再実行はスクリプト末尾の kind list で選択する。build/run log は各 `/private/tmp/sol-neg-*/{build,run}.log`。一時スクリプト・log は永続成果物ではない。変異内容は上表に保存した。

A1/B1 の初回変異は結果と PC だけでは検出できなかった。誤分類で次 opcode を余分に読んでも、LDA は operand low だけを使い PC+2 へ戻るためである。結果 oracle を緩めず、1 byte 命令の FETCH_OPERAND2 禁止 assert を追加し、同じ変異が失敗することを再確認した。

LCD 担当の C03 クロスレビューで LDA pointer-wrap ケースの initial A と期待 RAM 値が両方 44 と指摘された。n0/n1 の initial A を 33 へ変え、期待 RAM44 との違いを作った。CMP n2/n3 は A44 を維持する。RTL を変えず fresh final5 で PASS し、A1/B1 それぞれ read を丸ごと省略して A を保持する copy が fatal/exit1 になることを独立に確認した。

## 限界・残課題

256 表は RTL 上の実装有無と operand 分類の静的照合。全 256opcode を全入力・全 flags・全 page 境界で動的網羅した結果ではない。割込み、decimal 演算、NMOS 違法命令、cycle accuracy、NMOS JMP 間接 page-wrap bug は非互換。未実装例は LDY abs,X ($BC)と ROR abs,X ($7E)。

旧 INIT_VRAM 診断 state は boot から到達しないため、誤って入れば fault にする。CPU reset は RAM/VRAM 内容の clear ではない。IFO の frame atomicity/debugger ownership、long-running stability、実 RAM の collision/CDC、9K/20K 合成・配置配線・実機受入はこの CPU 単体検証の証明範囲外。
