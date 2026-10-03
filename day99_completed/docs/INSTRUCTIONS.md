# Day 99 命令とメモリ契約

6502の二進演算を実装するサブセット。割込み、decimal、cycle accuracy、NMOS JMP ($xxFF)のpage-wrap bugは互換対象外。JMP indirectは16bitの次addressを読む。未対応opcodeはoperandを推測して読み進めず、opcode/PCを保持して `FAULT_OPCODE` で停止する。`HLT` は `HALT`、faultは `FAULT` として区別する。

CLDは対応。SEDとPLPでD=1を復元する要求は `FAULT_DECIMAL`。PLPはSPを1増やしてN/V/I/Z/Cを復元し、B/bit5は保存flagとして扱わない。PHPのstack byteはB=1/bit5=1。BCD結果を二進結果で代用しない。

`+` はRTL decodeが存在すること、`!` はcustom命令、`D` は明示decimal fault、`—` はunsupported fault。下表は256 opcodeの静的auditであり、全命令の全入力の検証済み表ではない。未対応の例はBRK/RTI/CLI/SEI、LDY abs,X ($BC)、ROR abs,X ($7E)。

| high \ low | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | A | B | C | D | E | F |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 0 | — | + ORA idx | — | — | — | + ORA zp | + ASL zp | — | + PHP impl | + ORA imm | + ASL acc | — | — | + ORA abs | + ASL abs | — |
| 1 | + BPL rel | + ORA idy | — | — | — | + ORA zpx | + ASL zpx | — | + CLC impl | + ORA aby | — | — | — | + ORA abx | + ASL abx | — |
| 2 | + JSR abs | + AND idx | — | — | + BIT zp | + AND zp | + ROL zp | — | + PLP impl | + AND imm | + ROL acc | — | — | — | + ROL abs | — |
| 3 | + BMI rel | + AND idy | — | — | — | + AND zpx | + ROL zpx | — | + SEC impl | — | — | — | — | — | + ROL abx | — |
| 4 | — | + EOR idx | — | — | — | + EOR zp | + LSR zp | — | + PHA impl | + EOR imm | + LSR acc | — | + JMP abs | — | + LSR abs | — |
| 5 | + BVC rel | + EOR idy | — | — | — | + EOR zpx | + LSR zpx | — | — | — | — | — | — | — | + LSR abx | — |
| 6 | + RTS impl | + ADC idx | — | — | — | + ADC zp | + ROR zp | — | + PLA impl | + ADC imm | + ROR acc | — | + JMP ind | + ADC abs | + ROR abs | — |
| 7 | + BVS rel | + ADC idy | — | — | — | + ADC zpx | + ROR zpx | — | — | + ADC aby | — | — | — | + ADC abx | — | — |
| 8 | — | + STA idx | — | — | + STY zp | + STA zp | + STX zp | — | + DEY impl | — | + TXA impl | — | + STY abs | + STA abs | + STX abs | — |
| 9 | + BCC rel | + STA idy | — | — | + STY zpx | + STA zpx | + STX zpy | — | + TYA impl | + STA aby | + TXS impl | — | — | + STA abx | — | — |
| A | + LDY imm | + LDA idx | + LDX imm | — | + LDY zp | + LDA zp | + LDX zp | — | + TAY impl | + LDA imm | + TAX impl | — | + LDY abs | + LDA abs | + LDX abs | — |
| B | + BCS rel | + LDA idy | — | — | + LDY zpx | + LDA zpx | + LDX zpy | — | + CLV impl | + LDA aby | + TSX impl | — | — | + LDA abx | + LDX aby | — |
| C | + CPY imm | + CMP idx | — | — | + CPY zp | + CMP zp | + DEC zp | — | + INY impl | + CMP imm | + DEX impl | — | + CPY abs | + CMP abs | + DEC abs | ! CVR impl |
| D | + BNE rel | + CMP idy | — | — | — | + CMP zpx | + DEC zpx | — | + CLD impl | + CMP aby | — | — | — | + CMP abx | + DEC abx | ! IFO abs |
| E | + CPX imm | + SBC idx | — | — | + CPX zp | + SBC zp | + INC zp | — | + INX impl | + SBC imm | + NOP impl | — | + CPX abs | + SBC abs | + INC abs | ! HLT impl |
| F | + BEQ rel | + SBC idy | — | — | — | + SBC zpx | + INC zpx | — | D SED fault | + SBC aby | — | — | — | + SBC abx | + INC abx | ! WVS imm |

A1/B1 (LDA indirect,X / indirect,Y) はopcode後に1 byte operandをfetchする。表のidx/idyは全て1 byte operand、abs/abx/aby/indは2 byte operand。クロスレビューで見つかった旧A1/B1分類誤りも修正した。

## Custom命令

- CF CVR: operandなし。1024セルをspace ($20)で埋め、shadowも同じindex/dataで更新。最終write edge後に次命令へ進む。
- DF IFO: 16bit operand。既存register/memory表示。FFFFは表示せず次命令へ。debug snapshot/外部debuggerの所有権は別課題。
- EF HLT: operandなし。CPU停止、LCDは継続。
- FF WVS: 8bit operand。0でvsync1回、NでN+1回待つ。

## メモリmapとboot

PC、branch、absolute/indexed実効addressは16bit wrap、zero page indexは8bit wrap。physical decodeでRAMの15bit addressへ変換する。

| CPU address | 読み出し | CPU書込み |
|---|---|---|
| 0000–7BFF | main RAM | main RAM |
| 7C00–7FFF | shadow VRAM | FAULT_SHADOW_WRITE |
| 8000–DFFF | address bit15を除いたRAM mirror | RAM mirror |
| E000–E3FF | shadow 7C00–7FFF | VRAMとshadow両方 |
| E400–FBFF | address bit15を除いたRAM mirror | RAM mirror |
| FC00–FFFF | shadow 7C00–7FFF mirror | FAULT_SHADOW_WRITE |

VRAM decodeをmirrorより優先する。VRAM readはshadowを読むためRMWも対応。VRAM容量1024 byte、可視範囲60×17=1020セル。E3FC–E3FFの4セルも通常read/writeとCVR対象。CPU resetはRAM/VRAM内容を初期化しない。

boot配列容量は7680 byte。lengthはbyte数で1–7680のみ合法。0/超過はwriteなしのFAULT_BOOT_LENGTH。INIT_RAMかつ有効indexだけ配列を読み、length回のregistered writeを発行する。最終write edgeが終わってからFETCHへ進む。

CEA/VCEAは標準0で、通常store/RMWごとに1edgeのみwriteする。内部CVR/IFOは連続write可能だが常に `ada=7C00+v_ada`, `din=v_din` を満たす。faultはresetまで保持しwriteを抑止する。

検証範囲と実行コマンドは [Sol CPU結果](../../docs/REVIEW_SOL_CPU99_RESULT_ja.md)。合成・配置配線・実機互換性は別途確認が必要。
