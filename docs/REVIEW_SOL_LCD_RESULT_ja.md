# Day 99 Solメモリ・LCD実装結果

実装日: 2026-10-03
対象: R03/R09。[設計調査](REVIEW_SOL_MEMORY_DESIGN_ja.md) を具体化した。

## 変更と契約

- `ram.sv` はVRAM writeをMEMORY_CLK、readをPIXEL_CLKへ分離。font ROMとLCDはPixelClkへ揃え、topの多bitアドレス2FFを削除した。
- READ_MODE=0のbehavioral modelはCEBのみで同期読出し、OCE非依存とした。RESETBは出力のみをresetし内容を保持する。vendorのRESETAはwrite抑止ではないため、top側のCEAをmemory reset中gateする。
- `lcd.sv` は組合せVRAM address → 同期VRAM → 組合せfont address → 同期font → RGB/DE登録。row・bit・validを同じpipelineで運ぶ。DEはbeamより2edge遅れ、幅480・272 active行・531×292周期を保持する。
- 全zero font stubを実MI読込みへ変更。MIは4096容量宣言だが実データは2048byte（128文字）なので、残る2048byteはvendor INITと同じゼロにした。実データ件数不一致はfatalとする。
- `platform_clocks.sv` はproject所有rPLL adapter。既存vendor/generatedは変更せず、既存rPLL設定とBOARD差（pixel ODIV=48/64、memory ODIV=16、DEVICE）を保存してLOCKを公開する。
- `reset_sync.sv` は外部reset/いずれかLOCK喪失で両domainへ非同期assert、domainごと2edge同期release。CPUはmemory resetで制御し、LCDのDEはpixel resetで0にする。
- `tb_lcd.sv` は新self-checking pixel testの互換entryへ変更。VRAM smokeは実クロックと100ms timeout、物理write enableの監視に追従した。
- 旧PLL stub・旧 `tb_top.sv` はlegacy参考。現行受入に使わない。

## 独立検証

すべてcwd=`day99_completed`、Verilator 5.052。生成した実行ファイルは `/private/tmp` に置き、repoのbuild成果物やvendorソースを変更していない。下表の成功はsimulationの結果である。

| 検査 | 結果 |
| --- | --- |
| `tb_ram_contract` behavioral vs 9K/20K同梱vendor | exit 0。CEB保持/読出し、OCE=0更新、RESETB出力reset/内容保持、RESETA中write、非衝突dual-clock readを比較 |
| `tb_font_contract` 実MI vs vendor INIT | exit 0。全4096byte一致、CE保持/OCE=0更新/reset/内容保持 |
| `tb_lcd_pipeline +phase=0/7/31` | 各exit 0。2frameの261120画素、34820点灯画素。全セル/全row/全bit、DE、period、vsync一致 |
| `tb_clock_reset` | exit 0。9MHz/40.5MHz周期、lock待ち・喪失・再lock、2edge同期release、button reset |
| `tb_top_reset` | exit 0。実topでlock喪失/relock/reset、CPU物理write gate、LCD DE resetと再開 |
| RAM故障注入 | 一時copyで旧 `ceb && oce` に戻すと `expected=a5, actual=00` でexit 1 |
| LCD故障注入 | 一時copyでfont bit左右反転するとpixel `t=6974` の不一致でexit 1 |

実行commands（`--Mdir` は一時build出力）:

```sh
verilator --binary --timing -Wno-fatal --top-module tb_ram_contract -Iinclude -Isrc \
  --Mdir /private/tmp/day99_ram_contract src/tb_ram_contract.sv src/ram.sv \
  src/gowin_sdpb/gowin_sdpb.v src/gowin_sdpb/gowin_sdpb_vram.v deps/gw1n/prim_sim.v
/private/tmp/day99_ram_contract/Vtb_ram_contract
# 20K: 上記 deps/gw1n を deps/gw2a、Mdir を day99_ram_contract_20k に置換して実行。

verilator --binary --timing -Wno-fatal --top-module tb_font_contract \
  --Mdir /private/tmp/day99_font_contract src/tb_font_contract.sv \
  src/gowin_prom/gowin_prom_font.v deps/gw1n/prim_sim.v
/private/tmp/day99_font_contract/Vtb_font_contract

verilator --binary --timing -Wno-fatal --top-module tb_lcd_pipeline -Iinclude -Isrc \
  --Mdir /private/tmp/day99_lcd_pipeline src/tb_lcd_pipeline.sv src/ram.sv src/lcd.sv \
  sim/gowin_prom_font_stub.sv
/private/tmp/day99_lcd_pipeline/Vtb_lcd_pipeline +phase=0
/private/tmp/day99_lcd_pipeline/Vtb_lcd_pipeline +phase=7
/private/tmp/day99_lcd_pipeline/Vtb_lcd_pipeline +phase=31

verilator --binary --timing -Wno-fatal --top-module tb_clock_reset \
  --Mdir /private/tmp/day99_clock_reset src/tb_clock_reset.sv \
  src/platform_clocks.sv src/reset_sync.sv
/private/tmp/day99_clock_reset/Vtb_clock_reset

verilator --binary --timing -Wno-fatal --top-module tb_top_reset -Iinclude -Isrc \
  --Mdir /private/tmp/day99_top_reset src/tb_top_reset.sv src/top_core.sv src/cpu.sv \
  src/ram.sv src/lcd.sv src/platform_clocks.sv src/reset_sync.sv sim/gowin_prom_font_stub.sv
/private/tmp/day99_top_reset/Vtb_top_reset
```

統合Make経路は `make test-ram test-font test-lcd test-clock test-reset`。

## 未検証・保証しない範囲

- FPGA合成・配置配線・timing確認はroot統合側で実行して記録する。本書のsimulation成功はその代替ではない。
- 実機書込み・cold boot・button reset・連続表示・長期安定性は未実施。
- dual-clock同address read/write衝突のold/new値は保証しない。テストは非衝突系列、書込後のread一致を検査する。frame atomicityは提供しない。
- phaseテストは複数clock関係で画素整合を検査するが、metastability耐性を証明しない。
- vendor primitive全体をVerilatorで読む際には既存vendorの警告が出る。vendorファイルを修正して警告を消してはいない。
