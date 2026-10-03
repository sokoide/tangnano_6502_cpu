# Day 99 Solメモリ・LCD実装結果

実装日: 2026-10-03
対象: R03/R09。[設計調査](REVIEW_SOL_MEMORY_DESIGN_ja.md)を具体化した。

## 変更と契約

- `ram.sv` は VRAM write を MEMORY_CLK、read を PIXEL_CLK へ分離。font ROM と LCD は PixelClk へ揃え、top の多 bit アドレス 2FF を削除した。
- READ_MODE=0 の behavioral model は CEB のみで同期読出し、OCE 非依存とした。RESETB は出力のみを reset し内容を保持する。vendor の RESETA は write 抑止ではないため、top 側の CEA を memory reset 中 gate する。
- `lcd.sv` は組合せ VRAM address → 同期 VRAM → 組合せ font address → 同期 font → RGB/DE 登録。row・bit・valid を同じ pipeline で運ぶ。DE は beam より 2edge 遅れ、幅 480・272 active 行・531×292 周期を保持する。
- 全 zero font stub を実 MI 読込みへ変更。MI は 4096 容量宣言だが実データは 2048byte（128 文字）なので、残る 2048byte は vendor INIT と同じゼロにした。実データ件数不一致は fatal とする。
- `platform_clocks.sv` は project 所有 rPLL adapter。既存 vendor/generated は変更せず、既存 rPLL 設定と BOARD 差（pixel ODIV=48/64、memory ODIV=16、DEVICE）を保存して LOCK を公開する。
- `reset_sync.sv` は外部 reset/いずれか LOCK 喪失で両 domain へ非同期 assert、domain ごと 2edge 同期 release。CPU は memory reset で制御し、LCD の DE は pixel reset で 0 にする。
- `tb_lcd.sv` は新 self-checking pixel test の互換 entry へ変更。VRAM smoke は実クロックと 100ms timeout、物理 write enable の監視に追従した。
- 旧 PLL stub・旧 `tb_top.sv` は legacy 参考。現行受入に使わない。

## 独立検証

すべて cwd=`day99_completed`、Verilator 5.052。生成した実行ファイルは `/private/tmp` に置き、repo の build 成果物や vendor ソースを変更していない。下表の成功は simulation の結果である。

| 検査 | 結果 |
| --- | --- |
| `tb_ram_contract` behavioral vs 9K/20K同梱vendor | exit 0。CEB保持/読出し、OCE=0更新、RESETB出力reset/内容保持、RESETA中write、非衝突dual-clock readを比較 |
| `tb_font_contract` 実MI vs vendor INIT | exit 0。全4096byte一致、CE保持/OCE=0更新/reset/内容保持 |
| `tb_lcd_pipeline +phase=0/7/31` | 各exit 0。2frameの261120画素、34820点灯画素。全セル/全row/全bit、DE、period、vsync一致 |
| `tb_clock_reset` | exit 0。9MHz/40.5MHz周期、lock待ち・喪失・再lock、2edge同期release、button reset |
| `tb_top_reset` | exit 0。実topでlock喪失/relock/reset、CPU物理write gate、LCD DE resetと再開 |
| RAM故障注入 | 一時copyで旧 `ceb && oce` に戻すと `expected=a5, actual=00` でexit 1 |
| LCD故障注入 | 一時copyでfont bit左右反転するとpixel `t=6974` の不一致でexit 1 |

実行 commands（`--Mdir` は一時 build 出力）:

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

統合 Make 経路は `make test-ram test-font test-lcd test-clock test-reset`。

## 未検証・保証しない範囲

- FPGA 合成・配置配線・timing 確認は root 統合側で実行して記録する。本書の simulation 成功はその代替ではない。
- 実機書込み・cold boot・button reset・連続表示・長期安定性は未実施。
- dual-clock 同 address read/write 衝突の old/new 値は保証しない。テストは非衝突系列、書込後の read 一致を検査する。frame atomicity は提供しない。
- phase テストは複数 clock 関係で画素整合を検査するが、metastability 耐性を証明しない。
- vendor primitive 全体を Verilator で読む際には既存 vendor の警告が出る。vendor ファイルを修正して警告を消してはいない。
