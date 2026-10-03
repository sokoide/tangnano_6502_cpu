# Day 99 CPU・メモリ・LCDの設計調査

作成日: 2026-10-02
対象: [改善計画](REVIEW_IMPROVEMENT_PLAN_ja.md) R03/R06/R07/R08/R09
状態: **設計提案。RTL未変更、シミュレーション・合成・実機検証未実施。**

ユーザー指定順序は GLM修正 → Solレビュー → Sol設計修正。GLMの命令FSM修正中に同じRTLを編集しない。本書は後続実装の責任範囲と契約を具体化するもので、実装完了を表すものではない。

## 1. 現行経路と問題

実稼働経路は `top_9k/top_20k → top_core → cpu → calc_cpu_next`。`cpu_memory.sv` は現在のCPUからinstantiateされていないため、この参考モジュールを直すだけではメモリ問題は解消しない。

- RAM/VRAM vendor IPは `READ_MODE=0`, `RESET_MODE="SYNC"`。同梱SDPB modelではCEBによってbypass出力を更新し、OCEは追加pipeline registerだけに作用する。`ram.sv` とVRAM stubの `ceb && oce` は不一致。
- 同梱SDPB modelのwrite enableは `pcea = CEA && bs_ena`。RESETAは書込みを抑止しない。behavioral modelの `!reseta && cea` は異なる契約になっている。
- `cpu.sv` のboot配列は7680 byteだが、状態に無関係に `boot_program[cur.boot_idx]` を参照する。loaderはlengthを最後のindexとして扱い、1 byte余分に書く。
- storeのVRAM decodeは1020 byte、実RAM容量は1024 byte。clearはVRAM側の次indexとshadow側の旧indexを使う。通常store、RMW、内部表示書込みの契約が分散している。
- PC/branch計算まで `$7FFF` maskを適用しており、CPUの16bit演算と32KiB RAMの物理変換が混ざっている。
- LCDアドレスを多bit 2FFで渡しても値全体の整合性は保証できない。font address/dataにもCDCが残る。
- PLL wrapperはLOCKを内部 `lock_o` に閉じ込め、公開portはclkout/clkinのみ。既存portのままlockに基づくresetを実装できない。

## 2. 実装の所有ファイルと分担

| 担当 | 所有ファイル | 責任 |
| --- | --- | --- |
| CPU | `day99_completed/src/cpu.sv`, `src/cpu/cpu_types_pkg.sv`, `src/cpu/cpu_fsm_next_pkg.sv`, `include/consts_pkg.sv`, `include/cpu_pkg.sv` | boot、write発行、16bit CPU address、領域decode、fault、clear/shadow整合 |
| メモリ | `day99_completed/src/ram.sv`, `sim/gowin_sdpb_vram_stub.sv`、新規RAM契約テスト | bypassのCE/OCE/reset契約、VRAM dual-clock port、vendorとの系列比較 |
| LCD/clock統合 | `day99_completed/src/top_core.sv`, `src/top_9k.sv`, `src/top_20k.sv`, `src/lcd.sv`, 新規 `src/platform_clocks.sv`, 新規 `src/reset_sync.sv`, `sim/gowin_prom_font_stub.sv`、新規表示/clockテスト | pixel domainへVRAM/font移動、pipeline、PLL lock、各domain reset |
| build統合 | `day99_completed/Makefile`, `day99_9k.gprj`, `day99_20k.gprj` | 新規RTLの登録、BOARD parameter、simulation/vendor契約testの経路、依存manifest |
| 文書 | `day99_completed/docs/GVRAM_ja.md`, `docs/LCD.md`, `docs/DEVELOPER.md`、本書/改善計画 | 決定したaddress map、timing、未検証範囲の明記 |

`src/cpu/cpu_fsm_next_pkg.sv` をGLMと後続CPU担当が同時に変更しない。`src/top_core.sv` はLCD/clock統合担当が所有し、メモリ担当はportの変更を連絡する。build統合はRTL interface確定後に行う。generated/vendorファイルは編集しない。

## 3. CPU・メモリの契約

### Boot

容量を `BOOT_CAPACITY=7680`、lengthをbyte数とする。生成器、linker、CPU portの容量を一致させる。現HEX生成器には既に空入力・容量超過拒否が実装されているが、この調査では実行していない。

1. `length == 0` または `length > BOOT_CAPACITY` は、RAM writeなしで明示fault/停止する。
2. INIT_RAMかつ `idx < length && idx < BOOT_CAPACITY` の場合だけboot byteを参照する。範囲外の入力はゼロなど固定値とし、配列をindexしない。
3. byte準備 → registered CEAによる実際のwrite edge → idx更新の順序を維持する。
4. 最後のwrite edgeが終わるまでFETCH_REQへ解放しない。合法lengthのwrite数は厳密にlengthとする。

### 書込みとVRAM/shadow

`calc_cpu_next` の標準値を `next.cea=0; next.v_cea=0;` とし、writeを発行するcaseだけ再設定する。通常storeのwrite enableをFETCH_REQで保持しない。clearは各edgeで異なるセルへ連続writeしてよい。

定数は `VRAM_CAPACITY=1024`, `VISIBLE_CELLS=COLUMNS*ROWS=1020` に分ける。通常STA/STX/STY/RMW writeの領域decodeを一つのhelperに集約する。内部VRAM writeの不変条件は以下とする。

```text
0 <= i < VRAM_CAPACITY
v_ada = i
ada   = SHADOW_VRAM_START + i
din   = v_din
cea   = v_cea = 1
```

shadowの直接CPU storeは拒否し、内部VRAM更新のみがshadowを書ける。clearは容量全1024セルをspaceで埋める案を推奨する。表示1020セルに加え未表示4セルも決定的な値になる。clearの終了は最終セルwrite edge後とし、次のindexへのwrapや余分なwriteを生まない。

VRAM RMWにはread値の決定が必要。**推奨はVRAM readをshadow readへ変換する仕様**であり、VRAMはread/write、shadowはCPU read-onlyとして文書を更新する。write-onlyを維持するならVRAM RMWを明示faultにする。これは実装前に採用方針を一つに固定する必要がある。

### 16bit CPU addressとphysical decode

PC加算・branch・absolute/indexed実効アドレスは16bit wrap、zero-page indexedは8bit wrapとする。15bit化はメモリdecodeでのみ行う。

小さい変更で現在のRAM mirrorを維持する案なら、上位領域を正式なplatform仕様として列挙し、VRAM decodeをmirrorより優先する。shadowのmirror aliasへのwriteも拒否し、read-only保護を迂回できないようにする。mirrorを廃止してunmapped領域を設ける案では、現在の15bit `adb` だけで識別できないためCPU contextにfull read address/validを追加する。暗黙のmaskを残して「unmapped対応済み」としない。

### RAM timing/reset/collision

- main RAM: write/readともMEMORY_CLK。VRAM: write MEMORY_CLK、read PixelClk。
- READ_MODE=0: read clock edgeでCEB=1なら出力更新、CEB=0なら保持。OCE=0でもbypass出力は更新する。
- RESETBはread clockで出力registerをゼロにする。メモリ内容を消さない。
- RESETAにwrite抑止を依存させない。CPU CEA reset値と、必要ならtopの `cea & memory_rst_n` で保証する。
- dual-clock同addr read/write衝突のold/new値にportableな保証を置かない。vendor modelとの比較は非衝突系列およびwrite完了後のread一致を対象にする。連続表示中のCPU更新は一時的な表示変化を許容し、frame atomicityを保証しない。

## 4. LCD domainとpipeline

`ram.sv` にPixelClk入力を追加し、VRAM vendor `clkb` だけをPixelClkへ移す。font ROMのclkもPixelClkへ移す。`top_core.sv` の `v_adb_sync1/2` を削除する。既存vendor VRAM/font wrapperの公開portで実現でき、vendor編集は不要。

clock接続変更だけでは既存lcdのstage間隔は成立しない。registered addressを発行した次edgeでcaptureすると、同じedgeのRAM NBA更新前の旧dataを読む。旧CHAR_FETCH_OFFSETを温存して動作確認をsmokeだけに任せない。

推奨pipelineは全pixelを処理し、addressを組合せ生成する。

| edge | memory動作 | LCD metadata |
| --- | --- | --- |
| E0 | 現beam座標の組合せVRAM addressをRAMが読む | row/bit index/validをstage0へ登録 |
| E1 | E0のv_doutとstage0 rowから組合せfont addressをROMが読む | bit index/valid/char error判定をstage1へ登録 |
| E2 | E1のfont byteを受けRGBを登録 | stage1 validをDEへ登録し、同じbit indexで画素選択 |

DEもRGBと同じpipelineへ遅延する案なら、480 pixelのactive幅を保ったまま内部beamに対し開始を2edge遅らせる。従来porch配置を厳密に保つ必要がある場合は2pixel先読みを設計する。どちらかを明記し、reset後のpipeline validはゼロにする。

counterは `0..TOTAL-1` を回す。現コードの `==PixelForHS` / `==PixelForVS` は1clock余分に回る。縦進行は横wrap時のみ更新し、vsyncが旧V値によって1行ずれないようにする。vsyncのCPU受信は既存2FFを使い、単bit CDCの受信domainで同期する。

font simulationは全zero stubを変更し、実 `data/font.mi` またはvendor INIT値から生成した、検証可能なnonzero内容を使う。MIはコメント/metadata行を含むため、そのまま `$readmemh` へ渡さず厳密に変換する。generated/vendor本体は変更しない。

## 5. PLL wrapperとreset policy

既存LOCKのhierarchical参照は合成portable性に依存するため採用しない。新しい手書き `platform_clocks.sv` がrPLL primitiveを2個instantiateし、clockとLOCKを公開する案を推奨する。既存vendor PLLソースは変更せず保持する。

現物の確認値:

| parameter | pixel 9K | pixel 20K | memory 9K | memory 20K |
| --- | --- | --- | --- | --- |
| DEVICE | `GW1NR-9C` | `GW2AR-18C` | `GW1NR-9C` | `GW2AR-18C` |
| FCLKIN | `"27"` | `"27"` | `"27"` | `"27"` |
| IDIV_SEL | 2 | 2 | 1 | 1 |
| FBDIV_SEL | 0 | 0 | 2 | 2 |
| ODIV_SEL | 48 | 64 | 16 | 16 |
| PSDA_SEL | `"0000"` | 同左 | 同左 | 同左 |
| DUTYDA_SEL | `"1000"` | 同左 | 同左 | 同左 |
| DYN_DA_EN | `"true"` | 同左 | 同左 | 同左 |
| DYN_SDIV_SEL | 2 | 2 | 2 | 2 |

上記は `src/gowin_rpll_9K/gowin_rpll9.v`, `gowin_rpll40.v`, `src/gowin_rpll_20K/gowin_rpll9.v`, `gowin_rpll40.v` から確認した値。残る設定も既存値を保存する: DYN_IDIV/FBDIV/ODIV_SEL=false、CLKFB_SEL=internal、全CLKOUT*_BYPASS=false、CLKOUT/CLKOUTP_FT_DIR=1、DLY_STEP=0、CLKOUTD/CLKOUTD3_SRC=CLKOUT。dynamic selector/CLKFBはゼロ接続。

BOARD差は `top_20k` から `top_core`/clock wrapperへ明示parameterで渡す。simulationの `BOARD_20K` defineだけにhardware選択を依存させない。

reset policy:

1. board wrapperで既存ResetButton極性を正規化する。9Kは `rst_n=ResetButton`、20Kは `rst_n=~ResetButton`。コメントのactive-high/low表現だけで極性を変更しない。
2. PLL primitive RESETへ接続する場合は外部button resetのみを使う。LOCK由来resetをPLL自身へ戻して循環依存を作らない。
3. user logicの非同期reset条件は `rst_n && pixel_lock && memory_lock`。各clock domainに2FF同期releaseを設ける。button resetまたはどちらかのlock喪失で両domainを即assertする。
4. memory domain release前にCPU/writeを動かさない。pixel domain release前にDE/pipeline validをゼロにする。RAM内容の初期化はこのresetの役割に含めない。
5. simulationは直結PLL stubではなく9MHz/40.5MHzとLOCK遅延・喪失を表すclock modelにする。複数位相で実行する。metastabilityの実耐性はsimulation成功から証明しない。

## 6. 後続検証順と受入条件

| 順序 | 検査 | 合格条件 |
| --- | --- | --- |
| 1 | GLMの命令修正を独立レビュー | 命令結果・flag・stack・unsupported opcodeが期待仕様と一致 |
| 2 | RAM契約単体 | CEB=0保持、CEB=1/OCE=0更新、RESETB output reset、内容保持をbehavioral/vendor同一系列で確認 |
| 3 | boot | length 0/1/7679/7680/7681。合法値のwrite数=length、address範囲厳密一致、最終write前fetch禁止、不合法値writeなし |
| 4 | CPU write/address | `$DFFF/$E000/$E3FB/$E3FC/$E3FF/$E400`、shadow両端とmirror alias、STA/STX/STY/RMW、要求ごとのwrite回数 |
| 5 | clear | 全1024セルとshadowがspaceで一致。各indexへのwriteは1回。完了後にwriteが残らない |
| 6 | CPU wrap | zero-page `$FF`、PC `$7FFF/$FFFF`、正負branch。CPU16bit値と物理addressを別々に検査 |
| 7 | LCD画像/timing | nonzero font、文字の先頭/末尾、行境界、最終セル。DEN幅480、272 active行、TOTAL周期、bit向き、pipeline整合 |
| 8 | 非同期clock/reset | 9MHz/40.5MHzで複数位相。LOCK待ち/喪失/relock、各domain同期release、reset中write禁止 |
| 9 | FPGA | 9K/20K両方で合成・配置配線・timing/CDC評価。PLL設定、VRAM dual-clock推論/IP接続、追加logicの資源を確認 |
| 10 | 実機 | 両boardのcold boot/button reset/連続表示/CPU更新中表示を確認。実機未実施は未証明として残す |

故意にread enable/write pulse/font latencyを壊した場合に対応テストが非ゼロ終了することも確認する。独立 `cpu_memory` テストやDEN/colorのみのsmoke成功を、現CPU・文字pipelineの受入に代用しない。
