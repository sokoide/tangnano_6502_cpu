# Day 99 命令とメモリ契約

6502 の二進演算を実装するサブセット。割込み、decimal、cycle accuracy、NMOS JMP ($xxFF)の page-wrap bug は互換対象外。JMP indirect は 16bit の次 address を読む。未対応 opcode は operand を推測して読み進めず、opcode/PC を保持して `FAULT_OPCODE` で停止する。`HLT` は `HALT`、fault は `FAULT` として区別する。

CLD は対応。SED と PLP で D=1 を復元する要求は `FAULT_DECIMAL`。PLP は SP を 1 増やして N/V/I/Z/C を復元し、B/bit5 は保存 flag として扱わない。PHP の stack byte は B=1/bit5=1。BCD 結果を二進結果で代用しない。

`+` は RTL decode が存在すること、`!` は custom 命令、`D` は明示 decimal fault、`—` は unsupported fault。下表は 256 opcode の静的 audit であり、全命令の全入力の検証済み表ではない。未対応の例は BRK/RTI/CLI/SEI、LDY abs,X ($BC)、ROR abs,X ($7E)、ORA (zp),Y ($11)、BIT zp ($24)。

| high \ low | 0          | 1         | 2         | 3   | 4         | 5         | 6         | 7   | 8           | 9         | A          | B   | C         | D         | E         | F          |
| ---------- | ---------- | --------- | --------- | --- | --------- | --------- | --------- | --- | ----------- | --------- | ---------- | --- | --------- | --------- | --------- | ---------- |
| 0          | —          | + ORA idx | —         | —   | —         | + ORA zp  | + ASL zp  | —   | + PHP impl  | + ORA imm | + ASL acc  | —   | —         | + ORA abs | + ASL abs | —          |
| 1          | + BPL rel  | —         | —         | —   | —         | + ORA zpx | + ASL zpx | —   | + CLC impl  | + ORA aby | —          | —   | —         | + ORA abx | + ASL abx | —          |
| 2          | + JSR abs  | + AND idx | —         | —   | —         | + AND zp  | + ROL zp  | —   | + PLP impl  | + AND imm | + ROL acc  | —   | —         | —         | + ROL abs | —          |
| 3          | + BMI rel  | + AND idy | —         | —   | —         | + AND zpx | + ROL zpx | —   | + SEC impl  | —         | —          | —   | —         | —         | + ROL abx | —          |
| 4          | —          | + EOR idx | —         | —   | —         | + EOR zp  | + LSR zp  | —   | + PHA impl  | + EOR imm | + LSR acc  | —   | + JMP abs | —         | + LSR abs | —          |
| 5          | + BVC rel  | + EOR idy | —         | —   | —         | + EOR zpx | + LSR zpx | —   | —           | —         | —          | —   | —         | —         | + LSR abx | —          |
| 6          | + RTS impl | + ADC idx | —         | —   | —         | + ADC zp  | + ROR zp  | —   | + PLA impl  | + ADC imm | + ROR acc  | —   | + JMP ind | + ADC abs | + ROR abs | —          |
| 7          | + BVS rel  | + ADC idy | —         | —   | —         | + ADC zpx | + ROR zpx | —   | —           | + ADC aby | —          | —   | —         | + ADC abx | —         | —          |
| 8          | —          | + STA idx | —         | —   | + STY zp  | + STA zp  | + STX zp  | —   | + DEY impl  | —         | + TXA impl | —   | + STY abs | + STA abs | + STX abs | —          |
| 9          | + BCC rel  | + STA idy | —         | —   | + STY zpx | + STA zpx | + STX zpy | —   | + TYA impl  | + STA aby | + TXS impl | —   | —         | + STA abx | —         | —          |
| A          | + LDY imm  | + LDA idx | + LDX imm | —   | + LDY zp  | + LDA zp  | + LDX zp  | —   | + TAY impl  | + LDA imm | + TAX impl | —   | + LDY abs | + LDA abs | + LDX abs | —          |
| B          | + BCS rel  | + LDA idy | —         | —   | + LDY zpx | + LDA zpx | + LDX zpy | —   | + CLV impl  | + LDA aby | + TSX impl | —   | —         | + LDA abx | + LDX aby | —          |
| C          | + CPY imm  | + CMP idx | —         | —   | + CPY zp  | + CMP zp  | + DEC zp  | —   | + INY impl  | + CMP imm | + DEX impl | —   | + CPY abs | + CMP abs | + DEC abs | ! CVR impl |
| D          | + BNE rel  | + CMP idy | —         | —   | —         | + CMP zpx | + DEC zpx | —   | + CLD impl  | + CMP aby | —          | —   | —         | + CMP abx | + DEC abx | ! IFO abs  |
| E          | + CPX imm  | + SBC idx | —         | —   | + CPX zp  | + SBC zp  | + INC zp  | —   | + INX impl  | + SBC imm | + NOP impl | —   | + CPX abs | + SBC abs | + INC abs | ! HLT impl |
| F          | + BEQ rel  | + SBC idy | —         | —   | —         | + SBC zpx | + INC zpx | —   | D SED fault | + SBC aby | —          | —   | —         | + SBC abx | + INC abx | ! WVS imm  |

A1/B1 (LDA indirect,X / indirect,Y) は opcode 後に 1 byte operand を fetch する。表の idx/idy は全て 1 byte operand、abs/abx/aby/ind は 2 byte operand。クロスレビューで見つかった旧 A1/B1 分類誤りも修正した。

## Custom命令

- CF CVR: operand なし。1024 セルを space ($20)で埋め、shadow も同じ index/data で更新。最終 write edge 後に次命令へ進む。
- DF IFO: 16bit operand。既存 register/memory 表示。FFFF は表示せず次命令へ。debug snapshot/外部 debugger の所有権は別課題。
- EF HLT: operand なし。CPU 停止、LCD は継続。
- FF WVS: 8bit operand。0 で vsync1 回、N で N+1 回待つ。

## メモリmapとboot

PC、branch、absolute/indexed 実効 address は 16bit wrap、zero page index は 8bit wrap。physical decode で RAM の 15bit address へ変換する。

| CPU address | 読み出し                        | CPU書き込み        |
| ----------- | ------------------------------- | ------------------ |
| 0000–7BFF   | main RAM                        | main RAM           |
| 7C00–7FFF   | shadow VRAM                     | FAULT_SHADOW_WRITE |
| 8000–DFFF   | address bit15を除いたRAM mirror | RAM mirror         |
| E000–E3FF   | shadow 7C00–7FFF                | VRAMとshadow両方   |
| E400–FBFF   | address bit15を除いたRAM mirror | RAM mirror         |
| FC00–FFFF   | shadow 7C00–7FFF mirror         | FAULT_SHADOW_WRITE |

VRAM decode を mirror より優先する。VRAM read は shadow を読むため RMW も対応。VRAM 容量 1024 byte、可視範囲 60×17=1020 セル。E3FC–E3FF の 4 セルも通常 read/write と CVR 対象。CPU reset は RAM/VRAM 内容を初期化しない。

boot 配列容量は 7680 byte。length は byte 数で 1–7680 のみ合法。0/超過は write なしの FAULT_BOOT_LENGTH。INIT_RAM かつ有効 index だけ配列を読み、length 回の registered write を発行する。最終 write edge が終わってから FETCH へ進む。

CEA/VCEA は標準 0 で、通常 store/RMW ごとに 1edge のみ write する。内部 CVR/IFO は連続 write 可能だが常に `ada=7C00+v_ada`, `din=v_din` を満たす。fault は reset まで保持し write を抑止する。

検証範囲と実行コマンドは[Sol CPU結果](../../docs/REVIEW_SOL_CPU99_RESULT_ja.md)。合成・配置配線・実機互換性は別途確認が必要。
