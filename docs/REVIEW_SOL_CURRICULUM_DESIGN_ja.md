# Day 10–18 同期RAM / Day 18表示要求の最小設計

2026-10-02、GPT 6.1 Solによるread-only調査。CPU/RAM/lcd_demo、vendor、generatedは変更していない。
GLM-5.3のMakefile/TB変更とは独立した、後続Sol実装の設計資料。

## 現状と失敗条件

- Day 10–18のstarter/completedの `ram.sv` は各Dayで同一。
  Verilatorは `assign dout = mem[addr]` による非同期read。
  hardwareはCLKB/CEBを持つGowin_SDPB、`READ_MODE=0`、bank選択もDFFE。
  simulationの即時応答がCPUの待ち不足を隠す。
- completed CPUは `address_bus <= ...` と次stateを同じedgeで更新し、次edgeで
  `data_in` をconsumeする。同期readではその次edgeのRAM出力更新はNBA後なので、
  CPUは新addressの応答より前の値をconsumeする。
- Day 10–17のhardwareは24bit counterによる疎な `pc_enable`。
  addressが十分長く保持され、待ち不足が偶然見えない。
  Day 11–17のVerilatorはfull speed、Day 18は両経路full speed。
- `write_en <= 0` が `else if (pc_enable)` の中にある。
  push/store後にenableが止まるとRAMは同一writeを次enableまで繰り返す。
  RAMの同じbyteへの繰返しは値だけでは検出できず、将来のMMIOでは副作用になる。
- Day 18 completed `lcd_demo.sv:607` はIFO表示中にRAMのaddressだけをdebugへ切替え、
  write_en/dinはCPUのまま。CPUは止まらないのでdebug領域への誤書込と誤readが起こる。
  `ram_data_out` を別edgeで上位/下位nibbleとして使い、byteの一致も保証しない。
  debug_addr更新直後の次edgeで上位nibbleをconsumeする経路も同期readに待ち不足。
- レジスタ文字列はlive CPU値から複数edgeに渡って作るので、同一時点のsnapshotでない。
  `cpu_vram_clear` はtopで使用されず、CVR単独ではclearを実行しない。
- Verilatorの `lcd/vram.sv` は表示read専用の初期文字列であり、topの
  vram_cea/ada/dinを接続していない。CPU要求を検査しても実際のVRAM更新は検証できない。
- starter CPUはTODO skeletonでcompletedとは異なる。
  課題の解答をコピーせず、interfaceと同期memoryの教材契約を揃える。

## 推奨するCPU / RAM変更

RAMのVerilator分岐を同期readへ変更する。

```systemverilog
always_ff @(posedge clk) begin
    if (write_en) mem[addr] <= din;
    dout <= mem[addr];
end
```

同edge read/writeの値には依存しない。上記モデルはold dataを返すが、
実primitiveのcollision semanticsと完全一致するとはこの調査だけでは断定しない。
vendor/generatedを変更せず、必要なら同梱primitive modelによる別検証を行う。

CPU全microstate間に1clockのsettleを挟む `memory_ready` を最小案とする。
opcodeごとのWAIT stateを大量追加するより全bus更新経路の漏れが少ない。
execute時にready=0、次clkでready=1、次のenable時にconsumeする。
waitはpc_enableに関係なく進め、reset直後もready=0とする。

| edge | CPU | 同期RAM |
| --- | --- | --- |
| t0 | state実行、新addressをNBAでdrive、ready=0 | 旧addressをread |
| t1 | settleのみ、ready=1 | 新addressをreadしてdoutをNBA更新 |
| t2 | enable時に新doutをconsume | 保持addressをread |

全stateにbubbleを挟むのでfullspeedのmicrostate throughputは最大1/2になる。
6502のcycle精密化は今回の教材修正範囲に含めず、この変更を文書化する。
疎なenableの次パルスはsettle完了後なので従来の1パルス1microstateを維持できる。
settle中に到着する単発enableは実行できないため、manual stepを全受付する必要があるなら
1bit pendingを追加し、ready後に一度だけ消費する。これを黙って無視する仕様にはしない。

`write_en` はreset以外の毎clkでdefault0とし、state実行時のwriteだけ1にする。
address/dataはそのwriteがRAMで受理される次edgeまで保持する。
`write_en && pc_enable` の組合せgateだけで修正しない。
CPUがregistered writeを発行した次edgeにenableが0ならwrite自体が消えるためである。

Day 18の `vram_clear/show_info` も毎clkの単発pulseにする。
CPU hold中もwrite/requestのdefault clearは動作し、architectural stateだけ停止する。
starterには同期RAM契約とpulse scaffoldを用意し、命令TODOを残す。
全CPU instanceとTBをinterface変更に追従させる。

## Day 18: IFO / CVR とmemory所有権

最小実装は「要求を受けたらCPUを停止し、描画完了後に再開」。
CPUから1clock request、topからholdを返す。要求とbusyを組み合わせたholdにより、
要求がhighの次edgeにCPUが次命令へ進むraceを防ぐ。
IFO/CVRは命令境界で発行され、未完了writeがないことをassertする。
writeのある任意stateで外部停止するなら、停止受理前にwriteを1回retireさせるDRAINが必要。

Day 18 CPUに明示的 `memory_hold` 入力を追加する案を推奨する。
hold中はmemory_ready=0を維持する。
release後に1clock RAM再readを行い、その次edgeからCPUを再開する。
`pc_enable` gateだけで止める案ではreadyを無効化できず、debug readの残りを
CPU応答としてconsumeするので、topに別途release/prime期間が必須。

RAMのaddress/write_en/dinは一体として選択する。

| owner | address | write_en | din | CPU |
| --- | --- | --- | --- | --- |
| RESET | 任意固定 | 0 | 0 | reset |
| BOOT | boot_loader出力 | boot write | ROM byte | reset |
| DEBUG | debug_addr | 0 | 0 | hold |
| CPU | cpu_address_bus[14:0] | cpu_write_en && !address_bus[15] | cpu_data_out | run |

優先順位はRESET、BOOT、DEBUG、CPU。
boot_loaderの既存boot/CPU muxを維持する場合も、debugはその出力の全tupleをoverrideする。
boot中はdebug要求を受付けず、clear/IFO stateを開始しない。
boot最終byteを書いたedgeでboot_doneになり、CPUはreset解除後に最初のreadをprimeする。
ROMは現状combinational caseで、copyにROMread waitは不要。
ROMを同期化する場合は別変更としてbootのrequest/wait/write設計も変更する。
reset中の `boot_active ? 1 : ...` によるRAM writeはrst_n gateで止める。

IFO受付edgeでPC/A/X/Y/P/Sをcaptureする。
PCの意味は「IFOがretireした後の次命令address」と定義する。
CPUはrender全期間holdし、文字列はcapture値から作る。
RAM dumpはrequest→wait→captureの3段階とし、captureしたbyteだけから
両nibbleとbit表示を生成する。

```text
ADDR edge: debug_addrを変更
WAIT edge: RAMが新addressをsampleしdoutを更新
CAPTURE edge: debug_byte <= ram_data_out
RENDER edges: debug_byteの上位/下位/bitを使用
```

CPUを止めたまま `$0000–$007F` を読むので、全dumpも同一CPU停止状態に対応する。
128byte配列の全snapshotを追加しなくても整合性は保てる。
CPU再開を早める最適化は別途行う。

CVRはclear-only要求としてS_CLEARへ進め、1024 addressへspaceを書き終えたら終了。
IFOはclear→regs→memory表示へ進む。要求種別をlatched flagに保持する。
最後の `vram_cea` registered writeが次edgeでretireするため、DRAIN stateを入れてから
busyを解除する。request受付からdoneまでCPUは次の要求を発行できないので、
CPU起因のbusy中要求queueは不要。外部起因要求を追加する場合は別途pendingが必要。

Verilator VRAMモデルにもwrite portを追加し、同じwriter signalを接続する。
vendor VRAM wrapperは維持する。

## 保持すべきinvariant

1. CPUがdata_inをconsumeする前に、CPU所有のaddressが少なくとも1read edge保持された。
2. 発行したCPU writeは正しいaddress/dataでちょうど1edge受理される。
   hold/reset以外では発行writeをgateして消さない。
3. DEBUG所有中にRAM writeは0。BOOTとDEBUGを同時選択しない。
4. hold中のPC/register/state/addressは不変。pulse clearとread-ready無効化は動作する。
5. IFOの両nibbleは同一capture byte、レジスタは同一capture epochに由来する。
6. CVR/IFOは1命令につき1受付、1完了。完了は最後のVRAM write retirementより後。
7. resetはowner/pending/busyを消し、bootから再開始し、描画途中の旧要求を再生しない。
8. ownerがCPUへ戻ってもdebug doutをconsumeせず、CPUreadを再primeする。

WVSは別の注意点がある。unconditional bubble追加時にvsync edgeを実行edgeだけで
観測すると短いpulseを見逃す。vsyncはhardwareのLCD_CLK→MEMORY_CLKを同期し、
毎cpu_clkでedgeを観測、必要ならpendingを保持してWAIT_VSYNCで1回consumeする。
`vsync_prev` を毎clkに移すだけではbubble中にedgeが消えるので不十分。
count=0/1の現在契約、要求前edgeの破棄、hold中のeventの扱いをTBと文書で固定する。

## 後続実装のtests / 順序

1. Day 10 completedを先行し、実 `ram.sv` を接続した同期RAM CPU TB。
   reset後first fetch、LDA immediate、PHA/PLA、JSR/RTSの低/高byteを確認。
2. enable常時1、4/16cycleに1pulse、write発行直後にenable停止の3条件を同じprogramで実行。
   最終値だけでなくwrite受理回数/address/dataもscoreboardで確認。
3. Day 11–18に展開し、ZP/ABS/indexed/indirect、branch taken/not-taken、INC/DECの
   read-modify-write、stack page wrapを各Dayの実装命令に合わせて検査。
4. Day 18はboot→最初のopcodeまでの統合TBを追加し、256byte全一致と
   reset中writeなし、boot終了前CPU進行なしを検査。
5. Day 18 IFO/CVR統合TBで、IFO直後にstoreを置き描画完了までstoreが進まないこと、
   dump中RAM writeが0で全RAMが保持されること、snapshot文字列/128byte dumpの一致を確認。
   byte値は隣接addressで異なるpatternにして1byte遅れ/nibble混在を検出する。
6. CVRのみ、IFO→CVR、CVR→IFO、IFO連続、途中reset、最後のVRAMwrite retirementを検査。
   最終VRAM配列を確認し、writerの信号だけで成功としない。
7. hold解除後のopcode/operand fetch、1clock vsync edgeがsettleと重なるWVSも確認。
8. cycle数固定のTBを更新する。bounded timeout内のarchitectural結果とevent数を判断し、
   CPU内部stateをforceする方法で同期read問題を隠さない。
9. starterはlint/compileで契約を確認し、TODO未実装をcompleted同等のpassと報告しない。

今回実行したのはコード調査と比較であり、この後続設計のシミュレーションは未実行。
Gowin synthesis、primitive timing、LCDのCDC/表示、実機でのfullspeedは別受入条件。
Makefiles/TBを編集中のGLM成果物が固まってから、この順序で実装・検証する。
