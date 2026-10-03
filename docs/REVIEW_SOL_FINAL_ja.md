# Sol最終クロスレビュー

2026-10-03。CPU担当が自分のCPU実装以外をread-onlyで確認した。対象はDay99 clock/reset/LCD/RAM、board wrappersとgprj、root/Day99 Makefile、programmer helperとfake test、Day01 counter/TB、Day05/06到達仕様。RTL・Makefile・scriptはこのレビューで変更していない。Gowin実行結果の集約はparentの結果記録を参照。

## 指摘

### F01 / P1: constraint変更がbitstreamを古いままにする

レビュー時の `day99_completed/Makefile` のFS prerequisiteは `$(wildcard *.cst)`。CSTの実体は `src/lcd_cpu_bsram_9K.cst` / `src/lcd_cpu_bsram_20K.cst` であり、ルートglobに入らない。既存FSがある状態でpin/timing制約のみを変更しても再buildされない。board選択CSTを明示dependencyへ追加する必要がある。Day01–06completed等もgprj/SRCSのみでCSTの同種欠落がある。

### F02 / P2: programmer終了markerのsubstringが偽成功を作る

`grep -q 'Finished'` がsubstring一致で、exit=0・Error:なしの場合、成功を否定する `Not Finished` も成功になる。tmp fake programmerで次を実行し、3ケース全てscript exit=0を確認した。

| fake stdout | script exit | 評価 |
|---|---|---|
| Not Finished | 0 | 偽成功 |
| Finished with errors | 0 | 偽成功 |
| UnFinished | 0 | 偽成功 |

既存fakeテストはError:・marker欠損・nonzero codeを検査し、それらは妥当。ただしこの反例は含まれない。実programmerの正規成功markerを確認し、行として認識すること、否定/失敗ログを拒否すること、そのfakeケースを追加することを推奨する。今回hardware programmingは実行していない。

### F03 / P2: Day99 lint入口が失敗する

`make -C day99_completed lint > /private/tmp/sol-cross-lint.log 2>&1` を実行しexit=2。Verilatorに `-Iinclude -Isrc` がなく、11件のinclude-not-foundで終了。SRCSから単純filterしたmanifestはgenerated include/packageを直接sourceにも並べ、vendor fontを除いた後の代替もない。active top＋board wrapper＋font stub＋明示include pathのlint source manifestが必要。lint成功を報告してはならない。

## 実装上確認した契約

- `platform_clocks.sv` の9K/20K pixel/memory PLL parameterは、元の4 vendor wrapperとIDIV/FBDIV/ODIV/DEVICE、dynamic selector、CLKOUT、phase/duty、bypassを静的照合した。pixel ODIVは9K48/20K64、memoryは16、元と一致。simulation modelの周波数は9MHz/40.5MHzでLOCK待ち/喪失を表す。
- 9K/20K wrapperがBOARD_20K parameterを明示し、両gprjにproject-owned platform_clocks/reset_syncを登録。vendor/generated PLLは変更していない。reset buttonの既存極性を保つ。
- 両LOCKと外部resetからready_nを作り、各domainはasync assert・自身の2edgeでrelease。CPUはmemory reset、LCDはpixel reset、physical CEA/VCEAはmemory resetでgate。LOCKをPLL resetへ循環接続していない。
- VRAM writeはmemory clock、readはpixel clock。fontもpixel clockで読み、旧multi-bit address2FFはなく、metadata/VRAM/font/RGBの2edge pipelineに置換。active/border/errorはvalidと同じ段へ運ぶ。DEはRGBに合わせて2edge遅れる設計。
- LCD H/V counterはTOTAL−1でwrap、V更新はH wrapだけ。all-cell/pixel oracleはDUT counterを期待値へ流用せず、別h/vで2frameを計算する。3つのmemory/pixel phaseをMakeから実行する。
- font stubは実MI2048 byteを読み、残り2048 byteをzero。font contractはvendor INIT4096 byteとの一致、CE/OCE/reset/内容保持を比較する。all-zero stubで文字の正しさをPASSにしていない。
- RAM behavioralのreadはCEBを尊重し、READ_MODE=0のOCEを無視。RESETAによってwriteを抑止しない。vendor/behavioralを同系列で比較するtestがある。collision時のold/new値を受入oracleにしていない。
- root testはprogrammer fake test後、`set -e` で各completedのtestを実行する。build/sim/cleanにも子make失敗を隠すloopはない。Day99 testはCPU/ALU/RAM/font/LCD/clock/system/smokeの終了codeを集約する。
- Day01 TBはcounterのbit24両遷移と25bit wrapまで外部LEDから検査しtimeout/fatalを持つ。20K counter初期化は9Kと同じ決定的startになり、polarityはboardごとのoracleを持つ。RTL initializerの実hardware初期化は合成/実機で別確認する。
- Day05/06 docsは実CPUの0200 reset・PC enable・LDA opcode/operandを到達点にし、未接続のregister/decoder/flag moduleを追加課題と明記。A/X/Y/flagの未実装をCPUtest成功から推測させない。

## 検証境界

このクロスレビューでは上記static照合、programmer fake反例、lint入口の失敗を独立実行した。LCD/RAM/font/clock/Day01 testsの合格実行をこのレビュー自身が再実行したわけではない。結果は各担当/parentのfresh build・実行記録で確認する。PLL simulationはprimitiveのanalog lock/timing/CDCの実機証明ではない。9K/20K合成・配置配線・timing、実機button reset/cold boot/連続表示は別受入。

## Parent修正後の再確認

F01: parentがDay99 dependencyに `src/*.cst` / `*.sdc` / `src/*.sdc` を加えたことを静的確認。他completedにもCST globが追加された。constraint変更の未反映原因は解消した。

F02: 正規成功markerを行全体の `^[[:space:]]*Finished[[:space:]]*$` へ修正し、3反例を含む10 fakeケースを追加。`python3 scripts/test_program_fpga.py` を独立再実行しexit0。実programmerのhardware書込み結果は別受入。

F03: active board top＋font stub manifest、明示include path、top-moduleへ修正された。`make -C day99_completed lint > /private/tmp/sol-cross-lint-fixed.log 2>&1` を独立再実行しexit0。警告はnonfatal設定であり、timing/CDCや実機の証明にはしない。
