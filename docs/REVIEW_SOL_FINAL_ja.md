# Sol最終クロスレビュー

2026-10-03。CPU 担当が自分の CPU 実装以外を read-only で確認した。対象は Day99 clock/reset/LCD/RAM、board wrappers と gprj、root/Day99 Makefile、programmer helper と fake test、Day01 counter/TB、Day05/06 到達仕様。RTL・Makefile・script はこのレビューで変更していない。Gowin 実行結果の集約は parent の結果記録を参照。

## 指摘

### F01 / P1: constraint変更がbitstreamを古いままにする

レビュー時の `day99_completed/Makefile` の FS prerequisite は `$(wildcard *.cst)`。CST の実体は `src/lcd_cpu_bsram_9K.cst` / `src/lcd_cpu_bsram_20K.cst` であり、ルート glob に入らない。既存 FS がある状態で pin/timing 制約のみを変更しても再 build されない。board 選択 CST を明示 dependency へ追加する必要がある。Day01–06completed 等も gprj/SRCS のみで CST の同種欠落がある。

### F02 / P2: programmer終了markerのsubstringが偽成功を作る

`grep -q 'Finished'` が substring 一致で、exit=0・Error:なしの場合、成功を否定する `Not Finished` も成功になる。tmp fake programmer で次を実行し、3 ケース全て script exit=0 を確認した。

| fake stdout          | script exit | 評価   |
| -------------------- | ----------- | ------ |
| Not Finished         | 0           | 偽成功 |
| Finished with errors | 0           | 偽成功 |
| UnFinished           | 0           | 偽成功 |

既存 fake テストは Error:・marker 欠損・nonzero code を検査し、それらは妥当。ただしこの反例は含まれない。実 programmer の正規成功 marker を確認し、行として認識すること、否定/失敗ログを拒否すること、その fake ケースを追加することを推奨する。今回 hardware programming は実行していない。

### F03 / P2: Day99 lint入口が失敗する

`make -C day99_completed lint > /private/tmp/sol-cross-lint.log 2>&1` を実行し exit=2。Verilator に `-Iinclude -Isrc` がなく、11 件の include-not-found で終了。SRCS から単純 filter した manifest は generated include/package を直接 source にも並べ、vendor font を除いた後の代替もない。active top＋board wrapper＋font stub＋明示 include path の lint source manifest が必要。lint 成功を報告してはならない。

## 実装上確認した契約

- `platform_clocks.sv` の 9K/20K pixel/memory PLL parameter は、元の 4 vendor wrapper と IDIV/FBDIV/ODIV/DEVICE、dynamic selector、CLKOUT、phase/duty、bypass を静的照合した。pixel ODIV は 9K48/20K64、memory は 16、元と一致。simulation model の周波数は 9MHz/40.5MHz で LOCK 待ち/喪失を表す。
- 9K/20K wrapper が BOARD_20K parameter を明示し、両 gprj に project-owned platform_clocks/reset_sync を登録。vendor/generated PLL は変更していない。reset button の既存極性を保つ。
- 両 LOCK と外部 reset から ready_n を作り、各 domain は async assert・自身の 2edge で release。CPU は memory reset、LCD は pixel reset、physical CEA/VCEA は memory reset で gate。LOCK を PLL reset へ循環接続していない。
- VRAM write は memory clock、read は pixel clock。font も pixel clock で読み、旧 multi-bit address2FF はなく、metadata/VRAM/font/RGB の 2edge pipeline に置換。active/border/error は valid と同じ段へ運ぶ。DE は RGB に合わせて 2edge 遅れる設計。
- LCD H/V counter は TOTAL−1 で wrap、V 更新は H wrap だけ。all-cell/pixel oracle は DUT counter を期待値へ流用せず、別 h/v で 2frame を計算する。3 つの memory/pixel phase を Make から実行する。
- font stub は実 MI2048 byte を読み、残り 2048 byte を zero。font contract は vendor INIT4096 byte との一致、CE/OCE/reset/内容保持を比較する。all-zero stub で文字の正しさを PASS にしていない。
- RAM behavioral の read は CEB を尊重し、READ_MODE=0 の OCE を無視。RESETA によって write を抑止しない。vendor/behavioral を同系列で比較する test がある。collision 時の old/new 値を受入 oracle にしていない。
- root test は programmer fake test 後、`set -e` で各 completed の test を実行する。build/sim/clean にも子 make 失敗を隠す loop はない。Day99 test は CPU/ALU/RAM/font/LCD/clock/system/smoke の終了 code を集約する。
- Day01 TB は counter の bit24 両遷移と 25bit wrap まで外部 LED から検査し timeout/fatal を持つ。20K counter 初期化は 9K と同じ決定的 start になり、polarity は board ごとの oracle を持つ。RTL initializer の実 hardware 初期化は合成/実機で別確認する。
- Day05/06 docs は実 CPU の 0200 reset・PC enable・LDA opcode/operand を到達点にし、未接続の register/decoder/flag module を追加課題と明記。A/X/Y/flag の未実装を CPUtest 成功から推測させない。

## 検証境界

このクロスレビューでは上記 static 照合、programmer fake 反例、lint 入口の失敗を独立実行した。LCD/RAM/font/clock/Day01 tests の合格実行をこのレビュー自身が再実行したわけではない。結果は各担当/parent の fresh build・実行記録で確認する。PLL simulation は primitive の analog lock/timing/CDC の実機証明ではない。9K/20K 合成・配置配線・timing、実機 button reset/cold boot/連続表示は別受入。

## Parent修正後の再確認

F01: parent が Day99 dependency に `src/*.cst` / `*.sdc` / `src/*.sdc` を加えたことを静的確認。他 completed にも CST glob が追加された。constraint 変更の未反映原因は解消した。

F02: 正規成功 marker を行全体の `^[[:space:]]*Finished[[:space:]]*$` へ修正し、3 反例を含む 10 fake ケースを追加。`python3 scripts/test_program_fpga.py` を独立再実行し exit0。実 programmer の hardware 書き込み結果は別受入。

F03: active board top＋font stub manifest、明示 include path、top-module へ修正された。`make -C day99_completed lint > /private/tmp/sol-cross-lint-fixed.log 2>&1` を独立再実行し exit0。警告は nonfatal 設定であり、timing/CDC や実機の証明にはしない。
