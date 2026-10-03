# Day 10–18 同期RAM / Day 18表示要求の最小設計

2026-10-02、GPT 6.1 Sol による read-only 調査。CPU/RAM/lcd_demo、vendor、generated は変更していない。
GLM-5.3 の Makefile/TB 変更とは独立した、後続 Sol 実装の設計資料。

## 現状と失敗条件

- Day 10–18 の starter/completed の `ram.sv` は各 Day で同一。
  Verilator は `assign dout = mem[addr]` による非同期 read。
  hardware は CLKB/CEB を持つ Gowin_SDPB、`READ_MODE=0`、bank 選択も DFFE。
  simulation の即時応答が CPU の待ち不足を隠す。
- completed CPU は `address_bus <= ...` と次 state を同じ edge で更新し、次 edge で
  `data_in` を consume する。同期 read ではその次 edge の RAM 出力更新は NBA 後なので、
  CPU は新 address の応答より前の値を consume する。
- Day 10–17 の hardware は 24bit counter による疎な `pc_enable`。
  address が十分長く保持され、待ち不足が偶然見えない。
  Day 11–17 の Verilator は full speed、Day 18 は両経路 full speed。
- `write_en <= 0` が `else if (pc_enable)` の中にある。
  push/store 後に enable が止まると RAM は同一 write を次 enable まで繰り返す。
  RAM の同じ byte への繰返しは値だけでは検出できず、将来の MMIO では副作用になる。
- Day 18 completed `lcd_demo.sv:607` は IFO 表示中に RAM の address だけを debug へ切替え、
  write_en/din は CPU のまま。CPU は止まらないので debug 領域への誤書込と誤 read が起こる。
  `ram_data_out` を別 edge で上位/下位 nibble として使い、byte の一致も保証しない。
  debug_addr 更新直後の次 edge で上位 nibble を consume する経路も同期 read に待ち不足。
- レジスタ文字列は live CPU 値から複数 edge に渡って作るので、同一時点の snapshot でない。
  `cpu_vram_clear` は top で使用されず、CVR 単独では clear を実行しない。
- Verilator の `lcd/vram.sv` は表示 read 専用の初期文字列であり、top の
  vram_cea/ada/din を接続していない。CPU 要求を検査しても実際の VRAM 更新は検証できない。
- starter CPU は TODO skeleton で completed とは異なる。
  課題の解答をコピーせず、interface と同期 memory の教材契約を揃える。

## 推奨するCPU / RAM変更

RAM の Verilator 分岐を同期 read へ変更する。

```systemverilog
always_ff @(posedge clk) begin
    if (write_en) mem[addr] <= din;
    dout <= mem[addr];
end
```

同 edge read/write の値には依存しない。上記モデルは old data を返すが、
実 primitive の collision semantics と完全一致するとはこの調査だけでは断定しない。
vendor/generated を変更せず、必要なら同梱 primitive model による別検証を行う。

CPU 全 microstate 間に 1clock の settle を挟む `memory_ready` を最小案とする。
opcode ごとの WAIT state を大量追加するより全 bus 更新経路の漏れが少ない。
execute 時に ready=0、次 clk で ready=1、次の enable 時に consume する。
wait は pc_enable に関係なく進め、reset 直後も ready=0 とする。

| edge | CPU | 同期RAM |
| --- | --- | --- |
| t0 | state実行、新addressをNBAでdrive、ready=0 | 旧addressをread |
| t1 | settleのみ、ready=1 | 新addressをreadしてdoutをNBA更新 |
| t2 | enable時に新doutをconsume | 保持addressをread |

全 state に bubble を挟むので fullspeed の microstate throughput は最大 1/2 になる。
6502 の cycle 精密化は今回の教材修正範囲に含めず、この変更を文書化する。
疎な enable の次パルスは settle 完了後なので従来の 1 パルス 1microstate を維持できる。
settle 中に到着する単発 enable は実行できないため、manual step を全受付する必要があるなら
1bit pending を追加し、ready 後に一度だけ消費する。これを黙って無視する仕様にはしない。

`write_en` は reset 以外の毎 clk で default0 とし、state 実行時の write だけ 1 にする。
address/data はその write が RAM で受理される次 edge まで保持する。
`write_en && pc_enable` の組合せ gate だけで修正しない。
CPU が registered write を発行した次 edge に enable が 0 なら write 自体が消えるためである。

Day 18 の `vram_clear/show_info` も毎 clk の単発 pulse にする。
CPU hold 中も write/request の default clear は動作し、architectural state だけ停止する。
starter には同期 RAM 契約と pulse scaffold を用意し、命令 TODO を残す。
全 CPU instance と TB を interface 変更に追従させる。

## Day 18: IFO / CVR とmemory所有権

最小実装は「要求を受けたら CPU を停止し、描画完了後に再開」。
CPU から 1clock request、top から hold を返す。要求と busy を組み合わせた hold により、
要求が high の次 edge に CPU が次命令へ進む race を防ぐ。
IFO/CVR は命令境界で発行され、未完了 write がないことを assert する。
write のある任意 state で外部停止するなら、停止受理前に write を 1 回 retire させる DRAIN が必要。

Day 18 CPU に明示的 `memory_hold` 入力を追加する案を推奨する。
hold 中は memory_ready=0 を維持する。
release 後に 1clock RAM 再 read を行い、その次 edge から CPU を再開する。
`pc_enable` gate だけで止める案では ready を無効化できず、debug read の残りを
CPU 応答として consume するので、top に別途 release/prime 期間が必須。

RAM の address/write_en/din は一体として選択する。

| owner | address | write_en | din | CPU |
| --- | --- | --- | --- | --- |
| RESET | 任意固定 | 0 | 0 | reset |
| BOOT | boot_loader出力 | boot write | ROM byte | reset |
| DEBUG | debug_addr | 0 | 0 | hold |
| CPU | cpu_address_bus[14:0] | cpu_write_en && !address_bus[15] | cpu_data_out | run |

優先順位は RESET、BOOT、DEBUG、CPU。
boot_loader の既存 boot/CPU mux を維持する場合も、debug はその出力の全 tuple を override する。
boot 中は debug 要求を受付けず、clear/IFO state を開始しない。
boot 最終 byte を書いた edge で boot_done になり、CPU は reset 解除後に最初の read を prime する。
ROM は現状 combinational case で、copy に ROMread wait は不要。
ROM を同期化する場合は別変更として boot の request/wait/write 設計も変更する。
reset 中の `boot_active ? 1 : ...` による RAM write は rst_n gate で止める。

IFO 受付 edge で PC/A/X/Y/P/S を capture する。
PC の意味は「IFO が retire した後の次命令 address」と定義する。
CPU は render 全期間 hold し、文字列は capture 値から作る。
RAM dump は request→wait→capture の 3 段階とし、capture した byte だけから
両 nibble と bit 表示を生成する。

```text
ADDR edge: debug_addrを変更
WAIT edge: RAMが新addressをsampleしdoutを更新
CAPTURE edge: debug_byte <= ram_data_out
RENDER edges: debug_byteの上位/下位/bitを使用
```

CPU を止めたまま `$0000–$007F` を読むので、全 dump も同一 CPU 停止状態に対応する。
128byte 配列の全 snapshot を追加しなくても整合性は保てる。
CPU 再開を早める最適化は別途行う。

CVR は clear-only 要求として S_CLEAR へ進め、1024 address へ space を書き終えたら終了。
IFO は clear→regs→memory 表示へ進む。要求種別を latched flag に保持する。
最後の `vram_cea` registered write が次 edge で retire するため、DRAIN state を入れてから
busy を解除する。request 受付から done まで CPU は次の要求を発行できないので、
CPU 起因の busy 中要求 queue は不要。外部起因要求を追加する場合は別途 pending が必要。

Verilator VRAM モデルにも write port を追加し、同じ writer signal を接続する。
vendor VRAM wrapper は維持する。

## 保持すべきinvariant

1. CPU が data_in を consume する前に、CPU 所有の address が少なくとも 1read edge 保持された。
2. 発行した CPU write は正しい address/data でちょうど 1edge 受理される。
   hold/reset 以外では発行 write を gate して消さない。
3. DEBUG 所有中に RAM write は 0。BOOT と DEBUG を同時選択しない。
4. hold 中の PC/register/state/address は不変。pulse clear と read-ready 無効化は動作する。
5. IFO の両 nibble は同一 capture byte、レジスタは同一 capture epoch に由来する。
6. CVR/IFO は 1 命令につき 1 受付、1 完了。完了は最後の VRAM write retirement より後。
7. reset は owner/pending/busy を消し、boot から再開始し、描画途中の旧要求を再生しない。
8. owner が CPU へ戻っても debug dout を consume せず、CPUread を再 prime する。

WVS は別の注意点がある。unconditional bubble 追加時に vsync edge を実行 edge だけで
観測すると短い pulse を見逃す。vsync は hardware の LCD_CLK→MEMORY_CLK を同期し、
毎 cpu_clk で edge を観測、必要なら pending を保持して WAIT_VSYNC で 1 回 consume する。
`vsync_prev` を毎 clk に移すだけでは bubble 中に edge が消えるので不十分。
count=0/1 の現在契約、要求前 edge の破棄、hold 中の event の扱いを TB と文書で固定する。

## 後続実装のtests / 順序

1. Day 10 completed を先行し、実 `ram.sv` を接続した同期 RAM CPU TB。
   reset 後 first fetch、LDA immediate、PHA/PLA、JSR/RTS の低/高 byte を確認。
2. enable 常時 1、4/16cycle に 1pulse、write 発行直後に enable 停止の 3 条件を同じ program で実行。
   最終値だけでなく write 受理回数/address/data も scoreboard で確認。
3. Day 11–18 に展開し、ZP/ABS/indexed/indirect、branch taken/not-taken、INC/DEC の
   read-modify-write、stack page wrap を各 Day の実装命令に合わせて検査。
4. Day 18 は boot→最初の opcode までの統合 TB を追加し、256byte 全一致と
   reset 中 write なし、boot 終了前 CPU 進行なしを検査。
5. Day 18 IFO/CVR 統合 TB で、IFO 直後に store を置き描画完了まで store が進まないこと、
   dump 中 RAM write が 0 で全 RAM が保持されること、snapshot 文字列/128byte dump の一致を確認。
   byte 値は隣接 address で異なる pattern にして 1byte 遅れ/nibble 混在を検出する。
6. CVR のみ、IFO→CVR、CVR→IFO、IFO 連続、途中 reset、最後の VRAMwrite retirement を検査。
   最終 VRAM 配列を確認し、writer の信号だけで成功としない。
7. hold 解除後の opcode/operand fetch、1clock vsync edge が settle と重なる WVS も確認。
8. cycle 数固定の TB を更新する。bounded timeout 内の architectural 結果と event 数を判断し、
   CPU 内部 state を force する方法で同期 read 問題を隠さない。
9. starter は lint/compile で契約を確認し、TODO 未実装を completed 同等の pass と報告しない。

今回実行したのはコード調査と比較であり、この後続設計のシミュレーションは未実行。
Gowin synthesis、primitive timing、LCD の CDC/表示、実機での fullspeed は別受入条件。
Makefiles/TB を編集中の GLM 成果物が固まってから、この順序で実装・検証する。
