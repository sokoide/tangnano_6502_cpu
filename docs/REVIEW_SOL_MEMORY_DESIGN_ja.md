# Day 99 CPU・メモリ・LCDの設計調査

作成日: 2026-10-02
対象: [改善計画](REVIEW_IMPROVEMENT_PLAN_ja.md) R03/R06/R07/R08/R09
状態: **設計提案。RTL未変更、シミュレーション・合成・実機検証未実施。**

ユーザー指定順序は GLM 修正 → Sol レビュー → Sol 設計修正。GLM の命令 FSM 修正中に同じ RTL を編集しない。本書は後続実装の責任範囲と契約を具体化するもので、実装完了を表すものではない。

## 1. 現行経路と問題

実稼働経路は `top_9k/top_20k → top_core → cpu → calc_cpu_next`。`cpu_memory.sv` は現在の CPU から instantiate されていないため、この参考モジュールを直すだけではメモリ問題は解消しない。

- RAM/VRAM vendor IP は `READ_MODE=0`, `RESET_MODE="SYNC"`。同梱 SDPB model では CEB によって bypass 出力を更新し、OCE は追加 pipeline register だけに作用する。`ram.sv` と VRAM stub の `ceb && oce` は不一致。
- 同梱 SDPB model の write enable は `pcea = CEA && bs_ena`。RESETA は書き込みを抑止しない。behavioral model の `!reseta && cea` は異なる契約になっている。
- `cpu.sv` の boot 配列は 7680 byte だが、状態に無関係に `boot_program[cur.boot_idx]` を参照する。loader は length を最後の index として扱い、1 byte 余分に書く。
- store の VRAM decode は 1020 byte、実 RAM 容量は 1024 byte。clear は VRAM 側の次 index と shadow 側の旧 index を使う。通常 store、RMW、内部表示書き込みの契約が分散している。
- PC/branch 計算まで `$7FFF` mask を適用しており、CPU の 16bit 演算と 32KiB RAM の物理変換が混ざっている。
- LCD アドレスを各ビットの 2 段 FF で渡しても値全体の整合性は保証できない。font address/data にも CDC が残る。
- PLL wrapper は LOCK を内部 `lock_o` に閉じ込め、公開 port は clkout/clkin のみ。既存 port のまま lock に基づく reset を実装できない。

## 2. 実装の所有ファイルと分担

| 担当          | 所有ファイル                                                                                                                                                                                     | 責任                                                                          |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------- |
| CPU           | `day99_completed/src/cpu.sv`, `src/cpu/cpu_types_pkg.sv`, `src/cpu/cpu_fsm_next_pkg.sv`, `include/consts_pkg.sv`, `include/cpu_pkg.sv`                                                           | boot、write発行、16bit CPU address、領域decode、fault、clear/shadow整合       |
| メモリ        | `day99_completed/src/ram.sv`, `sim/gowin_sdpb_vram_stub.sv`、新規RAM契約テスト                                                                                                                   | bypassのCE/OCE/reset契約、VRAM dual-clock port、vendorとの系列比較            |
| LCD/clock統合 | `day99_completed/src/top_core.sv`, `src/top_9k.sv`, `src/top_20k.sv`, `src/lcd.sv`, 新規 `src/platform_clocks.sv`, 新規 `src/reset_sync.sv`, `sim/gowin_prom_font_stub.sv`、新規表示/clockテスト | pixel domainへVRAM/font移動、pipeline、PLL lock、各domain reset               |
| build統合     | `day99_completed/Makefile`, `day99_9k.gprj`, `day99_20k.gprj`                                                                                                                                    | 新規RTLの登録、BOARD parameter、simulation/vendor契約testの経路、依存manifest |
| 文書          | `day99_completed/docs/GVRAM_ja.md`, `docs/LCD.md`, `docs/DEVELOPER.md`、本書/改善計画                                                                                                            | 決定したaddress map、timing、未検証範囲の明記                                 |

`src/cpu/cpu_fsm_next_pkg.sv` を GLM と後続 CPU 担当が同時に変更しない。`src/top_core.sv` は LCD/clock 統合担当が所有し、メモリ担当は port の変更を連絡する。build 統合は RTL interface 確定後に行う。generated/vendor ファイルは編集しない。

## 3. CPU・メモリの契約

### Boot

容量を `BOOT_CAPACITY=7680`、length を byte 数とする。生成器、linker、CPU port の容量を一致させる。現 HEX 生成器には既に空入力・容量超過拒否が実装されているが、この調査では実行していない。

1. `length == 0` または `length > BOOT_CAPACITY` は、RAM write なしで明示 fault/停止する。
2. INIT_RAM かつ `idx < length && idx < BOOT_CAPACITY` の場合だけ boot byte を参照する。範囲外の入力はゼロなど固定値とし、配列を index しない。
3. byte 準備 → registered CEA による実際の write edge → idx 更新の順序を維持する。
4. 最後の write edge が終わるまで FETCH_REQ へ解放しない。合法 length の write 数は厳密に length とする。

### 書き込みとVRAM/shadow

`calc_cpu_next` の標準値を `next.cea=0; next.v_cea=0;` とし、write を発行する case だけ再設定する。通常 store の write enable を FETCH_REQ で保持しない。clear は各 edge で異なるセルへ連続 write してよい。

定数は `VRAM_CAPACITY=1024`, `VISIBLE_CELLS=COLUMNS*ROWS=1020` に分ける。通常 STA/STX/STY/RMW write の領域 decode を一つの helper に集約する。内部 VRAM write の不変条件は以下とする。

```text
0 <= i < VRAM_CAPACITY
v_ada = i
ada   = SHADOW_VRAM_START + i
din   = v_din
cea   = v_cea = 1
```

shadow の直接 CPU store は拒否し、内部 VRAM 更新のみが shadow を書ける。clear は容量全 1024 セルを space で埋める案を推奨する。表示 1020 セルに加え未表示 4 セルも決定的な値になる。clear の終了は最終セル write edge 後とし、次の index への wrap や余分な write を生まない。

VRAM RMW には read 値の決定が必要。**推奨はVRAM readをshadow readへ変換する仕様**であり、VRAM は read/write、shadow は CPU read-only として文書を更新する。write-only を維持するなら VRAM RMW を明示 fault にする。これは実装前に採用方針を一つに固定する必要がある。

### 16bit CPU addressとphysical decode

PC 加算・branch・absolute/indexed 実効アドレスは 16bit wrap、zero-page indexed は 8bit wrap とする。15bit 化はメモリ decode でのみ行う。

小さい変更で現在の RAM mirror を維持する案なら、上位領域を正式な platform 仕様として列挙し、VRAM decode を mirror より優先する。shadow の mirror alias への write も拒否し、read-only 保護を迂回できないようにする。mirror を廃止して unmapped 領域を設ける案では、現在の 15bit `adb` だけで識別できないため CPU context に full read address/valid を追加する。暗黙の mask を残して「unmapped 対応済み」としない。

### RAM timing/reset/collision

- main RAM: write/read とも MEMORY_CLK。VRAM: write MEMORY_CLK、read PixelClk。
- READ_MODE=0: read clock edge で CEB=1 なら出力更新、CEB=0 なら保持。OCE=0 でも bypass 出力は更新する。
- RESETB は read clock で出力 register をゼロにする。メモリ内容を消さない。
- RESETA に write 抑止を依存させない。CPU CEA reset 値と、必要なら top の `cea & memory_rst_n` で保証する。
- dual-clock 同 addr read/write 衝突の old/new 値に portable な保証を置かない。vendor model との比較は非衝突系列および write 完了後の read 一致を対象にする。連続表示中の CPU 更新は一時的な表示変化を許容し、frame atomicity を保証しない。

## 4. LCD domainとpipeline

`ram.sv` に PixelClk 入力を追加し、VRAM vendor `clkb` だけを PixelClk へ移す。font ROM の clk も PixelClk へ移す。`top_core.sv` の `v_adb_sync1/2` を削除する。既存 vendor VRAM/font wrapper の公開 port で実現でき、vendor 編集は不要。

clock 接続変更だけでは既存 lcd の stage 間隔は成立しない。registered address を発行した次 edge で capture すると、同じ edge の RAM NBA 更新前の旧 data を読む。旧 CHAR_FETCH_OFFSET を温存して動作確認を smoke だけに任せない。

推奨 pipeline は全 pixel を処理し、address を組合せ生成する。

| edge | memory動作                                              | LCD metadata                                      |
| ---- | ------------------------------------------------------- | ------------------------------------------------- |
| E0   | 現beam座標の組合せVRAM addressをRAMが読む               | row/bit index/validをstage0へ登録                 |
| E1   | E0のv_doutとstage0 rowから組合せfont addressをROMが読む | bit index/valid/char error判定をstage1へ登録      |
| E2   | E1のfont byteを受けRGBを登録                            | stage1 validをDEへ登録し、同じbit indexで画素選択 |

DE も RGB と同じ pipeline へ遅延する案なら、480 pixel の active 幅を保ったまま内部 beam に対し開始を 2edge 遅らせる。従来 porch 配置を厳密に保つ必要がある場合は 2pixel 先読みを設計する。どちらかを明記し、reset 後の pipeline valid はゼロにする。

counter は `0..TOTAL-1` を回す。現コードの `==PixelForHS` / `==PixelForVS` は 1clock 余分に回る。縦進行は横 wrap 時のみ更新し、vsync が旧 V 値によって 1 行ずれないようにする。vsync の CPU 受信は既存 2FF を使い、単 bit CDC の受信 domain で同期する。

font simulation は全 zero stub を変更し、実 `data/font.mi` または vendor INIT 値から生成した、検証可能な nonzero 内容を使う。MI はコメント/metadata 行を含むため、そのまま `$readmemh` へ渡さず厳密に変換する。generated/vendor 本体は変更しない。

## 5. PLL wrapperとreset policy

既存 LOCK の hierarchical 参照は合成 portable 性に依存するため採用しない。新しい手書き `platform_clocks.sv` が rPLL primitive を 2 個 instantiate し、clock と LOCK を公開する案を推奨する。既存 vendor PLL ソースは変更せず保持する。

現物の確認値:

| parameter    | pixel 9K   | pixel 20K   | memory 9K  | memory 20K  |
| ------------ | ---------- | ----------- | ---------- | ----------- |
| DEVICE       | `GW1NR-9C` | `GW2AR-18C` | `GW1NR-9C` | `GW2AR-18C` |
| FCLKIN       | `"27"`     | `"27"`      | `"27"`     | `"27"`      |
| IDIV_SEL     | 2          | 2           | 1          | 1           |
| FBDIV_SEL    | 0          | 0           | 2          | 2           |
| ODIV_SEL     | 48         | 64          | 16         | 16          |
| PSDA_SEL     | `"0000"`   | 同左        | 同左       | 同左        |
| DUTYDA_SEL   | `"1000"`   | 同左        | 同左       | 同左        |
| DYN_DA_EN    | `"true"`   | 同左        | 同左       | 同左        |
| DYN_SDIV_SEL | 2          | 2           | 2          | 2           |

上記は `src/gowin_rpll_9K/gowin_rpll9.v`, `gowin_rpll40.v`, `src/gowin_rpll_20K/gowin_rpll9.v`, `gowin_rpll40.v` から確認した値。残る設定も既存値を保存する: DYN_IDIV/FBDIV/ODIV_SEL=false、CLKFB_SEL=internal、全 CLKOUT*_BYPASS=false、CLKOUT/CLKOUTP_FT_DIR=1、DLY_STEP=0、CLKOUTD/CLKOUTD3_SRC=CLKOUT。dynamic selector/CLKFB はゼロ接続。

BOARD 差は `top_20k` から `top_core`/clock wrapper へ明示 parameter で渡す。simulation の `BOARD_20K` define だけに hardware 選択を依存させない。

reset policy:

1. board wrapper で既存 ResetButton 極性を正規化する。9K は `rst_n=ResetButton`、20K は `rst_n=~ResetButton`。コメントの active-high/low 表現だけで極性を変更しない。
2. PLL primitive RESET へ接続する場合は外部 button reset のみを使う。LOCK 由来 reset を PLL 自身へ戻して循環依存を作らない。
3. user logic の非同期 reset 条件は `rst_n && pixel_lock && memory_lock`。各 clock domain に 2FF 同期 release を設ける。button reset またはどちらかの lock 喪失で両 domain を即 assert する。
4. memory domain release 前に CPU/write を動かさない。pixel domain release 前に DE/pipeline valid をゼロにする。RAM 内容の初期化はこの reset の役割に含めない。
5. simulation は直結 PLL stub ではなく 9MHz/40.5MHz と LOCK 遅延・喪失を表す clock model にする。複数位相で実行する。metastability の実耐性は simulation 成功から証明しない。

## 6. 後続検証順と受入条件

| 順序 | 検査                        | 合格条件                                                                                                        |
| ---- | --------------------------- | --------------------------------------------------------------------------------------------------------------- |
| 1    | GLMの命令修正を独立レビュー | 命令結果・flag・stack・unsupported opcodeが期待仕様と一致                                                       |
| 2    | RAM契約単体                 | CEB=0保持、CEB=1/OCE=0更新、RESETB output reset、内容保持をbehavioral/vendor同一系列で確認                      |
| 3    | boot                        | length 0/1/7679/7680/7681。合法値のwrite数=length、address範囲厳密一致、最終write前fetch禁止、不合法値writeなし |
| 4    | CPU write/address           | `$DFFF/$E000/$E3FB/$E3FC/$E3FF/$E400`、shadow両端とmirror alias、STA/STX/STY/RMW、要求ごとのwrite回数           |
| 5    | clear                       | 全1024セルとshadowがspaceで一致。各indexへのwriteは1回。完了後にwriteが残らない                                 |
| 6    | CPU wrap                    | zero-page `$FF`、PC `$7FFF/$FFFF`、正負branch。CPU16bit値と物理addressを別々に検査                              |
| 7    | LCD画像/timing              | nonzero font、文字の先頭/末尾、行境界、最終セル。DEN幅480、272 active行、TOTAL周期、bit向き、pipeline整合       |
| 8    | 非同期clock/reset           | 9MHz/40.5MHzで複数位相。LOCK待ち/喪失/relock、各domain同期release、reset中write禁止                             |
| 9    | FPGA                        | 9K/20K両方で合成・配置配線・timing/CDC評価。PLL設定、VRAM dual-clock推論/IP接続、追加logicの資源を確認          |
| 10   | 実機                        | 両boardのcold boot/button reset/連続表示/CPU更新中表示を確認。実機未実施は未証明として残す                      |

故意に read enable/write pulse/font latency を壊した場合に対応テストが非ゼロ終了することも確認する。独立 `cpu_memory` テストや DEN/color のみの smoke 成功を、現 CPU・文字 pipeline の受入に代用しない。
